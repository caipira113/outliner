import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outliner/custom_text_field.dart';
import 'package:outliner/widgets/custom_avatar.dart';
import 'package:outliner/widgets/timeline_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../service/follow_service.dart';
import '../service/user_service.dart';

class CommonProfileScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const CommonProfileScreen({
    super.key,
    required this.userId,
    required this.isCurrentUser,
  });

  @override
  _CommonProfileScreenState createState() => _CommonProfileScreenState();
}

class _CommonProfileScreenState extends State<CommonProfileScreen> {
  final UserService _userService = UserService();
  final FollowService _followService = FollowService();
  late Future<DocumentSnapshot> _userDataFuture;
  File? _imageFile;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _username;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _userService.getUserDoc(widget.userId);
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    _isFollowing = await _followService.isFollowing(widget.userId);
    setState(() {});
  }

  Future<void> removeMyDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null && token != null) {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'deviceTokens': FieldValue.arrayRemove([token]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (widget.isCurrentUser)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await removeMyDeviceToken();
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error loading profile.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfilePicture(
                          userData['profilePictureUrl'], userData['username']),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 100),
                        child: _isEditing
                            ? _buildEditProfileForm(userData)
                            : _buildProfileDetails(userData),
                      ),
                      const SizedBox(height: 20),
                      if (!widget.isCurrentUser) _buildFollowButton(),
                      // 팔로우 버튼 추가
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    const TabBar(
                      tabs: [
                        Tab(text: 'Posts'),
                        Tab(text: 'Replies'),
                        Tab(text: 'Media'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ],
              body: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TabBarView(
                  children: [
                    TimelineWidget(
                      userId: widget.userId,
                      filter: PostFilter.all,
                      me: true,
                    ),
                    TimelineWidget(
                      userId: widget.userId,
                      filter: PostFilter.replies,
                      me: true,
                    ),
                    TimelineWidget(
                      userId: widget.userId,
                      filter: PostFilter.media,
                      me: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePicture(String? profilePictureUrl, String username) {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[200],
        child: profilePictureUrl != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: profilePictureUrl,
                  fit: BoxFit.cover,
                  width: 100,
                  height: 100,
                  placeholder: (context, url) => Skeletonizer(
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              )
            : CustomAvatar(
                userId: widget.userId,
                username: username,
                size: 100,
              ),
      ),
    );
  }

  Widget _buildProfileDetails(Map<String, dynamic> userData) {
    return Column(
      children: [
        Text(
          userData['name'] ?? userData['username'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        Text(userData['username'] ?? 'Unknown User'),
        const SizedBox(height: 16),
        _buildFollowInfo(
            userData['followingCount'] ?? 0, userData['followerCount'] ?? 0),
        if (widget.isCurrentUser) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ],
    );
  }

  Widget _buildEditProfileForm(Map<String, dynamic> userData) {
    _name = userData['name'];
    _username = userData['username'];
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            initialValue: _name,
            labelText: 'Name',
            onSaved: (value) {
              _name = value;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            initialValue: _username,
            labelText: 'Username',
            onSaved: (value) {
              _username = value;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowInfo(int following, int follower) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFollowColumn(following, 'Following'),
        const SizedBox(width: 24),
        _buildFollowColumn(follower, 'Followers'),
      ],
    );
  }

  Widget _buildFollowColumn(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildFollowButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_isFollowing) {
          await _followService.unfollowUser(widget.userId);
        } else {
          await _followService.followUser(widget.userId);
        }
        _checkFollowStatus();
      },
      child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
    );
  }

  Future<void> _pickImage() async {
    if (!widget.isCurrentUser) return;
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _userService.updateProfilePicture(widget.userId, _imageFile!);
      setState(() {
        _userDataFuture = _userService.getUserDoc(widget.userId);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _userService.updateUserProfile(_name, _username!);
      setState(() {
        _isEditing = false;
        _userDataFuture = _userService.getUserDoc(widget.userId);
      });
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
