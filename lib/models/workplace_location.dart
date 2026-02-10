import 'package:geolocator/geolocator.dart';

/// Model representing a workplace location with geofencing capabilities
class WorkplaceLocation {
  /// Name of the location (e.g., "Main Office, Berlin")
  final String name;
  
  /// Full street address
  final String address;
  
  /// Latitude coordinate
  final double latitude;
  
  /// Longitude coordinate
  final double longitude;
  
  /// Geofence radius in meters - the allowed distance from the workplace
  final double geofenceRadiusMeters;
  
  /// GPS buffer in meters to account for GPS inaccuracy
  /// This is added to the geofence radius to create an effective radius
  final double gpsBufferMeters;

  const WorkplaceLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.geofenceRadiusMeters = 200.0,
    this.gpsBufferMeters = 10.0,
  });

  /// Calculate the effective radius including GPS buffer
  /// This is the actual radius used for location checks
  double get effectiveRadiusMeters => geofenceRadiusMeters + gpsBufferMeters;

  /// Calculate distance from this workplace to a given position
  /// Returns distance in meters
  double distanceTo(Position position) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      position.latitude,
      position.longitude,
    );
  }

  /// Check if a position is within the work zone (effective radius)
  bool isWithinWorkZone(Position position) {
    return distanceTo(position) <= effectiveRadiusMeters;
  }

  /// Check if a position is within the strict geofence (without buffer)
  bool isWithinStrictGeofence(Position position) {
    return distanceTo(position) <= geofenceRadiusMeters;
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    }
  }

  /// Get a human-readable status message based on distance
  LocationStatus getLocationStatus(Position? position) {
    if (position == null) {
      return LocationStatus(
        isWithinZone: false,
        message: 'Location not available',
        statusType: LocationStatusType.unavailable,
      );
    }

    final distance = distanceTo(position);
    final isWithin = isWithinWorkZone(position);

    if (isWithin) {
      return LocationStatus(
        isWithinZone: true,
        message: 'You are within the work zone (${formatDistance(distance)})',
        statusType: LocationStatusType.withinZone,
        distance: distance,
      );
    } else {
      return LocationStatus(
        isWithinZone: false,
        message: 'You are outside the work zone (${formatDistance(distance)} away)',
        statusType: LocationStatusType.outsideZone,
        distance: distance,
      );
    }
  }

  /// Factory constructor to create from JSON
  factory WorkplaceLocation.fromJson(Map<String, dynamic> json) {
    return WorkplaceLocation(
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      geofenceRadiusMeters: json['geofenceRadiusMeters'] as double? ?? 200.0,
      gpsBufferMeters: json['gpsBufferMeters'] as double? ?? 10.0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      'gpsBufferMeters': gpsBufferMeters,
    };
  }
}

/// Represents the current location status relative to the workplace
class LocationStatus {
  /// Whether the user is within the work zone
  final bool isWithinZone;
  
  /// Human-readable status message
  final String message;
  
  /// Type of location status
  final LocationStatusType statusType;
  
  /// Distance from workplace in meters (if available)
  final double? distance;

  const LocationStatus({
    required this.isWithinZone,
    required this.message,
    required this.statusType,
    this.distance,
  });
}

/// Enum representing different location status types
enum LocationStatusType {
  withinZone,
  outsideZone,
  unavailable,
  loading,
  permissionDenied,
  serviceDisabled,
}