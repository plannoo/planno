/// Model representing a work shift
/// Contains information about scheduled work hours and location
class ShiftModel {
  /// Unique identifier for this shift
  final String id;
  
  /// Job role/title for this shift (e.g., "Floor Manager", "Sales Associate")
  final String role;
  
  /// Date of the shift
  final DateTime date;
  
  /// Start time of the shift
  final DateTime startTime;
  
  /// End time of the shift
  final DateTime endTime;
  
  /// Location where the shift takes place
  final String location;
  
  /// Full address of the location
  final String address;
  
  /// Latitude of the shift location
  final double latitude;
  
  /// Longitude of the shift location
  final double longitude;
  
  /// Optional notes about the shift
  final String? notes;

  ShiftModel({
    required this.id,
    required this.role,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  /// Calculate total duration of the shift
  Duration get duration => endTime.difference(startTime);

  /// Format start time in 12-hour format
  String get formattedStartTime {
    return _formatTime(startTime);
  }

  /// Format end time in 12-hour format
  String get formattedEndTime {
    return _formatTime(endTime);
  }

  /// Get formatted time range (e.g., "09:00 AM - 05:00 PM")
  String get timeRange => '$formattedStartTime - $formattedEndTime';

  /// Format time in 12-hour format with AM/PM
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Check if this is today's shift
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Factory constructor to create ShiftModel from JSON
  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      role: json['role'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      notes: json['notes'] as String?,
    );
  }

  /// Convert ShiftModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    };
  }

  /// Create a copy of this shift with optional field updates
  ShiftModel copyWith({
    String? id,
    String? role,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      role: role ?? this.role,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
    );
  }
}