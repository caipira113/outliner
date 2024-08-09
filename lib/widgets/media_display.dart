import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MediaDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> mediaInfo;
  final bool detail;

  const MediaDisplay({
    super.key,
    required this.mediaInfo,
    this.detail = false,
  });

  @override
  Widget build(BuildContext context) {
    if (detail) {
      return _buildDetailView();
    } else {
      return _buildCompactView();
    }
  }

  Widget _buildDetailView() {
    int crossAxisCount = 3;

    if (mediaInfo.length == 1) {
      crossAxisCount = 1;
    } else if (mediaInfo.length == 2 || mediaInfo.length == 4) {
      crossAxisCount = 2;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: mediaInfo.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _buildMediaItem(mediaInfo[index]),
    );
  }

  Widget _buildCompactView() {
    switch (mediaInfo.length) {
      case 0:
        return const SizedBox.shrink();
      case 1:
        return _buildMediaItem(mediaInfo[0]);
      case 2:
        return Row(
          children: mediaInfo
              .map((media) => Expanded(child: _buildMediaItem(media)))
              .toList(),
        );
      case 3:
        return Row(
          children: [
            Expanded(child: _buildMediaItem(mediaInfo[0])),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildMediaItem(mediaInfo[1])),
                  Expanded(child: _buildMediaItem(mediaInfo[2])),
                ],
              ),
            ),
          ],
        );
      case 4:
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: mediaInfo.map((media) => _buildMediaItem(media)).toList(),
        );
      default:
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...mediaInfo.take(3).map((media) => _buildMediaItem(media)),
            _buildRemainingMediaItem(
              mediaInfo.length - 3,
              mediaInfo[3]['url'],
            ),
          ],
        );
    }
  }

  Widget _buildMediaItem(Map<String, dynamic> media) {
    final url = media['url'];
    final mimeType = media['type'];

    if (mimeType != null) {
      if (mimeType.startsWith('image/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Skeletonizer(
              child: Container(
                color: Colors.grey[300],
              ),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );
      } else if (mimeType.startsWith('video/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: VideoPlayerWidget(url: url),
        );
      }
    }
    return const Center(child: Text('Unsupported media type'));
  }

  Widget _buildRemainingMediaItem(
      int remainingCount, String backgroundImageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 배경 이미지 (블러 처리)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: backgroundImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Skeletonizer(
              child: Container(
                color: Colors.grey[300],
              ),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            imageBuilder: (context, imageProvider) => ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // 어두운 오버레이
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        // 텍스트
        Center(
          child: Text(
            '+$remainingCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class VideoPlayerWidget extends StatelessWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: Colors.white, size: 50),
      ),
    );
  }
}
