import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/api_exceptions.dart';

abstract interface class AvailabilityRepository {
  Future<List<Map<String, dynamic>>> getMyAvailabilities({DateTime? date});
  Future<bool> checkOverlap({
    required String userId,
    required DateTime from,
    required DateTime to,
  });
}

class ApiAvailabilityRepository implements AvailabilityRepository {
  ApiAvailabilityRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> getMyAvailabilities({DateTime? date}) async {
    try {
      final data = await _client.get(
        ApiConfig.availabilitiesMe,
        queryParameters: {
          if (date != null) 'date': date.toIso8601String().split('T').first,
        },
      ) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse availabilities: $e'); }
  }

  @override
  Future<bool> checkOverlap({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final data = await _client.get(
        ApiConfig.availabilitiesCheck,
        queryParameters: {
          'userId': userId,
          'from':   from.toIso8601String(),
          'to':     to.toIso8601String(),
        },
      ) as Map<String, dynamic>;
      return (data['hasOverlap'] as bool?) ?? false;
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to check availability overlap: $e'); }
  }
}

class MockAvailabilityRepository implements AvailabilityRepository {
  @override
  Future<List<Map<String, dynamic>>> getMyAvailabilities({DateTime? date}) async => [];

  @override
  Future<bool> checkOverlap({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async => false;
}
