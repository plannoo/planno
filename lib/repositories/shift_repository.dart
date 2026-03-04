
import '../models/shift_model.dart';

/// Abstract contract for shift data operations.
/// Swap implementations (mock / remote) without touching UI code.
abstract interface class ShiftRepository {
  Future<List<ShiftModel>> getShiftsForWeek(DateTime weekStart);
  Future<ShiftModel?> getTodayShift();
  Future<List<ShiftModel>> getTeamShifts(DateTime weekStart);
}

/// In-memory mock implementation used during development / testing.
class MockShiftRepository implements ShiftRepository {
  @override
  Future<ShiftModel?> getTodayShift() async {
    final now = DateTime.now();
    return ShiftModel(
      id: 'shift-today',
      role: 'Floor Manager',
      date: now,
      startTime: DateTime(now.year, now.month, now.day, 9, 0),
      endTime: DateTime(now.year, now.month, now.day, 17, 0),
      location: 'Main Office, Berlin',
      address: 'Friedrichstraße 123, 10117 Berlin',
      latitude: 52.5200,
      longitude: 13.4050,
    );
  }

  @override
  Future<List<ShiftModel>> getShiftsForWeek(DateTime weekStart) async {
    // Return sample data – replace with real API call
    return [];
  }

  @override
  Future<List<ShiftModel>> getTeamShifts(DateTime weekStart) async {
    return [];
  }
}