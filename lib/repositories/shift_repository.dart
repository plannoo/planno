import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/api_exceptions.dart';
import '../models/shift_model.dart';

abstract interface class ShiftRepository {
  Future<List<ShiftModel>> getShiftsForWeek(DateTime weekStart);
  Future<ShiftModel?>      getTodayShift();
}

class ApiShiftRepository implements ShiftRepository {
  ApiShiftRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  String _fmt(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<List<ShiftModel>> getShiftsForWeek(DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final response = await _client.get(
        ApiConfig.shifts,
        queryParameters: { 'from': _fmt(weekStart), 'to': _fmt(weekEnd) },
      ) as Map<String, dynamic>;
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((j) => ShiftModel.fromJson(j as Map<String, dynamic>)).toList();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse shifts: $e'); }
  }

  @override
  Future<ShiftModel?> getTodayShift() async {
    try {
      // First try the dedicated /today endpoint.
      try {
        final response = await _client.get(
          '${ApiConfig.shifts}/today',
        ) as Map<String, dynamic>;
        final shift = response['data'];
        if (shift != null) {
          return ShiftModel.fromJson(shift as Map<String, dynamic>);
        }
      } on ApiException {
        // Fall through to the general shifts query below.
      }

      // Fallback: the /today endpoint may return null even when a shift exists
      // (e.g. unpublished shifts, timezone boundary, or different server logic).
      // The schedule's "My Schedule" tab uses the same general endpoint successfully.
      final today = DateTime.now();
      final fallback = await _client.get(
        ApiConfig.shifts,
        queryParameters: {
          'from': _fmt(today),
          'to': _fmt(today),
          'limit': '100',
        },
      ) as Map<String, dynamic>;
      final data = fallback['data'] as List<dynamic>? ?? [];
      // startTime comes from the API in UTC — convert to local before comparing
      // so that midnight-adjacent shifts aren't excluded by timezone offsets.
      for (final j in data) {
        final s = ShiftModel.fromJson(j as Map<String, dynamic>);
        final localStart = s.startTime.toLocal();
        if (localStart.year == today.year &&
            localStart.month == today.month &&
            localStart.day == today.day) {
          return s;
        }
      }
      return null;
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse today shift: $e'); }
  }

}

class MockShiftRepository implements ShiftRepository {
  @override
  Future<ShiftModel?> getTodayShift() async {
    final now = DateTime.now();
    return ShiftModel(
      id: 'shift-today', role: 'Floor Manager', date: now,
      startTime: DateTime(now.year, now.month, now.day, 9, 0),
      endTime:   DateTime(now.year, now.month, now.day, 17, 0),
      location: 'Main Office, Berlin',
      address:  'Friedrichstraße 123, 10117 Berlin',
      latitude: 52.5200, longitude: 13.4050,
    );
  }

  @override
  Future<List<ShiftModel>> getShiftsForWeek(DateTime weekStart) async => [];

}
