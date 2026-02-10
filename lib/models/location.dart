// models/location.dart

import 'package:flutter/material.dart';

class WorkLocation {
  final int id;
  final String name;
  final String? address;
  final String locationCode;
  final double latitude;
  final double longitude;
  final double geofenceRadiusMeters;
  final double gpsBufferMeters;
  final String locationType; // office, warehouse, construction_site, retail, remote
  final bool isActive;
  final bool requiresGeofence;
  final String timezone;
  final String? managerName;
  final String? managerEmail;
  final bool isPrimaryLocation; // From employee_locations join

  WorkLocation({
    required this.id,
    required this.name,
    this.address,
    required this.locationCode,
    required this.latitude,
    required this.longitude,
    this.geofenceRadiusMeters = 200.0,
    this.gpsBufferMeters = 10.0,
    this.locationType = 'office',
    this.isActive = true,
    this.requiresGeofence = true,
    this.timezone = 'UTC',
    this.managerName,
    this.managerEmail,
    this.isPrimaryLocation = false,
  });

  double get effectiveRadiusMeters => geofenceRadiusMeters + gpsBufferMeters;

  factory WorkLocation.fromJson(Map<String, dynamic> json) {
    return WorkLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      locationCode: json['location_code'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      geofenceRadiusMeters: json['geofence_radius_meters'] ?? 200.0,
      gpsBufferMeters: json['gps_buffer_meters'] ?? 10.0,
      locationType: json['location_type'] ?? 'office',
      isActive: json['is_active'] == 1,
      requiresGeofence: json['requires_geofence'] == 1,
      timezone: json['timezone'] ?? 'UTC',
      managerName: json['manager_name'],
      managerEmail: json['manager_email'],
      isPrimaryLocation: json['is_primary_location'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location_code': locationCode,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius_meters': geofenceRadiusMeters,
      'gps_buffer_meters': gpsBufferMeters,
      'location_type': locationType,
      'is_active': isActive ? 1 : 0,
      'requires_geofence': requiresGeofence ? 1 : 0,
      'timezone': timezone,
      'manager_name': managerName,
      'manager_email': managerEmail,
      'is_primary_location': isPrimaryLocation ? 1 : 0,
    };
  }

  // Icon based on location type
  IconData get icon {
    switch (locationType) {
      case 'warehouse':
        return Icons.warehouse;
      case 'construction_site':
        return Icons.construction;
      case 'retail':
        return Icons.store;
      case 'remote':
        return Icons.home_work;
      case 'office':
      default:
        return Icons.apartment;
    }
  }

  // Color based on location type
  Color get color {
    switch (locationType) {
      case 'warehouse':
        return const Color(0xFFF59E0B); // Orange
      case 'construction_site':
        return const Color(0xFFEF4444); // Red
      case 'retail':
        return const Color(0xFF8B5CF6); // Purple
      case 'remote':
        return const Color(0xFF22C55E); // Green
      case 'office':
      default:
        return const Color(0xFF2563EB); // Blue
    }
  }
}