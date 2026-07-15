import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/prefs_service.dart';

/// Manages the active app locale and persists the user's choice.
///
/// Wire into [MaterialApp] via [ChangeNotifierProvider]:
/// ```dart
/// MaterialApp(
///   locale: context.watch<LocaleProvider>().locale,
///   supportedLocales: LocaleProvider.supported,
///   ...
/// )
/// ```
class LocaleProvider extends ChangeNotifier {
  LocaleProvider._();

  static const List<Locale> supported = [
    Locale('en'),
    Locale('de'),
  ];

  /// Default locale. Overwritten by [load] if a preference is stored.
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool get isGerman => _locale.languageCode == 'de';

  bool get isEnglish => _locale.languageCode == 'en';

  /// Load the saved locale from [PrefsService]. Call once at startup.
  static Future<LocaleProvider> create() async {
    final provider = LocaleProvider._();
    await provider._load();
    return provider;
  }

  Future<void> _load() async {
    final code = await PrefsService.getLanguageCode();
    if (code != null) {
      _locale = Locale(code);
      Intl.defaultLocale = code;
    }
  }

  /// Switch to [locale] and persist the choice.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    Intl.defaultLocale = locale.languageCode;
    await PrefsService.saveLanguageCode(locale.languageCode);
    notifyListeners();
  }

  /// Convenience: set by language code string.
  Future<void> setLanguageCode(String code) =>
      setLocale(Locale(code));
}