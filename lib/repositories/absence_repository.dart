import '../models/absence.dart';
import '../models/absence_summary.dart';

abstract interface class AbsenceRepository {
  Future<AbsenceSummaryModel> getSummary();
  Future<List<AbsenceModel>> getUpcoming();
  Future<List<AbsenceModel>> getPast();
  Future<void> submitAbsence(AbsenceModel absence);
}

class MockAbsenceRepository implements AbsenceRepository {
  @override
  Future<AbsenceSummaryModel> getSummary() async => AbsenceSummaryModel(
        usedDays: 12,
        totalDays: 24,
        validUntil: DateTime(2024, 12, 31),
      );

  @override
  Future<List<AbsenceModel>> getUpcoming() async => [
        AbsenceModel(
          id: '1',
          type: AbsenceType.vacation,
          startDate: DateTime(2024, 7, 12),
          endDate: DateTime(2024, 7, 19),
          workingDays: 6,
          status: AbsenceStatus.approved,
        ),
        AbsenceModel(
          id: '2',
          type: AbsenceType.training,
          startDate: DateTime(2024, 8, 5),
          endDate: DateTime(2024, 8, 5),
          workingDays: 1,
          status: AbsenceStatus.pending,
        ),
      ];

  @override
  Future<List<AbsenceModel>> getPast() async => [
        AbsenceModel(
          id: '3',
          type: AbsenceType.sickLeave,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 3),
          workingDays: 3,
          status: AbsenceStatus.approved,
        ),
        AbsenceModel(
          id: '4',
          type: AbsenceType.personalDay,
          startDate: DateTime(2024, 5, 15),
          endDate: DateTime(2024, 5, 15),
          workingDays: 1,
          status: AbsenceStatus.rejected,
        ),
      ];

  @override
  Future<void> submitAbsence(AbsenceModel absence) async {
    // TODO: call API
    await Future.delayed(const Duration(milliseconds: 500));
  }
}