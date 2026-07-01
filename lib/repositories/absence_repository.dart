import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/api_exceptions.dart';
import '../models/absence.dart';
import '../models/absence_summary.dart';

abstract interface class AbsenceRepository {
  Future<AbsenceSummaryModel> getSummary();
  Future<List<AbsenceModel>>  getUpcoming();
  Future<List<AbsenceModel>>  getPast();
  Future<void>                submitAbsence(AbsenceModel absence);
  Future<List<Map<String, dynamic>>> getSchoolHolidays(int year, String state);
}

class ApiAbsenceRepository implements AbsenceRepository {
  ApiAbsenceRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<AbsenceSummaryModel> getSummary() async {
    try {
      final year = DateTime.now().year;
      final response = await _client.get(
        ApiConfig.absenceEntitlement,
        queryParameters: {'absenceType': 'VACATION', 'year': year},
      ) as Map<String, dynamic>;

      final row = response['data'] as Map<String, dynamic>?;
      if (row == null) {
        return AbsenceSummaryModel(
          usedDays: 0, totalDays: 0, validUntil: DateTime(year, 12, 31));
      }
      return AbsenceSummaryModel(
        usedDays:  ((row['accepted'] ?? row['acceptedDays']) as num? ?? 0).toInt(),
        totalDays: ((row['entitlementDays'] as num? ?? 0) +
                    (row['correctionDays']  as num? ?? 0)).toInt(),
        validUntil: DateTime(year, 12, 31),
      );
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse absence summary: $e'); }
  }

  @override
  Future<List<AbsenceModel>> getUpcoming() async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final response = await _client.get(
        ApiConfig.absenceSubmit,   // GET /api/absences
        queryParameters: { 'from': today, 'status': 'PENDING', 'limit': 50 },
      ) as Map<String, dynamic>;
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((j) => AbsenceModel.fromJson(j as Map<String, dynamic>)).toList();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse upcoming absences: $e'); }
  }

  @override
  Future<List<AbsenceModel>> getPast() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1))
          .toIso8601String().split('T').first;
      final response = await _client.get(
        ApiConfig.absenceSubmit,   // GET /api/absences
        queryParameters: { 'to': yesterday, 'limit': 50 },
      ) as Map<String, dynamic>;
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((j) => AbsenceModel.fromJson(j as Map<String, dynamic>)).toList();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse past absences: $e'); }
  }

  @override
  Future<void> submitAbsence(AbsenceModel absence) async {
    await _client.post(ApiConfig.absenceSubmit, data: {
      'type':      absence.apiType,
      'startDate': absence.startDate.toIso8601String().split('T').first,
      'endDate':   absence.endDate.toIso8601String().split('T').first,
      if (absence.reason != null) 'reason': absence.reason,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getSchoolHolidays(int year, String state) async {
    try {
      final res = await _client.get(
        ApiConfig.schoolHolidays,
        queryParameters: {'year': year, 'state': state},
      );
      // API wraps the list in { data: [...] }; tolerate a bare list too.
      final list = res is Map<String, dynamic>
          ? (res['data'] as List<dynamic>? ?? [])
          : (res as List<dynamic>? ?? []);
      return list.cast<Map<String, dynamic>>();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse school holidays: $e'); }
  }
}

class MockAbsenceRepository implements AbsenceRepository {
  @override
  Future<AbsenceSummaryModel> getSummary() async => AbsenceSummaryModel(
        usedDays: 12, totalDays: 24, validUntil: DateTime(2026, 12, 31));

  @override
  Future<List<AbsenceModel>> getUpcoming() async => [
        AbsenceModel(id: '1', type: AbsenceType.vacation,
            startDate: DateTime(2026, 7, 12), endDate: DateTime(2026, 7, 19),
            workingDays: 6, status: AbsenceStatus.approved),
        AbsenceModel(id: '2', type: AbsenceType.training,
            startDate: DateTime(2026, 8, 5),  endDate: DateTime(2026, 8, 5),
            workingDays: 1, status: AbsenceStatus.pending),
      ];

  @override
  Future<List<AbsenceModel>> getPast() async => [
        AbsenceModel(id: '3', type: AbsenceType.sickLeave,
            startDate: DateTime(2026, 6, 1), endDate: DateTime(2026, 6, 3),
            workingDays: 3, status: AbsenceStatus.approved),
      ];

  @override
  Future<void> submitAbsence(AbsenceModel absence) async =>
      Future.delayed(const Duration(milliseconds: 500));

  @override
  Future<List<Map<String, dynamic>>> getSchoolHolidays(int year, String state) async =>
      [];
}
