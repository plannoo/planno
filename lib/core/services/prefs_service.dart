import 'package:shared_preferences/shared_preferences.dart';

/// Centralized SharedPreferences service for Aplano.
///
/// Keys are private constants — always access via the typed methods below.
/// Nothing outside this class touches [SharedPreferences] directly.
class PrefsService {
  PrefsService._();

  // ── Keys ────────────────────────────────────────────────────────────────────

  static const _kHasSeenOnboarding = 'has_seen_onboarding';
  static const _kIsLoggedIn        = 'is_logged_in';
  static const _kUserEmail         = 'user_email';
  static const _kUserName          = 'user_name';
  static const _kEmployeeId        = 'employee_id';
  static const _kRememberedEmail   = 'remembered_email';

  // Token keys — intentionally separate from user-profile keys so
  // clearTokens() can invalidate the session without wiping profile data.
  static const _kAccessToken  = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';

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

  // ── Auth session ────────────────────────────────────────────────────────────

  /// Returns true if the user has an active login session.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    // A session is valid when the logged-in flag is set AND a token exists.
    final flagSet    = prefs.getBool(_kIsLoggedIn) ?? false;
    final hasToken   = prefs.getString(_kAccessToken) != null;
    return flagSet && hasToken;
  }

  /// Persists a successful login session (profile data only).
  /// Call [saveTokens] separately with the tokens returned by the API.
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

  /// Persists a new account registration (also sets the logged-in flag).
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

  /// Clears the session flag and all profile data (logout).
  /// Tokens are cleared separately via [clearTokens].
  /// The remembered email and onboarding flag are intentionally preserved.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsLoggedIn);
    await prefs.remove(_kUserEmail);
    await prefs.remove(_kUserName);
    await prefs.remove(_kEmployeeId);
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
  }

  // ── Token management ─────────────────────────────────────────────────────────

  /// Persists the JWT access token and refresh token returned by the API.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, accessToken);
    await prefs.setString(_kRefreshToken, refreshToken);
  }

  /// Returns the current JWT access token, or null if not logged in.
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }

  /// Returns the refresh token, or null if not present.
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken);
  }

  /// Removes both tokens (called when a refresh attempt fails).
  /// Does NOT clear profile data — use [logout] for a full sign-out.
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
  }

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

  /// Returns the remembered email for pre-filling the login form, if any.
  static Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRememberedEmail);
  }
}