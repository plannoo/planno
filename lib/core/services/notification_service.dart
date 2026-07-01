import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../../repositories/device_token_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background handler — MUST be a top-level function, NOT a class method.
// @pragma is required so the release-mode tree-shaker keeps it.
// This runs in a separate Dart isolate on Android; do NOT use Provider/GetIt here.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    // Firebase must be re-initialised in the background isolate.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[FCM] Background message: ${message.messageId}');
  } catch (e) {
    debugPrint('[FCM] Background handler init failed: $e');
  }
  // Heavy work (DB writes etc.) should go to your backend, not here.
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification channel constants (Android only)
// ─────────────────────────────────────────────────────────────────────────────

/// High-importance channel for shift / absence alerts — shows as heads-up.
const _kShiftChannelId   = 'planno_shifts';
const _kShiftChannelName = 'Shift Notifications';

/// Default channel for general announcements, tasks, etc.
const _kGeneralChannelId   = 'planno_general';
const _kGeneralChannelName = 'General Notifications';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

/// Singleton that owns all push-notification setup and routing.
///
/// Usage:
/// ```dart
/// await NotificationService.instance.init(tokenRepo: myRepo);
/// ```
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  /// Kept so we can (re)register the FCM token after the user authenticates —
  /// `init()` runs at app startup before any auth token exists, so the first
  /// registration attempt is unauthenticated and silently fails.
  DeviceTokenRepository? _tokenRepo;

  /// Whether the current platform supports Firebase push notifications.
  static bool get _isSupported {
    if (kIsWeb) return true;
    // Windows and Linux do not have Firebase native plugins.
    return !Platform.isWindows && !Platform.isLinux;
  }

  // Expose for deep-link routing in the app shell.
  Stream<RemoteMessage> get onForegroundMessage {
    if (_messaging == null) return const Stream.empty();
    return FirebaseMessaging.onMessage;
  }

  /// Call once from main(), after Firebase.initializeApp().
  ///
  /// On unsupported platforms (Windows, Linux) or when Firebase is not
  /// configured, this is a no-op.
  Future<void> init({required DeviceTokenRepository tokenRepo}) async {
    _tokenRepo = tokenRepo;
    if (!_isSupported || Firebase.apps.isEmpty) {
      if (Firebase.apps.isEmpty) {
        debugPrint('[FCM] Firebase not initialised — skipping notification setup');
      }
      return;
    }

    // 1. Register background handler (must happen before runApp)
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    _messaging = FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();

    // 2. Request permission (iOS / Android 13+)
    await _requestPermission();

    // 3. Set up local notifications (foreground display + Android channels)
    await _initLocalNotifications();

    // 4. Register FCM token with our backend
    await _registerToken(tokenRepo);

    // 5. Listen for token refreshes (tokens can rotate at any time)
    _messaging!.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed');
      await _sendTokenToBackend(tokenRepo, newToken);
    });

    // 6. Wire up foreground message display
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Handle tap when app was in background (brought to foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 8. Handle tap when app was fully terminated
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // ── Permission ──────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await _messaging!.requestPermission(
      alert:        true,
      badge:        true,
      sound:        true,
      provisional:  false, // true = silent delivery on iOS until user interacts
    );

    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // On iOS, FCM needs to present notifications while app is in foreground too.
    if (!kIsWeb && Platform.isIOS) {
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // ── Local notifications setup ───────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    // Android: use app icon as small icon (put ic_notification in drawable)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS: flutter_local_notifications handles foreground display
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FirebaseMessaging
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications!.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS:     iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channels.
    // Without a high-importance channel, heads-up banners won't show.
    if (!kIsWeb && Platform.isAndroid) {
      await _createAndroidChannels();
    }
  }

  Future<void> _createAndroidChannels() async {
    final plugin = _localNotifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kShiftChannelId,
        _kShiftChannelName,
        description: 'Shift assignments, updates, and cancellations',
        importance:  Importance.max, // required for heads-up banners
        playSound:   true,
      ),
    );

    await plugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kGeneralChannelId,
        _kGeneralChannelName,
        description: 'Announcements, tasks, and absence decisions',
        importance:  Importance.high,
        playSound:   true,
      ),
    );
  }

  // ── Token management ────────────────────────────────────────────────────────

  Future<void> _registerToken(DeviceTokenRepository tokenRepo) async {
    // Web requires a VAPID key from Firebase Console → Project Settings →
    // Cloud Messaging → Web Push certificates.
    final token = kIsWeb
        ? await _messaging!.getToken(
            vapidKey: const String.fromEnvironment('FCM_VAPID_KEY'),
          )
        : await _messaging!.getToken();

    if (token == null) {
      debugPrint('[FCM] Token is null — notification permission likely denied');
      return;
    }

    debugPrint('[FCM] Token: ${token.substring(0, 20)}…');
    await _sendTokenToBackend(tokenRepo, token);
  }

  Future<void> _sendTokenToBackend(
    DeviceTokenRepository tokenRepo,
    String token,
  ) async {
    try {
      final platform = kIsWeb
          ? 'WEB'
          : Platform.isIOS
              ? 'IOS'
              : 'ANDROID';

      await tokenRepo.registerToken(token: token, platform: platform);
    } catch (e) {
      // Non-fatal — the app still works, user just won't get push
      debugPrint('[FCM] Failed to register token with backend: $e');
    }
  }

  // ── Message handlers ────────────────────────────────────────────────────────

  /// FCM does NOT show a banner when the app is in the foreground.
  /// We display one manually via flutter_local_notifications.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return; // data-only message — app handles it

    // Pick channel based on notification type sent from our backend
    final isShiftNotification = [
      'SHIFT_ASSIGNED',
      'SHIFT_UPDATED',
      'SHIFT_CANCELLED',
    ].contains(message.data['type']);

    final channelId   = isShiftNotification ? _kShiftChannelId   : _kGeneralChannelId;
    final channelName = isShiftNotification ? _kShiftChannelName : _kGeneralChannelName;

    await _localNotifications!.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance:    isShiftNotification ? Importance.max : Importance.high,
          priority:      Priority.high,
          icon:          '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _encodePayload(message.data),
    );
  }

  /// Called when user taps a notification that brought the app from background.
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    _routeFromData(message.data);
  }

  /// Called when user taps a locally-shown foreground notification.
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    final data = _decodePayload(response.payload!);
    _routeFromData(data);
  }

  // ── Navigation routing ──────────────────────────────────────────────────────

  /// Routes to the correct screen based on the notification data payload.
  /// Uses a simple type-based switch matching our backend's NotificationType enum.
  ///
  /// The [navigatorKey] must be set on your MaterialApp:
  ///   `navigatorKey: NotificationService.navigatorKey`
  static final navigatorKey = GlobalKey<NavigatorState>();

  void _routeFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return;

    // Delay one frame to ensure the navigator is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      switch (type) {
        case 'SHIFT_ASSIGNED':
        case 'SHIFT_UPDATED':
        case 'SHIFT_CANCELLED':
          navigator.pushNamed('/shifts');
        case 'ABSENCE_APPROVED':
        case 'ABSENCE_REJECTED':
          navigator.pushNamed('/absences');
        case 'ANNOUNCEMENT':
          final id = data['announcementId'] as String?;
          navigator.pushNamed('/announcements', arguments: id);
        case 'CHAT_MESSAGE':
          final convId = data['conversationId'] as String?;
          navigator.pushNamed('/chat', arguments: convId);
        case 'TASK_ASSIGNED':
          navigator.pushNamed('/tasks');
        default:
          navigator.pushNamed('/notifications');
      }
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _encodePayload(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}=${e.value}').join('&');

  Map<String, dynamic> _decodePayload(String payload) => Map.fromEntries(
        payload.split('&').map((e) {
          final parts = e.split('=');
          return MapEntry(parts[0], parts.length > 1 ? parts[1] : '');
        }),
      );

  // ── Session hooks ─────────────────────────────────────────────────────────────

  /// Call right after the user authenticates. The FCM token obtained during
  /// `init()` (at app startup) could not be registered because no auth token
  /// existed yet — this registers it now that the request will be authorized.
  Future<void> onLogin() async {
    if (_messaging == null || _tokenRepo == null) return;
    await _registerToken(_tokenRepo!);
  }

  // ── Cleanup ──────────────────────────────────────────────────────────────────

  /// Call on logout to deregister the token from the backend.
  Future<void> onLogout(DeviceTokenRepository tokenRepo) async {
    if (_messaging == null) return;
    try {
      final token = await _messaging!.getToken();
      if (token != null) {
        await tokenRepo.removeToken(token: token);
      }
    } catch (e) {
      debugPrint('[FCM] Failed to deregister token on logout: $e');
    }
  }
}
