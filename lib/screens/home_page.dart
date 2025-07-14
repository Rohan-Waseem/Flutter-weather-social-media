// home_page.dart with profile tab
import 'package:flutter/material.dart';
import 'weather_screen.dart';
import 'new_post_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    WeatherScreen(),
    NewPostScreen(),
    FeedScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,          // active icon color
        unselectedItemColor: Colors.grey[600],   // inactive icon color
        backgroundColor: Colors.white,           // optional: sets nav bar background
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wb_sunny), label: 'Weather'),
          BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}