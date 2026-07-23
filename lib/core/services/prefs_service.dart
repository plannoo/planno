import 'package:shared_preferences/shared_preferences.dart';
import 'token_storage.dart';

/// Centralized persistence service for Wrenta.
///
/// Sensitive data (JWT tokens) use [TokenStorage] which picks the best
/// backend per platform — [FlutterSecureStorage] on mobile, [SharedPreferences]
/// on desktop/web (where secure storage native plugins may not be available).
/// Non-sensitive profile/preference data remain in [SharedPreferences].
class PrefsService {
  PrefsService._();

  static final TokenStorage _tokenStorage = createTokenStorage();

  // ── Keys ────────────────────────────────────────────────────────────────────

  static const _kHasSeenOnboarding = 'has_seen_onboarding';
  static const _kIsLoggedIn        = 'is_logged_in';
  static const _kUserEmail         = 'user_email';
  static const _kUserName          = 'user_name';
  static const _kEmployeeId        = 'employee_id';
  static const _kRememberedEmail   = 'remembered_email';
  static const _kLanguageCode      = 'language_code';
  static const _kThemeMode         = 'theme_mode';
  // ── Generic view preferences ─────────────────────────────────────────────────
  // Local-only UI toggles (schedule view options, notification type prefs, etc.).
  // Keys are namespaced by the caller to avoid collisions.

  static Future<bool> getViewBool(String key, {bool fallback = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('view_pref_$key') ?? fallback;
  }

  static Future<void> setViewBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('view_pref_$key', value);
  }

  // ── Onboarding ──────────────────────────────────────────────────────────────

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasSeenOnboarding) ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboarding, true);
  }

  // ── Auth session ────────────────────────────────────────────────────────────

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final flagSet  = prefs.getBool(_kIsLoggedIn) ?? false;
    final token    = await _tokenStorage.getAccessToken();
    return flagSet && token != null;
  }

  static Future<void> saveLoginSession({
    required String email,
    String? name,
    bool rememberEmail = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setString(_kUserEmail, email);
    if (name != null) await prefs.setString(_kUserName, name);
    if (rememberEmail) {
      await prefs.setString(_kRememberedEmail, email);
    } else {
      await prefs.remove(_kRememberedEmail);
    }
  }

  static Future<void> saveRegistration({
    required String email,
    required String name,
    required String employeeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setString(_kUserEmail, email);
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kEmployeeId, employeeId);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsLoggedIn);
    await prefs.remove(_kUserEmail);
    await prefs.remove(_kUserName);
    await prefs.remove(_kEmployeeId);
    await _tokenStorage.clearTokens();
  }

  // ── Token management ──────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      _tokenStorage.saveTokens(
          accessToken: accessToken, refreshToken: refreshToken);

  static Future<String?> getAccessToken() =>
      _tokenStorage.getAccessToken();

  static Future<String?> getRefreshToken() =>
      _tokenStorage.getRefreshToken();

  static Future<void> clearTokens() =>
      _tokenStorage.clearTokens();

  // ── Profile getters ──────────────────────────────────────────────────────────

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserEmail);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserName);
  }

  static Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmployeeId);
  }

  static Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRememberedEmail);
  }

  // ── Language / Locale ───────────────────────────────────────────────────────

  static Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLanguageCode);
  }

  static Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageCode, code);
  }

  // ── Theme mode ───────────────────────────────────────────────────────────────

  static Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeMode);
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode);
  }
}
