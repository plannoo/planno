import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/api_exceptions.dart';
import '../models/announcement_model.dart';

abstract interface class AnnouncementRepository {
  Future<AnnouncementListResult> list({
    String?  cursor,
    int      limit,
    String?  search,
    bool     onlyUnread,
  });
  Future<int>  getUnreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class ApiAnnouncementRepository implements AnnouncementRepository {
  ApiAnnouncementRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<AnnouncementListResult> list({
    String?  cursor,
    int      limit    = 20,
    String?  search,
    bool     onlyUnread = false,
  }) async {
    try {
      final data = await _client.get(
        ApiConfig.announcements,
        queryParameters: {
          'limit': limit,
          if (cursor     != null) 'cursor':     cursor,
          if (search     != null) 'search':     search,
          if (onlyUnread)         'onlyUnread': 'true',
        },
      ) as Map<String, dynamic>;

      final items = (data['data'] as List<dynamic>)
          .map((j) => AnnouncementModel.fromJson(j as Map<String, dynamic>))
          .toList();

      return AnnouncementListResult(
        items:        items,
        nextCursor:   data['nextCursor'] as String?,
        unreadCount:  (data['unreadCount'] as num).toInt(),
      );
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse announcements: $e'); }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final data = await _client.get(ApiConfig.announcementUnread)
          as Map<String, dynamic>;
      return (data['unreadCount'] as num).toInt();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse unread count: $e'); }
  }

  @override
  Future<void> markRead(String id) async {
    await _client.post(ApiConfig.markAnnouncementRead(id));
  }

  @override
  Future<void> markAllRead() async {
    await _client.post(ApiConfig.announcementReadAll);
  }
}

class MockAnnouncementRepository implements AnnouncementRepository {
  @override
  Future<AnnouncementListResult> list({
    String? cursor, int limit = 20,
    String? search, bool onlyUnread = false,
  }) async =>
      AnnouncementListResult(
        items: [
          AnnouncementModel(
            id: 'ann1',
            title: 'Schichtpläne ab 01.März 2026',
            message: 'Neue Schichtpläne sind jetzt verfügbar.',
            createdAt: '08. April',
            author: 'Ralf Bertelt',
            isRead: false,
          ),
        ],
        unreadCount: 1,
        nextCursor:  null,
      );

  @override Future<int>  getUnreadCount() async => 1;
  @override Future<void> markRead(String id) async {}
  @override Future<void> markAllRead() async {}
}
