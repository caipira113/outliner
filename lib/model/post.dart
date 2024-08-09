import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String id;
  String userId;
  String? content;
  Timestamp timestamp;
  List<Map<String, dynamic>>? mediaInfo; // 이미지나 비디오의 URL 및 MIME 타입
  String? cw; // 본문을 숨길 때 사용할 제목 또는 요약
  String? replyTo; // 답장하는 포스트의 ID
  String? repostOf; // 리포스트하는 포스트의 ID

  Post({
    required this.id,
    required this.userId,
    this.content,
    required this.timestamp,
    this.mediaInfo,
    this.cw,
    this.replyTo,
    this.repostOf,
  });

  static Post fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? json['objectID'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'],
      timestamp: json['timestamp'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['timestamp'])
          : Timestamp.now(),
      mediaInfo: json['mediaInfo'] != null
          ? List<Map<String, dynamic>>.from(json['mediaInfo'])
          : null,
      cw: json['cw'],
      replyTo: json['replyTo'],
      repostOf: json['repostOf'],
    );
  }

  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'],
      timestamp: data['timestamp'] as Timestamp,
      mediaInfo: List<Map<String, dynamic>>.from(data['mediaInfo'] ?? []),
      cw: data['cw'],
      replyTo: data['replyTo'],
      repostOf: data['repostOf'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'timestamp': timestamp,
      'mediaInfo': mediaInfo,
      'cw': cw,
      'replyTo': replyTo,
      'repostOf': repostOf,
    };
  }
}
