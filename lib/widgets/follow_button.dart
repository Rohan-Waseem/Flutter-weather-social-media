import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowButton extends StatefulWidget {
  final String userId;
  const FollowButton({required this.userId, super.key});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    checkFollowing();
  }

  Future<void> checkFollowing() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .doc(currentUser.uid)
        .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  Future<void> toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final followingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(widget.userId);

    final followersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .doc(currentUser.uid);

    if (isFollowing) {
      await followingRef.delete();
      await followersRef.delete();
    } else {
      await followingRef.set({});
      await followersRef.set({});
    }

    setState(() {
      isFollowing = !isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: toggleFollow,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: const BorderSide(color: Colors.blue),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(isFollowing ? 'Unfollow' : 'Follow', style: const TextStyle(fontSize: 12)),
    );
  }
}
