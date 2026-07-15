import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Model representing a single activity entry in the time tracking system
/// Used to display clock in/out events, breaks, and other work-related activities
class ActivityModel {
  /// Unique identifier for this activity
  final String id;
  
  /// Icon representing the activity type (e.g., login for clock in, coffee for break)
  final IconData icon;
  
  /// Title/name of the activity (e.g., "Clock In", "Break Start")
  final String title;
  
  /// Date when the activity occurred
  final DateTime date;
  
  /// Time when the activity occurred
  final DateTime time;
  
  /// Color associated with this activity type for visual distinction
  final Color color;
  
  /// Type of activity for categorization
  final ActivityType type;

  ActivityModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.date,
    required this.time,
    required this.color,
    required this.type,
  });

  /// e.g. "Monday, Oct 23" (en) / "Montag, 23. Okt." (de)
  String get formattedDate {
    final locale  = Intl.defaultLocale ?? 'en';
    final pattern = locale.startsWith('de') ? 'EEEE, d. MMM' : 'EEEE, MMM d';
    return DateFormat(pattern, locale).format(date);
  }

  /// e.g. "9:05 AM" (en) / "09:05" (de)
  String get formattedTime => DateFormat.jm(Intl.defaultLocale).format(time);

  /// Factory constructor to create ActivityModel from JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      icon: _getIconFromString(json['icon'] as String),
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      time: DateTime.parse(json['time'] as String),
      color: Color(json['color'] as int),
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${json['type']}',
        orElse: () => ActivityType.other,
      ),
    );
  }

  /// Convert ActivityModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'icon': icon.codePoint.toString(),
      'title': title,
      'date': date.toIso8601String(),
      'time': time.toIso8601String(),
      'color': color.toARGB32(),
      'type': type.toString().split('.').last,
    };
  }

  static IconData _getIconFromString(String iconCode) {
    // Default mapping - extend as needed
    final code = int.tryParse(iconCode) ?? Icons.event.codePoint;
    return IconData(code, fontFamily: 'MaterialIcons');
  }
}

/// Enum representing different types of activities
enum ActivityType {
  clockIn,
  clockOut,
  breakStart,
  breakEnd,
  other,
}