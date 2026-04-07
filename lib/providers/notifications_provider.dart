import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  bool _enabled = true; // default true

  bool get isEnabled => _enabled;

  void setNotification(bool value) {
    _enabled = value;
    notifyListeners();
  }
}