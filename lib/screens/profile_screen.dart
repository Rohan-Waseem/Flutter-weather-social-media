import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/follow_service.dart';


class ProfileScreen extends StatefulWidget {
  final int initialTabIndex;
  const ProfileScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _bioController;
  late TextEditingController _profilePicController;
  final FollowService _followService = FollowService();

  File? _selectedImage;
  final picker = ImagePicker();

// Function to pick and upload image
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, // or ImageSource.camera
      imageQuality: 50,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}.jpg');
      await storageRef.putFile(file);
      final downloadURL = await storageRef.getDownloadURL();

      // Update Firestore and controller
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profilePic': downloadURL,
      }, SetOptions(merge: true));

      setState(() {
        _profilePicController.text = downloadURL;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Profile picture updated')));
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    final user = _auth.currentUser;
    _emailController = TextEditingController(text: user?.email ?? "");
    _usernameController = TextEditingController(text: user?.displayName ?? "");
    _passwordController = TextEditingController();
    _bioController = TextEditingController(); // Optionally load from Firestore later
    _profilePicController = TextEditingController(); // Or use image picker

  }

  void _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not found")));
      return;
    }

    final newEmail = _emailController.text.trim();
    final newPassword = _passwordController.text.trim();
    final newUsername = _usernameController.text.trim();

    try {
      // ✅ Update email using verifyBeforeUpdateEmail
      if (newEmail.isNotEmpty && newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📩 Verification email sent to $newEmail. Please verify to update email.")),
        );
      }

      // ✅ Update password (still requires reauth)
      if (newPassword.isNotEmpty) {
        // Optional: You can wrap this with reauthentication
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🔑 Password updated")),
        );
      }

      // ✅ Update display name
      if (newUsername.isNotEmpty && newUsername != user.displayName) {
        await user.updateDisplayName(newUsername);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🧑 Username updated")),
        );
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${e.code}: ${e.message}")),
      );
    }
  }



  void _editCaption(String docId, String oldCaption) {
    final controller = TextEditingController(text: oldCaption);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit Caption"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: "New caption"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _firestore.collection('posts').doc(docId).update({
                'caption': controller.text.trim(),
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _deletePost(String docId) async {
    await _firestore.collection('posts').doc(docId).delete();
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text("$count", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Color(0xFFf0f4ff),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 4,
          title: Text("Profile", style: TextStyle(color: Colors.black)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _logout,
              tooltip: "Logout",
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "My Profile"),
              Tab(text: "Edit Profile"),
              Tab(text: "Posts"),
              Tab(text: "Saved"),
              Tab(text: "Settings"),

            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Profile Overview Tab
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return Center(child: CircularProgressIndicator());

                final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                final profilePic = userData['profilePic'] ?? '';
                final username = userData['username'] ?? 'User';
                final bio = userData['bio'] ?? '';

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, postSnapshot) {
                    if (!postSnapshot.hasData) return Center(child: CircularProgressIndicator());

                    final posts = postSnapshot.data!.docs;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                            backgroundColor: Colors.blue[100],
                            child: profilePic.isEmpty
                                ? const Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            username,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bio,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<Map<String, int>>(
                            future: FollowService().getFollowCounts(user!.uid),
                            builder: (context, followSnapshot) {
                              if (!followSnapshot.hasData) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatColumn("Posts", posts.length),
                                    _buildStatColumn("Followers", 0),
                                    _buildStatColumn("Following", 0),
                                  ],
                                );
                              }

                              final followers = followSnapshot.data!['followers']!;
                              final following = followSnapshot.data!['following']!;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn("Posts", posts.length),
                                  _buildStatColumn("Followers", followers),
                                  _buildStatColumn("Following", following),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 8),
                          posts.isEmpty
                              ? const Text("No posts yet.")
                              : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: posts.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemBuilder: (context, index) {
                              final postData = posts[index].data() as Map<String, dynamic>;
                              final imageUrl = postData['imageUrl'] ?? '';
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
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
              },
            ),

            // Edit Profile Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _profilePicController.text.isNotEmpty
                            ? NetworkImage(_profilePicController.text)
                            : null,
                        child: _profilePicController.text.isEmpty
                            ? Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                        backgroundColor: Colors.blue[200],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.edit, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "Username",
                      prefixIcon: Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Bio",
                      prefixIcon: Icon(Icons.info_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  OutlinedButton.icon(
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'username': _usernameController.text.trim(),
                          'bio': _bioController.text.trim(),
                          'profilePic': _profilePicController.text.trim(),
                        }, SetOptions(merge: true));

                        user.updateDisplayName(_usernameController.text.trim());

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ Profile updated")),
                        );
                      }
                    },
                    icon: Icon(Icons.save),
                    label: Text("Save Changes"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF62bafe),
                      side: BorderSide(color: Color(0xFF62bafe), width: 2),
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),


            // Posts Tab
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('posts')
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final posts = snapshot.data!.docs;
                if (posts.isEmpty) return Center(child: Text("No posts yet."));

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(post['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post['caption'], style: TextStyle(fontSize: 16)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.orange),
                                      onPressed: () => _editCaption(post.id, post['caption']),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deletePost(post.id),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // Saved Tab (Placeholder for now)
            Center(
              child: Text("Saved posts coming soon!", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ),
            // Settings Tab
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Account Settings",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  OutlinedButton.icon(
                    onPressed: _updateProfile,
                    icon: Icon(Icons.update),
                    label: Text("Update Email & Password"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF62bafe),
                      side: BorderSide(color: Color(0xFF62bafe), width: 2),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}
