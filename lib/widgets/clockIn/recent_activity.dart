import 'package:flutter/material.dart';
import '../activity_item.dart';
import '../../models/activity_model.dart';

/// Widget that displays a list of recent activities in a card
/// Shows clock in/out events, breaks, and other work-related activities
/// 
/// This widget can be populated with real data from a database or API
class RecentActivity extends StatelessWidget {
  /// List of activities to display
  /// If null, sample data will be shown
  final List<ActivityModel>? activities;
  
  /// Maximum number of activities to display
  final int maxActivities;

  const RecentActivity({
    super.key,
    this.activities,
    this.maxActivities = 5,
  });

  @override
  Widget build(BuildContext context) {
    final displayActivities = _getDisplayActivities();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(),
          const SizedBox(height: 20),
          
          // Activity list or empty state
          if (displayActivities.isEmpty)
            _buildEmptyState()
          else
            _buildActivityList(displayActivities),
        ],
      ),
    );
  }

  /// Builds the card decoration with rounded corners and border
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: const Color(0xFFF1F5F9), // Light gray border
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Builds the "RECENT ACTIVITY" section header
  Widget _buildSectionHeader() {
    return const Text(
      'RECENT ACTIVITY',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B), // Slate gray
        letterSpacing: 0.5,
      ),
    );
  }

  /// Builds the list of activity items
  Widget _buildActivityList(List<ActivityModel> displayActivities) {
    return Column(
      children: List.generate(
        displayActivities.length,
        (index) {
          final activity = displayActivities[index];
          return Column(
            children: [
              ActivityItem(activity: activity),
              // Add spacing between items (except after the last one)
              if (index < displayActivities.length - 1)
                const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// Builds an empty state when no activities are available
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No recent activity',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gets the activities to display (either provided or sample data)
  List<ActivityModel> _getDisplayActivities() {
    if (activities != null) {
      // Use provided activities, limited to maxActivities
      return activities!.take(maxActivities).toList();
    }
    
    // Return sample data for demonstration
    return _getSampleActivities();
  }

  /// Returns sample activity data for demonstration purposes
  /// In a real app, this would be replaced with actual data from a database
  List<ActivityModel> _getSampleActivities() {
    final now = DateTime.now();
    
    return [
      ActivityModel(
        id: '1',
        icon: Icons.login,
        title: 'Clock In',
        date: DateTime(now.year, now.month, now.day, 9, 0),
        time: DateTime(now.year, now.month, now.day, 9, 0),
        color: const Color(0xFF22C55E), // Green
        type: ActivityType.clockIn,
      ),
      ActivityModel(
        id: '2',
        icon: Icons.coffee,
        title: 'Break Start',
        date: DateTime(now.year, now.month, now.day, 12, 30),
        time: DateTime(now.year, now.month, now.day, 12, 30),
        color: const Color(0xFFF59E0B), // Amber
        type: ActivityType.breakStart,
      ),
      ActivityModel(
        id: '3',
        icon: Icons.work,
        title: 'Break End',
        date: DateTime(now.year, now.month, now.day, 13, 0),
        time: DateTime(now.year, now.month, now.day, 13, 0),
        color: const Color(0xFF2563EB), // Blue
        type: ActivityType.breakEnd,
      ),
    ];
  }
}