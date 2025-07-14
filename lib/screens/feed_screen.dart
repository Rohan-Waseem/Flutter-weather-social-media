// feed_screen.dart with filter, clean UI, and scalable structure
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/comments_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/user_search_delegate.dart';
import '../widgets/follow_button.dart';
import '../screens/user_profile_screen.dart';
import '../screens/profile_screen.dart';
class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedCity = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildModernAppBar("Weather Feed"),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFdbeafe), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

            final allPosts = snapshot.data!.docs;
            final filteredPosts = _selectedCity.isEmpty
                ? allPosts
                : allPosts.where((post) =>
                post['city'].toString().toLowerCase().contains(_selectedCity.toLowerCase())).toList();

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24), // fixed top padding
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return PostCard(post: post);
              },
            );
          },
        ),
      ),
    );
  }

  AppBar _buildModernAppBar(String title) {
    return AppBar(
      elevation: 4,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      centerTitle: true,
      leading:  IconButton(
        icon: Icon(Icons.filter_list, color: Colors.black87),
        onPressed: () => _showCityFilterDialog(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      actions: [IconButton(
        icon: Icon(Icons.search, color: Colors.black87),
        onPressed: () => _showSearchBar(context),
      ),],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    );
  }

  void _showSearchBar(BuildContext context) {
    showSearch(
      context: context,
      delegate: UserSearchDelegate(),
    );
  }

  void _showCityFilterDialog(BuildContext context) {
    final controller = TextEditingController(text: _selectedCity);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Filter by City"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: "City name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedCity = controller.text.trim());
              Navigator.pop(context);
            },
            child: Text("Apply"),
          ),
          TextButton(
            onPressed: () {
              setState(() => _selectedCity = "");
              Navigator.pop(context);
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot post;
  const PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final postId = post.id;
    final postUserId = post['userId']; // Assumes this field exists in each post
    final likes = List<String>.from(post['likes'] ?? []);
    final likedByUser = likes.contains(currentUser?.uid);

    final imageUrl = post['imageUrl'];
    final username = post['username'] ?? "User";
    final city = post['city'];
    final weather = post['weather'];
    final temp = post['temperature'];
    final caption = post['caption'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(postUserId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;

        final profilePic = userData?['profilePic'] ?? '';
        final isOwnPost = currentUser?.uid == postUserId;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (isOwnPost) {
                          DefaultTabController.of(context)?.animateTo(0); // go to own profile
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(userId: postUserId),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        backgroundImage: profilePic.isNotEmpty
                            ? NetworkImage(profilePic)
                            : AssetImage('assets/default_avatar.png') as ImageProvider,
                        backgroundColor: Colors.blue[200],
                        radius: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                          onTap: () {
                                final postUserId = post['userId'];
                                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                                if (postUserId == currentUserId) {
                                Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProfileScreen(initialTabIndex: 0)),
                                );
                                } else {
                                Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UserProfileScreen(userId: postUserId)),
                                );
                                }
                                },

                            child: Text(
                              username,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$weather in $city, ${temp.toStringAsFixed(1)}°C",
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    if (!isOwnPost)
                      FollowButton(userId: postUserId),
                    Icon(Icons.more_vert),
                  ],
                ),
              ),

              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.network(imageUrl, width: double.infinity, height: 300, fit: BoxFit.cover),
              ),

              // Like & Comment Icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
                        await postRef.update({
                          'likes': likedByUser
                              ? FieldValue.arrayRemove([currentUser!.uid])
                              : FieldValue.arrayUnion([currentUser!.uid]),
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            likedByUser ? Icons.favorite : Icons.favorite_border,
                            size: 26,
                            color: likedByUser ? Colors.red : Colors.black,
                          ),
                          const SizedBox(width: 6),
                          Text('${likes.length}', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: () {
                        showCommentsBottomSheet(context, postId);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 24),
                          const SizedBox(width: 6),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('posts')
                                .doc(postId)
                                .collection('comments')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return Text("0", style: TextStyle(fontSize: 13));
                              final count = snapshot.data!.docs.length;
                              return Text("$count", style: TextStyle(fontSize: 13));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Caption
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      TextSpan(text: "$username ", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: caption),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Preview Latest Comment
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SizedBox.shrink();
                  final comment = snapshot.data!.docs.first;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        children: [
                          TextSpan(
                            text: "${comment['username']} ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: comment['text']),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


