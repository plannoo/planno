import 'package:flutter_test/flutter_test.dart';
import 'package:wrenta/models/absence.dart';

/// Guards the absence-type mapping that the backend `createAbsenceSchema`
/// accepts: ['VACATION', 'SICK_LEAVE', 'TRAINING', 'PERSONAL_DAY', 'UNEXCUSED'].
/// A regression here causes "validation failed" on absence submit.
void main() {
  const allowed = {
    'VACATION', 'SICK_LEAVE', 'TRAINING', 'PERSONAL_DAY', 'UNEXCUSED',
  };

  group('AbsenceModel.apiTypeFor', () {
    test('every app type maps to a backend-accepted value', () {
      for (final type in AbsenceType.values) {
        final api = AbsenceModel.apiTypeFor(type);
        expect(allowed.contains(api), isTrue,
            reason: '$type → $api is not an accepted backend enum');
      }
    });

    test('exact mappings for the primary types', () {
      expect(AbsenceModel.apiTypeFor(AbsenceType.vacation),    'VACATION');
      expect(AbsenceModel.apiTypeFor(AbsenceType.training),    'TRAINING');
      expect(AbsenceModel.apiTypeFor(AbsenceType.sickLeave),   'SICK_LEAVE');
      expect(AbsenceModel.apiTypeFor(AbsenceType.personalDay), 'PERSONAL_DAY');
    });

    test('granular extras fall back to nearest accepted value', () {
      expect(AbsenceModel.apiTypeFor(AbsenceType.unpaid),  'UNEXCUSED');
      expect(AbsenceModel.apiTypeFor(AbsenceType.standby), 'PERSONAL_DAY');
    });

    test('instance apiType getter matches the static mapper', () {
      final absence = AbsenceModel(
        id: 'x',
        type: AbsenceType.sickLeave,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 2),
        workingDays: 2,
        status: AbsenceStatus.pending,
      );
      expect(absence.apiType, 'SICK_LEAVE');
    });

    test('never produces the invalid SICKLEAVE/PERSONALDAY forms', () {
      final produced =
          AbsenceType.values.map(AbsenceModel.apiTypeFor).toSet();
      expect(produced.contains('SICKLEAVE'), isFalse);
      expect(produced.contains('PERSONALDAY'), isFalse);
      expect(produced.contains('STANDBY'), isFalse);
      expect(produced.contains('UNPAID'), isFalse);
    });
  });
}
