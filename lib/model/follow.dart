import 'package:cloud_firestore/cloud_firestore.dart';

class Follow {
  String followerId; // 팔로우하는 사용자 ID
  String followingId; // 팔로우되는 사용자 ID
  Timestamp timestamp;

  Follow({
    required this.followerId,
    required this.followingId,
    required this.timestamp,
  });

  factory Follow.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Follow(
      followerId: data['followerId'] ?? '',
      followingId: data['followingId'] ?? '',
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'timestamp': timestamp,
    };
  }
}
