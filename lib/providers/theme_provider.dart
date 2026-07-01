import 'package:flutter/material.dart';
import '../core/services/prefs_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider._();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  static Future<ThemeProvider> create() async {
    final provider = ThemeProvider._();
    await provider._load();
    return provider;
  }

  Future<void> _load() async {
    final saved = await PrefsService.getThemeMode();
    _themeMode = _fromString(saved);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await PrefsService.saveThemeMode(_toString(mode));
    notifyListeners();
  }

  Future<void> toggle() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  static ThemeMode _fromString(String? s) {
    switch (s) {
      case 'dark':   return ThemeMode.dark;
      case 'light':  return ThemeMode.light;
      default:       return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:   return 'dark';
      case ThemeMode.light:  return 'light';
      case ThemeMode.system: return 'system';
    }
  }
}
