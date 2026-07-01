import 'api_client.dart';

/// Cursor-paginated, server-side-searched loader for `/api/users`.
///
/// Used by the member picker, the employees list, and new-chat — replacing the
/// old "load every user and filter client-side" approach so it scales past a
/// few hundred employees.
class UserSearchPager {
  UserSearchPager({this.pageSize = 30});
  final int pageSize;

  final List<Map<String, dynamic>> users = [];
  String? _cursor;
  String  _query = '';
  bool    _hasMore = true;
  bool    _loading = false;

  bool get hasMore => _hasMore;
  bool get isLoading => _loading;
  String get query => _query;

  /// Loads the next page. Pass [reset]=true (optionally with a new [query]) to
  /// start over from the first page.
  Future<void> load({bool reset = false, String? query}) async {
    if (_loading) return;
    if (reset) {
      _query   = query ?? _query;
      _cursor  = null;
      _hasMore = true;
      users.clear();
    }
    if (!_hasMore) return;
    _loading = true;
    try {
      final params = <String, String>{
        'limit': '$pageSize',
        if (_query.isNotEmpty) 'search': _query,
        if (_cursor != null)   'cursor': _cursor!,
      };
      final qs   = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final data = await ApiClient.instance.get('/api/users?$qs');
      final wrap = (data is Map<String, dynamic>) ? data : <String, dynamic>{};
      final raw  = (data is List ? data : wrap['data'] as List? ?? []);
      final page = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      users.addAll(page);
      _cursor  = wrap['nextCursor'] as String?;
      _hasMore = _cursor != null && page.isNotEmpty;
    } catch (_) {
      _hasMore = false;
    } finally {
      _loading = false;
    }
  }
}
