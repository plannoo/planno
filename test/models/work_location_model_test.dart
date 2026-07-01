import 'package:flutter_test/flutter_test.dart';
import 'package:aplano/models/work_location_model.dart';

void main() {
  group('WorkLocationModel.fromJson', () {
    final json = {
      'id': 'loc-1',
      'name': 'Hauptstandort',
      'address': 'Musterstraße 1, Berlin',
      'latitude': 52.52,
      'longitude': 13.405,
      'geofence_radius_meters': 150,
      'gps_buffer_meters': 15,
      'location_type': 'warehouse',
      'is_active': true,
      'requires_geofence': true,
      'is_primary_location': true,
    };

    test('parses the work-location DTO from the backend', () {
      final loc = WorkLocationModel.fromJson(json);
      expect(loc.id, 'loc-1');
      expect(loc.name, 'Hauptstandort');
      expect(loc.latitude, closeTo(52.52, 0.0001));
      expect(loc.longitude, closeTo(13.405, 0.0001));
      expect(loc.geofenceRadiusMeters, 150);
      expect(loc.gpsBufferMeters, 15);
      expect(loc.locationType, LocationType.warehouse);
      expect(loc.isPrimaryLocation, isTrue);
    });

    test('uses default radius/buffer when missing', () {
      final loc = WorkLocationModel.fromJson({
        'id': 'loc-2', 'name': 'X', 'latitude': 0, 'longitude': 0,
      });
      expect(loc.geofenceRadiusMeters, 200.0);
      expect(loc.gpsBufferMeters, 10.0);
      expect(loc.locationType, LocationType.office);
    });

    test('accepts integer 1/0 booleans', () {
      final loc = WorkLocationModel.fromJson({
        'id': 'loc-3', 'name': 'X', 'latitude': 0, 'longitude': 0,
        'is_active': 1, 'requires_geofence': 0,
      });
      expect(loc.isActive, isTrue);
      expect(loc.requiresGeofence, isFalse);
    });

    test('falls back to office for unknown location_type', () {
      final loc = WorkLocationModel.fromJson({
        'id': 'loc-4', 'name': 'X', 'latitude': 0, 'longitude': 0,
        'location_type': 'spaceship',
      });
      expect(loc.locationType, LocationType.office);
    });

    test('effectiveRadiusMeters adds buffer to geofence', () {
      final loc = WorkLocationModel.fromJson(json);
      expect(loc.effectiveRadiusMeters, 150 + 15);
    });
  });
}
