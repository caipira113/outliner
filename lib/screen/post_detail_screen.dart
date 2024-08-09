import 'package:flutter/material.dart';

import '../model/post.dart';
import '../widgets/post_widget.dart'; // 새로 만든 위젯 파일

class PostDetailScreen extends StatelessWidget {
  final Post post;
  final Map<String, dynamic>? userData;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: SingleChildScrollView(
        child: PostWidget(
          post: post,
          userData: userData,
          onTap: null,
          detail: true,
        ),
      ),
    );
  }
}
