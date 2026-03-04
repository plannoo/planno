
/// Abstract contract for clock-in / clock-out persistence.
abstract interface class ClockRepository {
  /// Record a clock-in event.
  Future<void> clockIn({
    required double? latitude,
    required double? longitude,
    required double distanceFromWorkplace,
    required double? accuracy,
  });

  /// Record a clock-out event.
  Future<void> clockOut({
    required double? latitude,
    required double? longitude,
    required double? accuracy,
  });
}

class MockClockRepository implements ClockRepository {
  @override
  Future<void> clockIn({
    required double? latitude,
    required double? longitude,
    required double distanceFromWorkplace,
    required double? accuracy,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> clockOut({
    required double? latitude,
    required double? longitude,
    required double? accuracy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}