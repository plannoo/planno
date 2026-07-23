import 'package:flutter_test/flutter_test.dart';
import 'package:wrenta/models/absence_summary.dart';

void main() {
  group('AbsenceSummaryModel computed properties', () {
    test('remainingDays is total minus used', () {
      final model = AbsenceSummaryModel(
        usedDays: 8,
        totalDays: 25,
        validUntil: DateTime(2026, 12, 31),
      );
      expect(model.remainingDays, 17);
    });

    test('usagePercentage is fraction of total', () {
      final model = AbsenceSummaryModel(
        usedDays: 5,
        totalDays: 20,
        validUntil: DateTime(2026, 12, 31),
      );
      expect(model.usagePercentage, closeTo(0.25, 0.001));
    });

    test('usagePercentage is 0 when totalDays is 0', () {
      final model = AbsenceSummaryModel(
        usedDays: 0,
        totalDays: 0,
        validUntil: DateTime(2026, 12, 31),
      );
      expect(model.usagePercentage, 0.0);
    });

    test('remainingDays can be negative when overbooked', () {
      final model = AbsenceSummaryModel(
        usedDays: 30,
        totalDays: 25,
        validUntil: DateTime(2026, 12, 31),
      );
      expect(model.remainingDays, -5);
    });

    test('usagePercentage exceeds 1 when overbooked', () {
      final model = AbsenceSummaryModel(
        usedDays: 30,
        totalDays: 25,
        validUntil: DateTime(2026, 12, 31),
      );
      expect(model.usagePercentage, greaterThan(1.0));
    });
  });
}
