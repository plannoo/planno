import 'package:flutter_test/flutter_test.dart';
import 'package:aplano/models/absence.dart';

void main() {
  group('AbsenceModel.fromJson', () {
    test('parses camelCase date fields', () {
      final json = {
        'id': 'abs-1',
        'type': 'VACATION',
        'status': 'APPROVED',
        'startDate': '2026-07-01',
        'endDate': '2026-07-07',
        'workingDays': 5,
      };
      final absence = AbsenceModel.fromJson(json);
      expect(absence.id, 'abs-1');
      expect(absence.type, AbsenceType.vacation);
      expect(absence.status, AbsenceStatus.approved);
      expect(absence.startDate, DateTime(2026, 7, 1));
      expect(absence.endDate, DateTime(2026, 7, 7));
      expect(absence.workingDays, 5);
    });

    test('parses snake_case date fields as fallback', () {
      final json = {
        'id': 'abs-2',
        'type': 'SICK_LEAVE',
        'status': 'PENDING',
        'start_date': '2026-06-10',
        'end_date': '2026-06-12',
        'working_days': 3,
      };
      final absence = AbsenceModel.fromJson(json);
      expect(absence.type, AbsenceType.sickLeave);
      expect(absence.status, AbsenceStatus.pending);
      expect(absence.startDate, DateTime(2026, 6, 10));
    });

    test('maps all absence types correctly', () {
      final cases = {
        'VACATION':     AbsenceType.vacation,
        'TRAINING':     AbsenceType.training,
        'SICK_LEAVE':   AbsenceType.sickLeave,
        'PERSONAL_DAY': AbsenceType.personalDay,
        'UNPAID':       AbsenceType.unpaid,
        'STANDBY':      AbsenceType.standby,
      };
      for (final entry in cases.entries) {
        final json = {
          'id': 'x', 'type': entry.key, 'status': 'PENDING',
          'startDate': '2026-01-01', 'endDate': '2026-01-01', 'workingDays': 1,
        };
        expect(AbsenceModel.fromJson(json).type, entry.value,
            reason: '${entry.key} should map to ${entry.value}');
      }
    });

    test('maps status: approved, rejected, pending', () {
      for (final pair in [
        ('APPROVED', AbsenceStatus.approved),
        ('REJECTED', AbsenceStatus.rejected),
        ('PENDING',  AbsenceStatus.pending),
        ('unknown',  AbsenceStatus.pending),
      ]) {
        final json = {
          'id': 'x', 'type': 'VACATION', 'status': pair.$1,
          'startDate': '2026-01-01', 'endDate': '2026-01-01', 'workingDays': 1,
        };
        expect(AbsenceModel.fromJson(json).status, pair.$2,
            reason: '${pair.$1} should map to ${pair.$2}');
      }
    });

    test('parses reason from note field', () {
      final json = {
        'id': 'abs-3',
        'type': 'VACATION',
        'status': 'PENDING',
        'startDate': '2026-08-01',
        'endDate': '2026-08-05',
        'workingDays': 4,
        'note': 'Family trip',
      };
      final absence = AbsenceModel.fromJson(json);
      expect(absence.reason, 'Family trip');
    });

    test('defaults workingDays to 1 when missing', () {
      final json = {
        'id': 'abs-4',
        'type': 'VACATION',
        'status': 'PENDING',
        'startDate': '2026-09-01',
        'endDate': '2026-09-01',
      };
      final absence = AbsenceModel.fromJson(json);
      expect(absence.workingDays, 1);
    });
  });

  group('AbsenceModel display properties', () {
    final absence = AbsenceModel(
      id: 'x',
      type: AbsenceType.sickLeave,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 3),
      workingDays: 3,
      status: AbsenceStatus.approved,
    );

    test('typeLabel returns readable string', () {
      expect(absence.typeLabel, 'Sick Leave');
    });

    test('statusLabel returns uppercase', () {
      expect(absence.statusLabel, 'APPROVED');
    });
  });
}
