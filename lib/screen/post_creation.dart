import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../provider/auth.dart';
import '../service/post_service.dart';
import '../service/user_service.dart';
import '../widgets/custom_avatar.dart';

class PostCreationScreen extends StatefulWidget {
  const PostCreationScreen({super.key});

  @override
  _PostCreationScreenState createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen> {
  final _contentController = TextEditingController();
  final _cwController = TextEditingController();
  final List<File> _mediaFiles = [];
  final PostService _postService = PostService();
  bool _cwEnabled = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authProvider =
          Provider.of<CustomAuthProvider>(context, listen: false);
      _userData = await UserService().getUserData(authProvider.user!.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자 데이터를 로드하는 동안 오류가 발생했습니다: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _cwController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final pickedFiles = await ImagePicker().pickMultipleMedia();
    setState(() {
      _mediaFiles.addAll(pickedFiles.map((file) => File(file.path)).toList());
    });
  }

  Future<void> _uploadPost() async {
    if (_contentController.text.isEmpty && _mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력하거나 미디어를 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      await _postService.createPost(
        content: _contentController.text,
        mediaFiles: _mediaFiles,
        cw: _cwEnabled ? _cwController.text : null,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시물 업로드 중 오류가 발생했습니다: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuthProvider>(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('새 게시물'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child:
                      const Text('게시', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
          body: _userData == null
              ? Container()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              radius: 24,
                              child: _userData!['profilePictureUrl'] != null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            _userData!['profilePictureUrl'],
                                        fit: BoxFit.cover,
                                        width: 48,
                                        height: 48,
                                        placeholder: (context, url) =>
                                            Skeletonizer(
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
                                      userId: authProvider.user!.uid,
                                      username: _userData!['username'],
                                      size: 48,
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Text(_userData!['username'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_cwEnabled)
                          TextField(
                            controller: _cwController,
                            decoration: const InputDecoration(
                              hintText: "열람 주의 설명",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        TextField(
                          controller: _contentController,
                          decoration: const InputDecoration(
                            hintText: "무슨 생각을 하고 계신가요?",
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 20),
                        _mediaFiles.isEmpty
                            ? const Center(child: Text('선택된 미디어 없음'))
                            : SizedBox(
                                height: 150,
                                child: ReorderableListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.zero,
                                  onReorder: (oldIndex, newIndex) {
                                    setState(() {
                                      if (newIndex > oldIndex) newIndex -= 1;
                                      final item =
                                          _mediaFiles.removeAt(oldIndex);
                                      _mediaFiles.insert(newIndex, item);
                                    });
                                  },
                                  children: _mediaFiles.map((file) {
                                    final index = _mediaFiles.indexOf(file);
                                    return Card(
                                      key: ValueKey(file),
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 150,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: FileImage(file),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: IconButton(
                                              icon: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _mediaFiles.removeAt(index);
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
          bottomNavigationBar: BottomAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                    icon: const Icon(Icons.image), onPressed: _pickMedia),
                IconButton(
                  icon: const Icon(Icons.warning),
                  onPressed: () {
                    setState(() {
                      _cwEnabled = !_cwEnabled;
                    });
                  },
                  color: _cwEnabled ? Theme.of(context).primaryColor : null,
                ),
              ],
            ),
          ),
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }
}
