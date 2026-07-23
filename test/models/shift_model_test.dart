import 'package:flutter_test/flutter_test.dart';
import 'package:wrenta/models/shift_model.dart';

void main() {
  group('ShiftModel.fromJson', () {
    final baseJson = {
      'id': 'shift-001',
      'role': 'EMPLOYEE',
      'date': '2026-06-28',
      'startTime': '2026-06-28T08:00:00.000Z',
      'endTime': '2026-06-28T16:30:00.000Z',
      'location': 'Hauptstandort',
      'address': 'Musterstraße 1, Berlin',
      'latitude': 52.52,
      'longitude': 13.405,
    };

    test('parses required fields', () {
      final shift = ShiftModel.fromJson(baseJson);
      expect(shift.id, 'shift-001');
      expect(shift.role, 'EMPLOYEE');
      expect(shift.location, 'Hauptstandort');
      expect(shift.address, 'Musterstraße 1, Berlin');
      expect(shift.latitude, closeTo(52.52, 0.001));
      expect(shift.longitude, closeTo(13.405, 0.001));
    });

    test('parses optional fields as null when absent', () {
      final shift = ShiftModel.fromJson(baseJson);
      expect(shift.notes, isNull);
      expect(shift.breakMinutes, isNull);
      expect(shift.roleColor, isNull);
      expect(shift.label, isNull);
      expect(shift.hashtags, isEmpty);
    });

    test('parses optional fields when present', () {
      final json = {
        ...baseJson,
        'notes': 'Bring badge',
        'breakMinutes': 30,
        'roleColor': '#2563EB',
        'label': 'Morning',
        'hashtags': ['urgent', 'weekend'],
      };
      final shift = ShiftModel.fromJson(json);
      expect(shift.notes, 'Bring badge');
      expect(shift.breakMinutes, 30);
      expect(shift.roleColor, '#2563EB');
      expect(shift.label, 'Morning');
      expect(shift.hashtags, ['urgent', 'weekend']);
    });

    test('duration is computed from start/end', () {
      final shift = ShiftModel.fromJson(baseJson);
      expect(shift.duration.inMinutes, greaterThan(0));
    });

    test('defaults missing location to empty string', () {
      final json = {
        ...baseJson,
        'location': null,
        'address': null,
        'latitude': null,
        'longitude': null,
      };
      final shift = ShiftModel.fromJson(json);
      expect(shift.location, '');
      expect(shift.address, '');
      expect(shift.latitude, 0.0);
      expect(shift.longitude, 0.0);
    });
  });
}
