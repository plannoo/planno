/// Central configuration for all HTTP communication.
///
/// Swap [baseUrl] per environment by reading a build-time flag:
///   --dart-define=API_BASE_URL=https://staging.aplano.io
class ApiConfig {
  ApiConfig._();

  // ── Base URL ───────────────────────────────────────────────────────────────

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.aplano.io',
  );

  // ── Timeouts ───────────────────────────────────────────────────────────────

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout    = Duration(seconds: 15);

  // ── Auth endpoints ─────────────────────────────────────────────────────────

  static const String login        = '/api/auth/login';
  static const String refreshToken = '/api/auth/refresh';
  static const String logout       = '/api/auth/logout';

  // ── User endpoints ─────────────────────────────────────────────────────────
   /// GET: Retrieve current user profile.
  static const String me            = '/api/users/me';
   /// PUT/PATCH: Update current user profile.
  static const String updateProfile = '/api/users/me';

  // ── Shift endpoints ────────────────────────────────────────────────────────

  static const String shifts = '/api/shifts';

  // ── Absence endpoints ──────────────────────────────────────────────────────

  static const String absences = '/api/absences';

  // ── Clock endpoints ────────────────────────────────────────────────────────

  static const String clockIn  = '/api/clock/in';
  static const String clockOut = '/api/clock/out';
}