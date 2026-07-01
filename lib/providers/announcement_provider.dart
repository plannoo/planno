import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';

enum AnnouncementLoadState { initial, loading, loaded, error }

/// Feeds the Announcements panel on the dashboard.
/// Exposes items list, unreadCount badge, pagination, and mark-read.
class AnnouncementProvider extends ChangeNotifier {
  AnnouncementProvider({required AnnouncementRepository repository})
      : _repo = repository;

  final AnnouncementRepository _repo;

  AnnouncementLoadState   _state       = AnnouncementLoadState.initial;
  List<AnnouncementModel> _items       = [];
  int                     _unreadCount = 0;
  String?                 _nextCursor;
  String?                 _errorMessage;
  bool                    _hasMore     = true;

  AnnouncementLoadState   get state        => _state;
  List<AnnouncementModel> get items        => List.unmodifiable(_items);
  int                     get unreadCount  => _unreadCount;
  String?                 get errorMessage => _errorMessage;
  bool                    get isLoading    => _state == AnnouncementLoadState.loading;
  bool                    get hasMore      => _hasMore;

  Future<void> load({String? search, bool onlyUnread = false}) async {
    if (_state == AnnouncementLoadState.loading) return;
    _setState(AnnouncementLoadState.loading);
    _nextCursor = null;
    try {
      final result = await _repo.list(search: search, onlyUnread: onlyUnread, limit: 20);
      _items       = result.items;
      _unreadCount = result.unreadCount;
      _nextCursor  = result.nextCursor;
      _hasMore     = result.nextCursor != null;
      _setState(AnnouncementLoadState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AnnouncementLoadState.error);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoading) return;
    try {
      final result = await _repo.list(cursor: _nextCursor, limit: 20);
      _items       = [..._items, ...result.items];
      _nextCursor  = result.nextCursor;
      _hasMore     = result.nextCursor != null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    final idx = _items.indexWhere((a) => a.id == id);
    if (idx >= 0 && !_items[idx].isRead) {
      _items = [
        ..._items.sublist(0, idx),
        _items[idx].copyWith(isRead: true),
        ..._items.sublist(idx + 1),
      ];
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    _items = _items.map((a) => a.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _repo.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  void _setState(AnnouncementLoadState s) {
    _state = s;
    notifyListeners();
  }
}
