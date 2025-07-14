import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUsername;
  final String targetUserPic;

  const ChatScreen({
    required this.targetUserId,
    required this.targetUsername,
    required this.targetUserPic,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final _auth = FirebaseAuth.instance;

  late final String _currentUserId;
  late final String _conversationId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser!.uid;
    _initializeConversation();
  }

  void _initializeConversation() async {
    _conversationId = await _chatService.getConversationId(_currentUserId, widget.targetUserId);
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .where('readBy', whereNotIn: [_currentUserId])
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'readBy': FieldValue.arrayUnion([_currentUserId]),
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _chatService.sendMessage(
      senderId: _currentUserId,
      receiverId: widget.targetUserId,
      text: text,
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: const BackButton(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.targetUserPic),
            ),
            const SizedBox(width: 10),
            Text(
              widget.targetUsername,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(_currentUserId, widget.targetUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: data['text'] != null
                            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                            : const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: data['text'] != null
                            ? Text(
                          data['text'],
                          style: const TextStyle(fontSize: 15),
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['imageUrl'],
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: () {
                    // Add image picker logic later
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
