import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/follow_service.dart';
import '../screens/chat_screen.dart';
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({required this.userId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isFollowing = false;
  final currentUser = FirebaseAuth.instance.currentUser;
  final FollowService _followService = FollowService();
  int followerCount = 0;
  int followingCount = 0;


  Map<String, dynamic>? userData;
  List<DocumentSnapshot> userPosts = [];

  final ButtonStyle outlineStyle = OutlinedButton.styleFrom(
    foregroundColor: Color(0xFF62bafe),
    side: BorderSide(color: Color(0xFF62bafe), width: 2),
    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
  );

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _loadFollowStatus();
  }
  Future<void> _fetchUserProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final postsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: widget.userId)
        .get();

    setState(() {
      userData = doc.data();
      userPosts = postsSnapshot.docs;
    });
  }
  Future<void> _loadFollowStatus() async {
    final isUserFollowing = await _followService.isFollowing(widget.userId);
    final counts = await _followService.getFollowCounts(widget.userId);

    setState(() {
      isFollowing = isUserFollowing;
      followerCount = counts['followers']!;
      followingCount = counts['following']!;
    });
  }

  Future<void> _toggleFollow() async {
    await _followService.toggleFollow(widget.userId, isFollowing);
    _loadFollowStatus(); // Refresh UI
  }
  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(userData!['username'] ?? 'User Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(userData!['profilePic'] ?? 'https://i.pravatar.cc/300'),
            ),
            const SizedBox(height: 12),
            Text(
              userData!['username'] ?? '',
              style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              userData!['bio'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat("Posts", userPosts.length),
                _buildStat("Followers", followerCount),
                _buildStat("Following", followingCount),
              ],
            ),
            SizedBox(height: 16),

            // Follow and Message Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _toggleFollow,
                  style: outlineStyle,
                  child: Text(isFollowing ? "Unfollow" : "Follow"),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          targetUserId: widget.userId,
                          targetUsername: userData?['username'] ?? 'User',
                          targetUserPic: userData?['profilePic'] ?? 'https://i.pravatar.cc/150?img=3',
                        ),
                      ),
                    );
                  },
                  style: outlineStyle,
                  child: Text("Message"),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Posts",
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            userPosts.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                "No posts yet",
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
                : GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: userPosts.map((doc) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(doc['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
