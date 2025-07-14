import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
class FirebasePostService {
  final storage = FirebaseStorage.instance;
  final firestore = FirebaseFirestore.instance;

  Future<String> uploadImage(File image) async {
    String fileId = const Uuid().v4();
    final ref = storage.ref().child('posts').child('$fileId.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> savePost({
    required String imageUrl,
    required String caption,
    required String city,
    required String weather,
    required double temperature,
  }) async {
    await firestore.collection('posts').add({
      'imageUrl': imageUrl,
      'caption': caption,
      'city': city,
      'weather': weather,
      'temperature': temperature,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'username': FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous',// ✅ Add this
      'likes': [],
    });
  }
}
Future<void> addComment({
  required String postId,
  required String userId,
  required String username,
  required String text,
}) async {
  final comment = {
    'text': text,
    'userId': userId,
    'username': username,
    'timestamp': FieldValue.serverTimestamp(),
    'likes': [],
  };

  await FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .add(comment);
}

