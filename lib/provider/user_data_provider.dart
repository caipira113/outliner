import 'package:flutter/material.dart';

import '../service/user_service.dart';

class UserDataProvider with ChangeNotifier {
  final UserService _userService = UserService();
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  Map<String, dynamic> get userData => _userData;

  bool get isLoading => _isLoading;

  UserDataProvider(String uid) {
    _loadUserData(uid);
  }

  Future<void> _loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _userData = await _userService.getUserData(uid);
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
