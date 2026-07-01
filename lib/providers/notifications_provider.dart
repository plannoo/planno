import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

enum NotificationsLoadState { initial, loading, loaded, error }

/// Manages the in-app notification list and unread badge count.
///
/// Responsibilities:
/// - Loads notifications from the backend (with cursor pagination)
/// - Listens to FCM foreground messages and prepends them in real-time
/// - Keeps [unreadCount] in sync with the server
/// - Exposes markRead / markAllRead that persist to the backend
///
/// Wire up:
/// ```dart
/// ChangeNotifierProvider(
///   create: (ctx) => NotificationsProvider(repo: ctx.read())..init(),
/// )
/// ```
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({required NotificationRepository repo}) : _repo = repo;

  final NotificationRepository _repo;

  // ── State ──────────────────────────────────────────────────────────────────
  List<NotificationModel> _items      = [];
  NotificationsLoadState  _state      = NotificationsLoadState.initial;
  String?                 _error;
  String?                 _nextCursor;        // null = no more pages
  bool                    _loadingMore = false;
  int                     _serverUnreadCount = 0;
  StreamSubscription<RemoteMessage>? _fcmSub;
  Timer?                  _pollTimer;

  List<NotificationModel> get items         => List.unmodifiable(_items);
  NotificationsLoadState  get state         => _state;
  bool                    get isLoading     => _state == NotificationsLoadState.loading;
  bool                    get isLoadingMore => _loadingMore;
  String?                 get error         => _error;
  bool                    get hasMore       => _nextCursor != null;

  // Prefer local computed count so UI reacts instantly on markRead,
  // but fall back to server count on first load before any items arrive.
  int  get unreadCount => _state == NotificationsLoadState.loaded
      ? _items.where((n) => !n.isRead).length
      : _serverUnreadCount;
  bool get hasUnread   => unreadCount > 0;

  // ── Init / dispose ─────────────────────────────────────────────────────────

  /// Call once after creation (e.g. in initState or provider create callback).
  Future<void> init() async {
    await Future.wait([
      load(),
      _syncUnreadCount(),
    ]);
    _subscribeFcm();
    _startPolling();
  }

  /// Poll the unread count periodically so the bell badge stays fresh even when
  /// push isn't configured/granted. Lightweight — count only, not the full list.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _syncUnreadCount());
  }

  /// Subscribes to FCM foreground messages and prepends them to the list.
  /// FCM background/terminated messages are handled by NotificationService
  /// and will appear on the next load() call.
  void _subscribeFcm() {
    _fcmSub?.cancel();
    _fcmSub = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      final model = NotificationModel.fromFcmData(
        title: notification.title ?? '',
        body:  notification.body  ?? '',
        data:  message.data,
      );

      _items.insert(0, model);
      _serverUnreadCount++;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _fcmSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Load (first page) ─────────────────────────────────────────────────────

  Future<void> load() async {
    if (_state == NotificationsLoadState.loading) return;

    _state      = NotificationsLoadState.loading;
    _error      = null;
    _nextCursor = null;
    notifyListeners();

    try {
      final page = await _repo.list(limit: 20);
      _items      = page.items;
      _nextCursor = page.nextCursor;
      _state      = NotificationsLoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = NotificationsLoadState.error;
    }
    notifyListeners();
  }

  // ── Load more (pagination) ────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (_loadingMore || _nextCursor == null) return;

    _loadingMore = true;
    notifyListeners();

    try {
      final page = await _repo.list(limit: 20, cursor: _nextCursor);
      _items      = [..._items, ...page.items];
      _nextCursor = page.nextCursor;
    } catch (e) {
      // Non-fatal: just stop paginating, don't replace the loaded list
      debugPrint('[Notifications] loadMore failed: $e');
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  // ── Unread count sync ─────────────────────────────────────────────────────

  Future<void> _syncUnreadCount() async {
    try {
      _serverUnreadCount = await _repo.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('[Notifications] getUnreadCount failed: $e');
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Optimistic: updates local state immediately, then persists to backend.
  /// Rolls back on failure.
  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1 || _items[idx].isRead) return;

    // Optimistic update
    _items[idx] = _items[idx].copyWith(isRead: true);
    notifyListeners();

    try {
      await _repo.markAsRead(id);
    } catch (e) {
      // Rollback
      _items[idx] = _items[idx].copyWith(isRead: false);
      notifyListeners();
      debugPrint('[Notifications] markRead failed: $e');
    }
  }

  /// Dismisses a notification (removes it from the local list).
  /// Optionally persists to backend.
  Future<void> dismiss(String id) async {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();

    try {
      await _repo.markAsRead(id);
    } catch (e) {
      debugPrint('[Notifications] dismiss failed: $e');
    }
  }

  /// Optimistic mark-all-read.
  Future<void> markAllRead() async {
    final previous = List<NotificationModel>.from(_items);

    // Optimistic
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _repo.markAllAsRead();
    } catch (e) {
      // Rollback
      _items = previous;
      notifyListeners();
      debugPrint('[Notifications] markAllRead failed: $e');
    }
  }
}
