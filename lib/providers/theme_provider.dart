import 'package:flutter/material.dart';
import '../theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeData get currentTheme => getAppTheme(isDark: _isDark);

  void toggleTheme(bool value) {
    _isDark = value;
    notifyListeners();
  }
}