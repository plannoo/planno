import 'package:flutter/material.dart';
import '../models/shift_model.dart';

/// Widget that displays today's shift information in a visually appealing card
/// Shows the shift role, time range, location, and an option to view details
/// 
/// The card features a background image with an overlay and prominent shift details
class TodayShiftCard extends StatelessWidget {
  /// The shift data to display
  /// If null, sample data will be shown
  final ShiftModel? shift;
  
  /// Callback when "View Details" button is tapped
  final VoidCallback? onViewDetails;

  const TodayShiftCard({
    super.key,
    this.shift,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final displayShift = shift ?? _getSampleShift();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info icon in top-left corner
          _buildInfoIcon(),
          const SizedBox(height: 80),
          
          // Shift details card
          _buildShiftDetailsCard(displayShift),
        ],
      ),
    );
  }

  /// Builds the card background decoration with image
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      image: const DecorationImage(
        // Office/workspace image as background
        image: NetworkImage(
          'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
        ),
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds the information icon in the top-left corner
  Widget _buildInfoIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE), // Light blue
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.info_outline,
        color: Color(0xFF2563EB), // Blue
        size: 20,
      ),
    );
  }

  /// Builds the white card containing shift details
  Widget _buildShiftDetailsCard(ShiftModel displayShift) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role label
          _buildRoleLabel(displayShift.role),
          const SizedBox(height: 4),
          
          // "Today's Shift" title
          _buildShiftTitle(),
          const SizedBox(height: 12),
          
          // Time range and view details button
          _buildTimeRangeRow(displayShift),
          const SizedBox(height: 12),
          
          // Divider
          const Divider(),
          const SizedBox(height: 8),
          
          // Location information
          _buildLocationRow(displayShift),
        ],
      ),
    );
  }

  /// Builds the role label (e.g., "FLOOR MANAGER")
  Widget _buildRoleLabel(String role) {
    return Text(
      role.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B), // Slate gray
        letterSpacing: 0.5,
      ),
    );
  }

  /// Builds the "Today's Shift" title
  Widget _buildShiftTitle() {
    return const Text(
      "Today's Shift",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A), // Dark slate
      ),
    );
  }

  /// Builds the time range row with clock icon and view details button
  Widget _buildTimeRangeRow(ShiftModel displayShift) {
    return Row(
      children: [
        // Clock icon
        const Icon(
          Icons.access_time,
          size: 18,
          color: Color(0xFF64748B), // Slate gray
        ),
        const SizedBox(width: 8),
        
        // Time range text
        Text(
          displayShift.timeRange,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B), // Slate gray
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        
        // View Details button
        _buildViewDetailsButton(),
      ],
    );
  }

  /// Builds the "View Details" button
  Widget _buildViewDetailsButton() {
    return TextButton(
      onPressed: onViewDetails ?? () {
        // Default empty action
      },
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB), // Blue text
        backgroundColor: const Color(0xFFEFF6FF), // Light blue background
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'View Details',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Builds the location information row
  Widget _buildLocationRow(ShiftModel displayShift) {
    return Row(
      children: [
        // "Location" label
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8), // Light slate gray
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        
        // Location name
        Flexible(
          child: Text(
            displayShift.location,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A), // Dark slate
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Returns sample shift data for demonstration
  /// In a real app, this would come from a database or API
  ShiftModel _getSampleShift() {
    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day, 9, 0);
    final endTime = DateTime(now.year, now.month, now.day, 17, 0);
    
    return ShiftModel(
      id: 'sample-shift-1',
      role: 'Floor Manager',
      date: now,
      startTime: startTime,
      endTime: endTime,
      location: 'Main Office, Berlin',
      address: 'Friedrichstraße 123, 10117 Berlin',
      latitude: 52.5200,
      longitude: 13.4050,
      notes: 'Regular weekday shift',
    );
  }
}