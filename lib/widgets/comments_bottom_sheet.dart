import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showCommentsBottomSheet(BuildContext context, String postId) {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  void _editComment(BuildContext context, String postId, QueryDocumentSnapshot comment) {
    final TextEditingController _editController = TextEditingController(text: comment['text']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit Comment"),
        content: TextField(
          controller: _editController,
          decoration: InputDecoration(labelText: "New comment"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .collection('comments')
                  .doc(comment.id)
                  .update({
                'text': _editController.text.trim(),
                'timestamp': Timestamp.now(),
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                      final comments = snapshot.data!.docs;
                      if (comments.isEmpty) return Center(child: Text("No comments yet."));

                      return ListView.separated(
                        controller: controller,
                        itemCount: comments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final likes = List<String>.from(comment['likes'] ?? []);
                          final likedByUser = likes.contains(currentUser?.uid);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Username
                                        Expanded(
                                          child: Text(
                                            comment['username'],
                                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                          ),
                                        ),

                                        // Edit/Delete menu (if owner)
                                        if (currentUser?.uid == comment['userId'])
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editComment(context, postId, comment);
                                                } else if (value == 'delete') {
                                                  FirebaseFirestore.instance
                                                      .collection('posts')
                                                      .doc(postId)
                                                      .collection('comments')
                                                      .doc(comment.id)
                                                      .delete();
                                                }
                                              },
                                              itemBuilder: (_) => [
                                                PopupMenuItem(value: 'edit', child: Text("Edit")),
                                                PopupMenuItem(value: 'delete', child: Text("Delete")),
                                              ],
                                              padding: EdgeInsets.zero,
                                              icon: Icon(Icons.more_horiz, size: 18),
                                            ),
                                          ),

                                        // Like button and count
                                        const SizedBox(width: 10),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                final commentRef = FirebaseFirestore.instance
                                                    .collection('posts')
                                                    .doc(postId)
                                                    .collection('comments')
                                                    .doc(comment.id);
                                                await commentRef.update({
                                                  'likes': likedByUser
                                                      ? FieldValue.arrayRemove([currentUser!.uid])
                                                      : FieldValue.arrayUnion([currentUser!.uid]),
                                                });
                                              },
                                              child: Icon(
                                                likedByUser ? Icons.favorite : Icons.favorite_border,
                                                color: likedByUser ? Colors.red : Colors.grey,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text("${likes.length}", style: TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(comment['text'], style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          );

                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: "Write a comment...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.blue),
                      onPressed: () async {
                        final text = _commentController.text.trim();
                        if (text.isNotEmpty && currentUser != null) {
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .collection('comments')
                              .add({
                            'text': text,
                            'userId': currentUser.uid,
                            'username': currentUser.displayName ?? currentUser.email!.split('@')[0],
                            'timestamp': FieldValue.serverTimestamp(),
                            'likes': [],
                          });
                          _commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
