import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/work_location_model.dart';

// ── Response models ────────────────────────────────────────────────────────────

class TodayActivitiesSummary {
  final bool isClockedIn;
  final bool isOnBreak;

  const TodayActivitiesSummary({
    required this.isClockedIn,
    required this.isOnBreak,
  });

  factory TodayActivitiesSummary.fromJson(Map<String, dynamic> json) =>
      TodayActivitiesSummary(
        isClockedIn: json['is_clocked_in'] == true,
        isOnBreak:   json['is_on_break'] == true,
      );
}

class TodayActivityEntry {
  final DateTime timestamp;
  final String type; // e.g. 'clock_in', 'clock_out', 'break_start', 'break_end'

  const TodayActivityEntry({required this.timestamp, required this.type});

  factory TodayActivityEntry.fromJson(Map<String, dynamic> json) =>
      TodayActivityEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        type:      json['type'] as String,
      );
}

class TodayActivities {
  final TodayActivitiesSummary summary;
  final List<TodayActivityEntry> data;

  const TodayActivities({required this.summary, required this.data});

  factory TodayActivities.fromJson(Map<String, dynamic> json) =>
      TodayActivities(
        summary: TodayActivitiesSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
        data: (json['data'] as List<dynamic>)
            .map((e) =>
                TodayActivityEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Repository interface ───────────────────────────────────────────────────────

abstract interface class ClockRepository {
  /// Server is authoritative for the geofence check — only raw GPS is sent,
  /// no client-computed distance. [locationId] should be the workplace the
  /// client already validated the GPS fix against (see ClockProvider.workplace);
  /// without it the server re-resolves "closest assigned location" from
  /// scratch and can pick a different location than the one the client showed.
  Future<void> clockIn({
    required double? latitude,
    required double? longitude,
    required double? accuracy,
    String? shiftId,
    String? locationId,
  });

  Future<void> clockOut({
    required double? latitude,
    required double? longitude,
    required double? accuracy,
  });

  Future<void> startBreak();
  Future<void> endBreak();

  Future<void> requestOverride({
    required double? latitude,
    required double? longitude,
    String? reason,
  });

  Future<WorkLocationModel> getWorkLocation();
  Future<TodayActivities> getTodayActivities();
  Future<Map<String, dynamic>> getCurrentSession();

  /// Clock in/out via a QR code scanned from a terminal kiosk.
  /// [terminalToken] comes from the QR deep-link `?token=` param.
  Future<Map<String, dynamic>> clockViaQr({
    required String terminalToken,
    required String action, // 'in' | 'out'
  });
}

class ApiClockRepository implements ClockRepository {
  ApiClockRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<void> clockIn({
    required double? latitude,
    required double? longitude,
    required double? accuracy,
    String? shiftId,
    String? locationId,
  }) async {
    await _client.post(ApiConfig.clockIn, data: {
      if (latitude   != null) 'latitude':   latitude,
      if (longitude  != null) 'longitude':  longitude,
      if (accuracy   != null) 'accuracy':   accuracy,
      if (shiftId    != null) 'shift_id':   shiftId,
      if (locationId != null) 'locationId': locationId,
    });
  }

  @override
  Future<void> clockOut({
    required double? latitude,
    required double? longitude,
    required double? accuracy,
  }) async {
    await _client.post(ApiConfig.clockOut, data: {
      if (latitude  != null) 'latitude':  latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy  != null) 'accuracy':  accuracy,
    });
  }

  @override
  Future<void> startBreak() async {
    await _client.post(ApiConfig.breakStart);
  }

  @override
  Future<void> endBreak() async {
    await _client.post(ApiConfig.breakEnd);
  }

  @override
  Future<void> requestOverride({
    required double? latitude,
    required double? longitude,
    String? reason,
  }) async {
    await _client.post(ApiConfig.clockOverride, data: {
      if (latitude  != null) 'latitude':  latitude,
      if (longitude != null) 'longitude': longitude,
      if (reason    != null) 'reason':    reason,
    });
  }

  @override
  Future<WorkLocationModel> getWorkLocation() async {
    final response =
        await _client.get(ApiConfig.myWorkLocation) as Map<String, dynamic>;
    return WorkLocationModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  @override
  Future<TodayActivities> getTodayActivities() async {
    final response =
        await _client.get(ApiConfig.clockToday) as Map<String, dynamic>;
    return TodayActivities.fromJson(response);
  }

  @override
  Future<Map<String, dynamic>> getCurrentSession() async {
    final response =
        await _client.get(ApiConfig.clockSession) as Map<String, dynamic>;
    return response;
  }

  @override
  Future<Map<String, dynamic>> clockViaQr({
    required String terminalToken,
    required String action,
  }) async {
    final response = await _client.post(
      ApiConfig.terminalMobileClock,
      data: { 'terminalToken': terminalToken, 'action': action },
    ) as Map<String, dynamic>;
    return response;
  }
}

class MockClockRepository implements ClockRepository {
  @override Future<void> clockIn({required double? latitude,
    required double? longitude,
    required double? accuracy, String? shiftId, String? locationId}) async =>
      Future.delayed(const Duration(milliseconds: 300));

  @override Future<void> clockOut({required double? latitude,
    required double? longitude, required double? accuracy}) async =>
      Future.delayed(const Duration(milliseconds: 300));

  @override Future<void> startBreak() async =>
      Future.delayed(const Duration(milliseconds: 200));

  @override Future<void> endBreak() async =>
      Future.delayed(const Duration(milliseconds: 200));

  @override Future<void> requestOverride({required double? latitude,
    required double? longitude, String? reason}) async =>
      Future.delayed(const Duration(milliseconds: 200));

  @override
  Future<WorkLocationModel> getWorkLocation() async =>
      Future.delayed(const Duration(milliseconds: 200), () => const WorkLocationModel(
        id: 'mock-1',
        name: 'Main Office, Berlin',
        address: 'Friedrichstraße 123, 10117 Berlin',
        latitude: 52.5200,
        longitude: 13.4050,
      ));

  @override
  Future<TodayActivities> getTodayActivities() async =>
      Future.delayed(const Duration(milliseconds: 200), () => TodayActivities(
        summary: const TodayActivitiesSummary(
            isClockedIn: false, isOnBreak: false),
        data: [],
      ));

  @override
  Future<Map<String, dynamic>> getCurrentSession() async =>
      Future.delayed(const Duration(milliseconds: 100), () => const {});

  @override
  Future<Map<String, dynamic>> clockViaQr({
    required String terminalToken,
    required String action,
  }) async =>
      Future.delayed(const Duration(milliseconds: 300), () => const {'success': true, 'status': 'Clocked In'});
}