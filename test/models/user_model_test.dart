import 'package:flutter_test/flutter_test.dart';
import 'package:aplano/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parses camelCase fields from API response', () {
      final json = {
        'id': 'u-001',
        'email': 'sarah@aplano.com',
        'firstName': 'Sarah',
        'lastName': 'Weber',
        'role': 'EMPLOYEE',
        'phone': '+49 170 1234567',
        'avatarUrl': 'https://example.com/avatar.jpg',
      };
      final user = UserModel.fromJson(json);
      expect(user.id, 'u-001');
      expect(user.firstName, 'Sarah');
      expect(user.lastName, 'Weber');
      expect(user.role, 'employee'); // lowercased
      expect(user.phone, '+49 170 1234567');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('parses snake_case fields as fallback', () {
      final json = {
        'id': 'u-002',
        'email': 'ralf@aplano.com',
        'first_name': 'Ralf',
        'last_name': 'Müller',
        'role': 'ADMIN',
        'avatar_url': null,
      };
      final user = UserModel.fromJson(json);
      expect(user.firstName, 'Ralf');
      expect(user.lastName, 'Müller');
      expect(user.role, 'admin');
      expect(user.avatarUrl, isNull);
    });

    test('extracts location IDs from locations array of objects', () {
      final json = {
        'id': 'u-003',
        'email': 'ali@aplano.com',
        'firstName': 'Ali',
        'lastName': 'Hassan',
        'role': 'manager',
        'locations': [
          {'id': 'loc-1', 'name': 'Hauptstandort'},
          {'id': 'loc-2', 'name': 'Zweigstelle'},
        ],
      };
      final user = UserModel.fromJson(json);
      expect(user.assignedLocationIds, ['loc-1', 'loc-2']);
    });

    test('extracts location IDs from flat assigned_location_ids list', () {
      final json = {
        'id': 'u-004',
        'email': 'demo@aplano.com',
        'firstName': 'Demo',
        'lastName': 'User',
        'role': 'employee',
        'assigned_location_ids': ['loc-a', 'loc-b'],
      };
      final user = UserModel.fromJson(json);
      expect(user.assignedLocationIds, ['loc-a', 'loc-b']);
    });

    test('returns empty location list when neither field present', () {
      final json = {
        'id': 'u-005',
        'email': 'empty@aplano.com',
        'firstName': 'Empty',
        'lastName': 'Locs',
        'role': 'employee',
      };
      final user = UserModel.fromJson(json);
      expect(user.assignedLocationIds, isEmpty);
    });

    test('derived properties: fullName, initials', () {
      final json = {
        'id': 'u-006',
        'email': 'anna@aplano.com',
        'firstName': 'Anna',
        'lastName': 'Schmidt',
        'role': 'employee',
      };
      final user = UserModel.fromJson(json);
      expect(user.fullName, 'Anna Schmidt');
      expect(user.initials, 'AS');
    });

    test('defaults missing role to employee', () {
      final json = {
        'id': 'u-007',
        'email': 'norole@aplano.com',
        'firstName': 'No',
        'lastName': 'Role',
      };
      final user = UserModel.fromJson(json);
      expect(user.role, 'employee');
    });
  });
}
