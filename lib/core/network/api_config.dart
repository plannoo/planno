/// Central configuration for all HTTP communication.
///
/// Swap [baseUrl] per environment by reading a build-time flag:
///   --dart-define=API_BASE_URL=https://staging.aplano.io
class ApiConfig {
  ApiConfig._();

  // ── Base URL ───────────────────────────────────────────────────────────────

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3052'
  );

  // ── Timeouts ───────────────────────────────────────────────────────────────
  // Generous connect timeout: the Neon serverless Postgres backing this API
  // cold-starts and the first request after idle can take 10–20s. A 10s
  // connect timeout was aborting work-location/profile loads and blocking
  // clock-in ("Work location not loaded yet").
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout    = Duration(seconds: 20);

  // ── Auth endpoints ─────────────────────────────────────────────────────────

  static const String login        = '/api/auth/login';
  static const String register     = '/api/auth/register';
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

  static const String absenceCalendar     = '/api/absences/calendar';
  static const String absenceSubmit       = '/api/absences';
  static const String absenceListDetailed = '/api/absences/list/detailed';
  static const String absenceEntitlement  = '/api/absences/entitlement';
  static const String schoolHolidays      = '/api/absences/school-holidays';

  // ── Clock endpoints ────────────────────────────────────────────────────────

  static const String clockIn       = '/api/clock/in';
  static const String clockOut      = '/api/clock/out';
  static const String breakStart    = '/api/clock/break/start';
  static const String breakEnd      = '/api/clock/break/end';
  static const String clockOverride = '/api/clock/override-request';
  static const String clockSession  = '/api/clock/session';
  static const String clockToday    = '/api/clock/activities/today';

  // ── Profile endpoints ──────────────────────────────────────────────────────

  static const String changePassword  = '/api/profile/change-password';
  // Backend mounts these under /api (userRoutes), not /api/v1.
  static const String clockPin        = '/api/me/clock-pin';
  static const String regeneratePin   = '/api/me/regenerate-pin';
  static const String terminalMobileClock = '/api/terminal/mobile-clock';

  // ── Work Locations ─────────────────────────────────────────────────────────

  static const String workLocations     = '/api/work-locations';
  static const String myWorkLocation    = '/api/work-locations/my-location';

  // ── Documents ──────────────────────────────────────────────────────────────

  static const String documentsMe       = '/api/documents/me';
  static String documentMe(String id)   => '/api/documents/me/$id';

  // ── Availabilities ──────────────────────────────────────────────────────────

  static const String availabilitiesMe    = '/api/availabilities/me';
  static const String availabilitiesCheck = '/api/availabilities/check';

  // ── Announcements ───────────────────────────────────────────────────────────

  static const String announcements       = '/api/announcements';
  static const String announcementUnread  = '/api/announcements/unread-count';
  static const String announcementReadAll = '/api/announcements/read-all';

  static String markAnnouncementRead(String id) => '/api/announcements/$id/read';

  // ── Timesheets ──────────────────────────────────────────────────────────────

  static const String timesheetWeek  = '/api/timesheets/me/week';
  static const String timesheetMonth = '/api/timesheets/me/month';

  // ── Notifications ───────────────────────────────────────────────────────────

  static const String notifications           = '/api/notifications';
  static const String notificationsUnread     = '/api/notifications/unread-count';
  static const String notificationsReadAll    = '/api/notifications/read-all';
  static String notificationRead(String id)   => '/api/notifications/$id/read';

  // ── Device Tokens ───────────────────────────────────────────────────────────

  static const String deviceTokens            = '/api/device-tokens';
  static const String deviceTokensAll         = '/api/device-tokens/all';

  // ── Chat ────────────────────────────────────────────────────────────────────

  static const String conversations           = '/api/chat/conversations';
  static const String conversationsUnread     = '/api/chat/conversations/unread-count';
  static String conversationMessages(String id) => '/api/chat/conversations/$id/messages';
  static String conversationRead(String id)     => '/api/chat/conversations/$id/read';
  static String sendMessage(String convId)      => '/api/chat/conversations/$convId/messages';
}