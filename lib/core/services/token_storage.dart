import 'package:shared_preferences/shared_preferences.dart';

/// Abstract token persistence.
///
/// On mobile (Android/iOS) you can swap this for a `SecureTokenStorage`
/// backed by `flutter_secure_storage` by adding that package and
/// uncommenting the class below. For desktop/web, `SharedPreferences`
/// is the only viable option without platform-specific native code.
abstract class TokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}

TokenStorage createTokenStorage() => SharedPreferencesTokenStorage();

class SharedPreferencesTokenStorage implements TokenStorage {
  static const _kAccessToken  = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, accessToken);
    await prefs.setString(_kRefreshToken, refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken);
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
  }
}
