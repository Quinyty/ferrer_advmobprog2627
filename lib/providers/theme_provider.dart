import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;
  bool get isLight => !_isDark;

  void toggleTheme(bool isDarkMode) {
    _isDark = isDarkMode;
    notifyListeners();
  }
}