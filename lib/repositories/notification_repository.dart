import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/notification_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Abstract interface
// ─────────────────────────────────────────────────────────────────────────────
abstract class NotificationRepository {
  /// Fetches a page of notifications.
  /// Pass [cursor] for the next page (cursor = last item's id).
  Future<NotificationPage> list({
    bool unreadOnly = false,
    int limit = 20,
    String? cursor,
  });

  /// Returns the authoritative unread count from the server.
  Future<int> getUnreadCount();

  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class NotificationPage {
  final List<NotificationModel> items;
  final String? nextCursor; // null = no more pages

  const NotificationPage({required this.items, this.nextCursor});
}

// ─────────────────────────────────────────────────────────────────────────────
// No-op implementation (used when the user is logged out)
// ─────────────────────────────────────────────────────────────────────────────
class NoOpNotificationRepo implements NotificationRepository {
  const NoOpNotificationRepo();

  @override
  Future<NotificationPage> list({
    bool unreadOnly = false,
    int limit = 20,
    String? cursor,
  }) async =>
      const NotificationPage(items: []);

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// HTTP implementation
// ─────────────────────────────────────────────────────────────────────────────
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({required ApiClient apiClient})
      : _api = apiClient;

  final ApiClient _api;

  @override
  Future<NotificationPage> list({
    bool unreadOnly = false,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _api.get(ApiConfig.notifications, queryParameters: {
      if (unreadOnly) 'unreadOnly': 'true',
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    });

    final data = response['data'] as List<dynamic>;
    return NotificationPage(
      items: data
          .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
          .toList(),
      nextCursor: response['nextCursor'] as String?,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _api.get(ApiConfig.notificationsUnread);
    return (response['data']['count'] as num).toInt();
  }

  @override
  Future<void> markAsRead(String id) async {
    await _api.patch(ApiConfig.notificationRead(id));
  }

  @override
  Future<void> markAllAsRead() async {
    await _api.patch(ApiConfig.notificationsReadAll);
  }
}
