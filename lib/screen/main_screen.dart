import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:outliner/screen/noti_screen.dart';
import 'package:outliner/screen/profile_screen.dart';
import 'package:outliner/screen/search_screen.dart';
import 'package:outliner/screen/timeline_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TimelineScreen(),
    const SearchScreen(),
    const NotiScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void getMyDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null && token != null) {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'deviceTokens': FieldValue.arrayUnion([token]),
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMyDeviceToken();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          unselectedItemColor: theme.colorScheme.onSurface,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.search, 'Search', 1),
            _buildNavItem(Icons.notifications_none, 'Notifications', 2),
            _buildNavItem(Icons.person_outline, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      label: label,
    );
  }
}
