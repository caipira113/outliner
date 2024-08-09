import 'dart:async';

import 'package:outliner/service/timeline_repository.dart';

import '../model/post.dart';

class TimelineBloc {
  final TimelineRepository _repository;
  bool _isLoading = false;
  bool _hasMorePosts = true;

  TimelineBloc(String userId) : _repository = TimelineRepository(userId);

  Stream<Post> getNewPosts() {
    return _repository.getNewPosts();
  }

  Future<List<Post>> loadPosts({bool refresh = false, bool me = false}) async {
    if (_isLoading || !_hasMorePosts) return [];
    _isLoading = true;

    try {
      final posts =
          await _repository.getTimelinePosts(refresh: refresh, me: me);
      if (posts.isEmpty) {
        _hasMorePosts = false;
      }
      return posts;
    } finally {
      _isLoading = false;
    }
  }

  void dispose() {
    // Dispose resources if needed
  }
}
