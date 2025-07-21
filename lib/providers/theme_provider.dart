// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider with ChangeNotifier {
  late Box _box;
  final String _themeKey = 'themeMode';

  // --- PERUBAHAN 1: Nilai awal diubah menjadi light ---
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox('settings');
    _loadTheme();
  }

  void _loadTheme() {
    // --- PERUBAHAN 2: Nilai default dari penyimpanan diubah menjadi 'light' ---
    final themeString = _box.get(_themeKey, defaultValue: 'light');

    switch (themeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default: // 'system'
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    String themeString;
    switch (themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      default:
        themeString = 'system';
    }
    await _box.put(_themeKey, themeString);
    notifyListeners();
  }
}