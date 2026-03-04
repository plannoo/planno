import 'package:flutter/material.dart';

import '../../core/services/prefs_service.dart';

/// Holds the app's active [Locale] and persists it across restarts.
///
/// Usage:
/// ```dart
/// // Switch to German
/// context.read<LocaleProvider>().setLocale(const Locale('de'));
///
/// // Read current locale
/// context.watch<LocaleProvider>().locale
/// ```
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // default until loaded

  Locale get locale => _locale;

  /// Call once at startup (before runApp) to restore the saved locale.
  Future<void> loadSavedLocale() async {
    final code = await PrefsService.getLanguageCode();
    if (code != null) {
      _locale = Locale(code);
      // No notifyListeners() here — called before the tree is built.
    }
  }

  /// Switches the app language at runtime and persists the choice.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await PrefsService.saveLanguageCode(locale.languageCode);
    notifyListeners();
  }

  bool get isGerman  => _locale.languageCode == 'de';
  bool get isEnglish => _locale.languageCode == 'en';
}