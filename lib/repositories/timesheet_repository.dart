import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/api_exceptions.dart';

abstract interface class TimesheetRepository {
  Future<Map<String, dynamic>> getWeekly({DateTime? date});
  Future<Map<String, dynamic>> getMonthly({required int year, required int month});
}

class ApiTimesheetRepository implements TimesheetRepository {
  ApiTimesheetRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> getWeekly({DateTime? date}) async {
    try {
      final data = await _client.get(
        ApiConfig.timesheetWeek,
        queryParameters: {
          if (date != null) 'date': date.toIso8601String().split('T').first,
        },
      ) as Map<String, dynamic>;
      return data;
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse weekly timesheet: $e'); }
  }

  @override
  Future<Map<String, dynamic>> getMonthly({required int year, required int month}) async {
    try {
      final data = await _client.get(
        ApiConfig.timesheetMonth,
        queryParameters: {'year': year, 'month': month},
      ) as Map<String, dynamic>;
      return data;
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse monthly timesheet: $e'); }
  }
}

class MockTimesheetRepository implements TimesheetRepository {
  @override
  Future<Map<String, dynamic>> getWeekly({DateTime? date}) async => {};

  @override
  Future<Map<String, dynamic>> getMonthly({required int year, required int month}) async => {};
}
