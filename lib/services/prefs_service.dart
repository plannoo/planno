import 'package:shared_preferences/shared_preferences.dart';

/// Centralized SharedPreferences service for Aplano.
///
/// Keys are private constants — always access via the typed methods below.
class PrefsService {
  PrefsService._();

  // ── Keys ────────────────────────────────────────────────────────────────────
  static const _kHasSeenOnboarding = 'has_seen_onboarding';
  static const _kIsLoggedIn        = 'is_logged_in';
  static const _kUserEmail         = 'user_email';
  static const _kUserName          = 'user_name';
  static const _kEmployeeId        = 'employee_id';
  static const _kRememberedEmail   = 'remembered_email';

  // ── Onboarding ──────────────────────────────────────────────────────────────

  /// Returns true once the user has completed or skipped onboarding.
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasSeenOnboarding) ?? false;
  }

  /// Call when the user finishes or skips the onboarding flow.
  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboarding, true);
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  /// Returns true if the user is currently logged in.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsLoggedIn) ?? false;
  }

  /// Persists a successful login session.
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

  /// Persists a new account registration.
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

  /// Clears the login session (logout).
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep remembered email and onboarding flag — only clear session
    await prefs.remove(_kIsLoggedIn);
    await prefs.remove(_kUserEmail);
    await prefs.remove(_kUserName);
    await prefs.remove(_kEmployeeId);
  }

  // ── Getters ─────────────────────────────────────────────────────────────────

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

  /// Returns the remembered email for pre-filling the login form, if any.
  static Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRememberedEmail);
  }
}