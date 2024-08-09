import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:outliner/screen/post_creation.dart';
import 'package:outliner/screen/user_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../model/post.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/media_display.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final Map<String, dynamic>? userData;
  final bool detail;

  const PostWidget({
    super.key,
    required this.post,
    this.onTap,
    this.userData,
    this.detail = false,
  });

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool _isContentVisible = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return DateFormat.MMMd().format(timestamp);
    } else {
      return DateFormat.yMMMd().format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.userData?['name'] ?? widget.userData?['username'] ?? 'Unknown';
    final username = widget.userData?['username'] ?? '';
    final profilePictureUrl = widget.userData?['profilePictureUrl'];
    final formattedDate = _formatTimestamp(widget.post.timestamp.toDate());

    return InkWell(
      onTap: widget.onTap,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserProfileScreen(userId: widget.post.userId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      radius: 24,
                      child: profilePictureUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profilePictureUrl,
                                fit: BoxFit.cover,
                                width: 48,
                                height: 48,
                                placeholder: (context, url) => Skeletonizer(
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey[300],
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            )
                          : CustomAvatar(
                              userId: widget.post.userId,
                              username: username,
                              size: 48,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(
                                username,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (widget.post.cw != null) ...[
                Text(
                  widget.post.cw!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isContentVisible = !_isContentVisible;
                        });
                      },
                      child: Text(_isContentVisible ? 'Hide' : 'Show More'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_isContentVisible || widget.post.cw == null) ...[
                if (widget.post.content != null)
                  Text(
                    widget.post.content!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                if (widget.post.mediaInfo != null)
                  MediaDisplay(
                      mediaInfo: widget.post.mediaInfo!, detail: widget.detail),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.reply),
                    onPressed: () {
                      const PostCreationScreen();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat),
                    onPressed: () {
                      // Implement repost functionality
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // Implement like functionality
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Implement share functionality
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
