import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  String id;
  String? name;
  String username;
  String? profilePictureUrl;
  Timestamp createdAt;
  int followingCount;
  int followerCount;
  List<String> deviceTokens; // Device Tokens 필드 추가

  UserProfile(
      {required this.id,
      this.name,
      required this.username,
      this.profilePictureUrl,
      required this.createdAt,
      required this.followingCount,
      required this.followerCount,
      required this.deviceTokens});

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserProfile(
        id: doc.id,
        name: data['name'] ?? data['username'],
        username: data['username'],
        profilePictureUrl: data['profilePictureUrl'],
        createdAt: data['createdAt'] as Timestamp,
        followingCount: data['followingCount'],
        followerCount: data['followerCount'],
        deviceTokens:
            List<String>.from(data['deviceTokens'] ?? [])); // deviceTokens 초기화
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt,
      'followingCount': followingCount,
      'followerCount': followerCount,
      'deviceTokens': deviceTokens // deviceTokens 필드 추가
    };
  }

  // deviceTokens에 새로운 토큰 추가
  void addDeviceToken(String token) {
    if (!deviceTokens.contains(token)) {
      deviceTokens.add(token);
    }
  }

  // deviceTokens에서 토큰 삭제
  void removeDeviceToken(String token) {
    deviceTokens.remove(token);
  }
}
