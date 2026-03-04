import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum LocationType { office, warehouse, constructionSite, retail, remote }

/// A workplace location with geofencing capabilities.
class WorkLocationModel {
  final int id;
  final String name;
  final String? address;
  final String locationCode;
  final double latitude;
  final double longitude;
  final double geofenceRadiusMeters;
  final double gpsBufferMeters;
  final LocationType locationType;
  final bool isActive;
  final bool requiresGeofence;
  final String timezone;
  final String? managerName;
  final String? managerEmail;
  final bool isPrimaryLocation;

  const WorkLocationModel({
    required this.id,
    required this.name,
    this.address,
    required this.locationCode,
    required this.latitude,
    required this.longitude,
    this.geofenceRadiusMeters = 200.0,
    this.gpsBufferMeters = 10.0,
    this.locationType = LocationType.office,
    this.isActive = true,
    this.requiresGeofence = true,
    this.timezone = 'UTC',
    this.managerName,
    this.managerEmail,
    this.isPrimaryLocation = false,
  });

  double get effectiveRadiusMeters => geofenceRadiusMeters + gpsBufferMeters;

  double distanceTo(Position position) => Geolocator.distanceBetween(
        latitude, longitude, position.latitude, position.longitude);

  bool isWithinWorkZone(Position position) =>
      distanceTo(position) <= effectiveRadiusMeters;

  IconData get icon => switch (locationType) {
    LocationType.warehouse       => Icons.warehouse,
    LocationType.constructionSite => Icons.construction,
    LocationType.retail          => Icons.store,
    LocationType.remote          => Icons.home_work,
    LocationType.office          => Icons.apartment,
  };

  Color get color => switch (locationType) {
    LocationType.warehouse        => const Color(0xFFF59E0B),
    LocationType.constructionSite => const Color(0xFFEF4444),
    LocationType.retail           => const Color(0xFF8B5CF6),
    LocationType.remote           => const Color(0xFF22C55E),
    LocationType.office           => const Color(0xFF2563EB),
  };

  factory WorkLocationModel.fromJson(Map<String, dynamic> json) => WorkLocationModel(
    id: json['id'] as int,
    name: json['name'] as String,
    address: json['address'] as String?,
    locationCode: json['location_code'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    geofenceRadiusMeters: (json['geofence_radius_meters'] as num?)?.toDouble() ?? 200.0,
    gpsBufferMeters: (json['gps_buffer_meters'] as num?)?.toDouble() ?? 10.0,
    locationType: LocationType.values.firstWhere(
      (e) => e.name == (json['location_type'] ?? 'office'),
      orElse: () => LocationType.office,
    ),
    isActive: json['is_active'] == 1 || json['is_active'] == true,
    requiresGeofence: json['requires_geofence'] == 1 || json['requires_geofence'] == true,
    timezone: json['timezone'] as String? ?? 'UTC',
    managerName: json['manager_name'] as String?,
    managerEmail: json['manager_email'] as String?,
    isPrimaryLocation: json['is_primary_location'] == 1 || json['is_primary_location'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'address': address,
    'location_code': locationCode,
    'latitude': latitude, 'longitude': longitude,
    'geofence_radius_meters': geofenceRadiusMeters,
    'gps_buffer_meters': gpsBufferMeters,
    'location_type': locationType.name,
    'is_active': isActive, 'requires_geofence': requiresGeofence,
    'timezone': timezone, 'manager_name': managerName,
    'manager_email': managerEmail, 'is_primary_location': isPrimaryLocation,
  };
}