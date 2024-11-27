import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners(); // UI 업데이트
  }

  void clearUser() {
    _userId = null;
    notifyListeners();
  }
}
