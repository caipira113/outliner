import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:outliner/screen/post_detail_screen.dart';
import 'package:outliner/screen/user_screen.dart';
import 'package:outliner/service/user_service.dart';

import '../model/post.dart';
import '../widgets/post_widget.dart';

enum SearchOption {
  none,
  posts,
  people,
  goTo,
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchTextController = TextEditingController();
  SearchOption _searchOption = SearchOption.none;
  List<String> _searchOptions = [];
  bool _isSearching = false;

  final HitsSearcher _postsSearcher = HitsSearcher(
    applicationID: 'KWNVGU4007',
    apiKey: '82fd462ec0d26d96a491d67b588bcb96',
    indexName: 'outliner',
  );

  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);
  final Map<String, Map<String, dynamic>> _userCache = {};

  void _onSearchChanged() {
    final query = _searchTextController.text;
    setState(() {
      _isSearching = query.isNotEmpty;
      _searchOptions = _isSearching
          ? [
              'Posts with "$query"',
              'People with "$query"',
              'Go to @${query.split(' ').first}'
            ]
          : [];
      if (_searchOption != SearchOption.none && query.isNotEmpty) {
        _searchOption =
            SearchOption.none; // Reset search option to prompt re-selection
      }
    });
  }

  void _onOptionSelected(String option) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);

    setState(() {
      if (option.startsWith('Posts with')) {
        _searchOption = SearchOption.posts;
      } else if (option.startsWith('People with')) {
        _searchOption = SearchOption.people;
      } else if (option.startsWith('Go to')) {
        _searchOption = SearchOption.goTo;
      } else {
        _searchOption = SearchOption.none;
      }
      _isSearching = false; // Hide search options
    });

    if (_searchOption == SearchOption.posts) {
      _pagingController.refresh();
    } else if (_searchOption == SearchOption.goTo) {
      final userId = await UserService()
          .getUserIdByUsername(_searchTextController.text.split(' ').first);
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              userId: userId, // Extract userId from query
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user found.'),
          ),
        );
      }
    }
  }

  Future<void> _fetchPosts(int pageKey) async {
    try {
      _postsSearcher.applyState((state) => state.copyWith(
            query: _searchTextController.text,
            page: pageKey,
          ));

      final response = await _postsSearcher.responses.first;
      final hitsPage = HitsPage.fromResponse(response);

      for (var post in hitsPage.items) {
        if (!_userCache.containsKey(post.userId)) {
          _userCache[post.userId] =
              await UserService().getUserData(post.userId);
        }
      }

      final isLastPage = hitsPage.nextPageKey == null;
      if (isLastPage) {
        _pagingController.appendLastPage(hitsPage.items);
      } else {
        _pagingController.appendPage(hitsPage.items, hitsPage.nextPageKey!);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchTextController.addListener(_onSearchChanged);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPosts(pageKey);
    });

    _searchTextController.addListener(() {
      _pagingController.refresh();
    });
  }

  @override
  void dispose() {
    _searchTextController.removeListener(_onSearchChanged);
    _searchTextController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(10.0),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchTextController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search',
                  // TODO: 검색 아이콘 너무 좌측임
                  // TODO: 색상 조정
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                  ),
                ),
              ),
            ),
            _searchOption == SearchOption.none && _isSearching
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _searchOptions.map((option) {
                        return ListTile(
                          title: Text(option),
                          onTap: () => _onOptionSelected(option),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
            if (_searchOption == SearchOption.posts)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: PagedListView<int, Post>(
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
                      firstPageProgressIndicatorBuilder: (context) =>
                          const Center(
                        child: CircularProgressIndicator(),
                      ),
                      newPageProgressIndicatorBuilder: (context) =>
                          const Center(
                        child: CircularProgressIndicator(),
                      ),
                      noItemsFoundIndicatorBuilder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HitsPage {
  const HitsPage(this.items, this.pageKey, this.nextPageKey);

  final List<Post> items;
  final int pageKey;
  final int? nextPageKey;

  factory HitsPage.fromResponse(SearchResponse response) {
    final items = response.hits.map(Post.fromJson).toList();
    final isLastPage = response.page >= response.nbPages;
    final nextPageKey = isLastPage ? null : response.page + 1;
    return HitsPage(items, response.page, nextPageKey);
  }
}
