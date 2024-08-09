import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../bloc/timeline_bloc.dart';
import '../model/post.dart';
import '../screen/post_detail_screen.dart';
import '../service/user_service.dart';
import '../widgets/post_widget.dart';

class TimelineWidget extends StatefulWidget {
  final String userId;
  final PostFilter filter;
  final bool me;

  const TimelineWidget({
    required this.userId,
    this.filter = PostFilter.all,
    required this.me,
    super.key,
  });

  @override
  _TimelineWidgetState createState() => _TimelineWidgetState();
}

enum PostFilter { all, replies, media }

class _TimelineWidgetState extends State<TimelineWidget> {
  late final TimelineBloc _timelineBloc;
  final Map<String, Map<String, dynamic>> _userCache = {};

  static const _pageSize = 20; // Number of items per page
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _timelineBloc = TimelineBloc(widget.userId);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPosts(pageKey, widget.me);
    });

    _timelineBloc.getNewPosts().listen((post) {
      if (_shouldShowPost(post)) {
        _pagingController.itemList?.insert(0, post);
        _pagingController.notifyListeners();
      }
    });
  }

  bool _shouldShowPost(Post post) {
    switch (widget.filter) {
      case PostFilter.replies:
        return post.replyTo != null;
      case PostFilter.media:
        return post.mediaInfo != null && post.mediaInfo!.isNotEmpty;
      case PostFilter.all:
      default:
        return true;
    }
  }

  Future<void> _fetchPosts(int pageKey, bool me) async {
    try {
      final posts =
          await _timelineBloc.loadPosts(refresh: pageKey == 0, me: me);
      final filteredPosts = posts.where(_shouldShowPost).toList();
      final isLastPage = filteredPosts.length < _pageSize;

      final userIds = filteredPosts.map((post) => post.userId).toSet();
      final userDataMap = await _fetchUserData(userIds);

      if (isLastPage) {
        _pagingController.appendLastPage(filteredPosts);
      } else {
        final nextPageKey = pageKey + filteredPosts.length;
        _pagingController.appendPage(filteredPosts, nextPageKey);
      }

      setState(() {
        _userCache.addAll(userDataMap);
      });
    } catch (e) {
      _pagingController.error = e;
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUserData(
      Set<String> userIds) async {
    final userDataMap = <String, Map<String, dynamic>>{};
    for (final userId in userIds) {
      if (!_userCache.containsKey(userId)) {
        userDataMap[userId] = await UserService().getUserData(userId);
      }
    }
    return userDataMap;
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<int, Post>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<Post>(
        itemBuilder: (context, post, index) {
          final userData = _userCache[post.userId];
          return PostWidget(
            key: ValueKey(post.id),
            post: post,
            userData: userData,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(
                  post: post,
                  userData: userData,
                ),
              ),
            ),
          );
        },
        firstPageProgressIndicatorBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        newPageProgressIndicatorBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        noItemsFoundIndicatorBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _timelineBloc.dispose();
    super.dispose();
  }
}
