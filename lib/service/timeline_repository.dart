import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/post.dart';
import 'follow_service.dart';

class TimelineRepository {
  final String userId;
  final int pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMorePosts = true;
  final FollowService _followService = FollowService();

  TimelineRepository(this.userId);

  Future<List<Post>> getTimelinePosts(
      {bool refresh = false, bool me = false}) async {
    if (refresh) {
      _lastDocument = null;
      _hasMorePosts = true;
    }

    if (!_hasMorePosts) return [];

    final followingIds = await _followService.getFollowingList(userId, me);
    followingIds.add(userId);

    print(followingIds);

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', whereIn: followingIds)
        .orderBy('timestamp', descending: true)
        .limit(pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      _hasMorePosts = false;
      return [];
    }

    _lastDocument = snapshot.docs.last;
    return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
  }

  Stream<Post> getNewPosts({bool me = false}) {
    return Stream.fromFuture(_followService.getFollowingList(userId, me))
        .asyncExpand((followingIds) {
      followingIds.add(userId);
      return FirebaseFirestore.instance
          .collection('posts')
          .where('userId', whereIn: followingIds)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) => snapshot.docs.isNotEmpty
              ? Post.fromDocument(snapshot.docs.first)
              : null)
          .where((post) => post != null)
          .cast<Post>();
    });
  }
}
