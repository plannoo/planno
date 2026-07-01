import 'package:flutter/material.dart';
import '../models/activity_model.dart';

/// Widget that displays a single activity item in a list
/// Shows an icon, title, date, and time for activities like clock in/out
/// 
/// Example usage:
/// ```dart
/// ActivityItem(
///   activity: ActivityModel(
///     icon: Icons.login,
///     title: 'Clock In',
///     date: DateTime.now(),
///     time: DateTime.now(),
///     color: Colors.green,
///   ),
/// )
/// ```
class ActivityItem extends StatelessWidget {
  /// The activity data to display
  final ActivityModel activity;

  const ActivityItem({
    super.key,
    required this.activity,
  });

  // Alternative constructor for direct property passing (backward compatibility)
  factory ActivityItem.fromProperties({
    required IconData icon,
    required String title,
    required String date,
    required String time,
    required Color color,
  }) {
    // Create a temporary ActivityModel for display
    final now = DateTime.now();
    return ActivityItem(
      activity: ActivityModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        icon: icon,
        title: title,
        date: now,
        time: now,
        color: color,
        type: ActivityType.other,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Activity icon with colored background
        _buildIconContainer(),
        const SizedBox(width: 16),
        
        // Activity details (title and date)
        Expanded(
          child: _buildActivityDetails(),
        ),
        
        // Time display
        _buildTimeText(),
      ],
    );
  }

  /// Builds the colored icon container
  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Light colored background matching the activity color
        color: activity.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        activity.icon,
        color: activity.color,
        size: 20,
      ),
    );
  }

  /// Builds the activity title and date column
  Widget _buildActivityDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity title (e.g., "Clock In")
        Text(
          activity.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A), // Dark slate color
          ),
        ),
        const SizedBox(height: 2),
        
        // Activity date (e.g., "Monday, Oct 23")
        Text(
          activity.formattedDate,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B), // Slate gray color
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Builds the time text display
  Widget _buildTimeText() {
    return Text(
      activity.formattedTime,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A), // Dark slate color
      ),
    );
  }
}