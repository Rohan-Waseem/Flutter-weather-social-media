import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> getConversationId(String user1, String user2) async {
    final ids = [user1, user2]..sort();
    return ids.join("_");
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    String? text,
    File? imageFile,
  }) async {
    final conversationId = await getConversationId(senderId, receiverId);
    final timestamp = Timestamp.now();

    String? imageUrl;
    if (imageFile != null) {
      final ref = _storage.ref().child("chat_images/${DateTime.now().millisecondsSinceEpoch}");
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final message = {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'readBy': [senderId], // Sender has "read" it by default
    };


    // Store the message
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message);

    // 🔄 Fetch the receiver’s user info from Firestore
    final userDoc = await _firestore.collection('users').doc(receiverId).get();
    final receiverName = userDoc.data()?['username'] ?? 'Unknown';
    final receiverPic = userDoc.data()?['profilePic'] ?? '';

    // Store/merge conversation metadata
    await _firestore.collection('conversations').doc(conversationId).set({
      'lastMessage': text ?? '📷 Photo',
      'lastTimestamp': timestamp,
      'userIds': [senderId, receiverId],
      'profilePic': receiverPic,
      'username': receiverName,
    }, SetOptions(merge: true));
  }


  Stream<QuerySnapshot> getMessagesStream(String user1, String user2) async* {
    final conversationId = await getConversationId(user1, user2);
    yield* _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }
}
