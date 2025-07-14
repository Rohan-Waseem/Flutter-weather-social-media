import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<bool> isFollowing(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    final snap = await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .get();

    return snap.exists;
  }

  Future<void> toggleFollow(String targetUserId, bool isFollowing) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    final followersRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    if (isFollowing) {
      await followingRef.delete();
      await followersRef.delete();
    } else {
      await followingRef.set({'timestamp': FieldValue.serverTimestamp()});
      await followersRef.set({'timestamp': FieldValue.serverTimestamp()});
    }
  }

  Future<Map<String, int>> getFollowCounts(String userId) async {
    final followers = await _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .get();
    final following = await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();

    return {
      'followers': followers.size,
      'following': following.size,
    };
  }
}
