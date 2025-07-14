import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/user_profile_screen.dart';
import '../screens/profile_screen.dart'; // or correct path
import 'package:firebase_auth/firebase_auth.dart';

class UserSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) return Center(child: Text("Search users by username"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final results = snapshot.data!.docs;
        if (results.isEmpty) return Center(child: Text("No users found"));

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user['profilePic'] ?? 'https://i.pravatar.cc/300'),
              ),
              title: Text(user['username'] ?? "Unnamed"),
                onTap: () {
                  close(context, null);
                  final currentUserId = FirebaseFirestore.instance.app.options.projectId; // fallback if needed
                  final currentUser = FirebaseFirestore.instance.collection('users');

                  final currentUserIdFromAuth = FirebaseFirestore.instance.app.options.projectId;

                  final currentUserIdAuth = FirebaseAuth.instance.currentUser?.uid;

                  if (user.id == currentUserIdAuth) {
                    // Navigate to user's own profile screen tab 0
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileScreen(initialTabIndex: 0)),
                    );
                  } else {
                    // Navigate to another user's profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id)),
                    );
                  }
                }
            );
          },
        );
      },
    );
  }
}
