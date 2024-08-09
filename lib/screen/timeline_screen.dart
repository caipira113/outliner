import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/timeline_widget.dart';
import 'post_creation.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final bool _isButtonVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _scrollToTop() {}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timeline')),
        body: const Center(child: Text('Timeline: Login required')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          _isButtonVisible
              ? Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _scrollToTop,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: TimelineWidget(
        userId: user.uid,
        me: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostCreationScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
