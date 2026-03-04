import 'package:flutter/material.dart';

/// Badge widget that displays the current on-duty status
/// Shows a green "ON DUTY" indicator when the user is clocked in
/// Can be extended to show other statuses like "OFF DUTY", "ON BREAK", etc.
class OnDutyStatus extends StatelessWidget {
  /// Whether the user is currently on duty
  final bool isOnDuty;
  
  /// Type of duty status to display
  final DutyStatusType statusType;

  const OnDutyStatus({
    super.key,
    this.isOnDuty = true,
    this.statusType = DutyStatusType.onDuty,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status indicator dot
          _buildStatusDot(statusConfig.dotColor),
          const SizedBox(width: 8),
          
          // Status text
          _buildStatusText(statusConfig.label, statusConfig.textColor),
        ],
      ),
    );
  }

  /// Builds the small circular status indicator
  Widget _buildStatusDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Builds the status label text
  Widget _buildStatusText(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Returns the configuration for the current status type
  _StatusConfig _getStatusConfig() {
    switch (statusType) {
      case DutyStatusType.onDuty:
        return _StatusConfig(
          label: 'ON DUTY',
          backgroundColor: const Color(0xFFDCFCE7), // Light green
          dotColor: const Color(0xFF22C55E), // Green
          textColor: const Color(0xFF22C55E), // Green
        );
      case DutyStatusType.offDuty:
        return _StatusConfig(
          label: 'OFF DUTY',
          backgroundColor: const Color(0xFFF1F5F9), // Light gray
          dotColor: const Color(0xFF64748B), // Slate gray
          textColor: const Color(0xFF64748B), // Slate gray
        );
      case DutyStatusType.onBreak:
        return _StatusConfig(
          label: 'ON BREAK',
          backgroundColor: const Color(0xFFFEF3C7), // Light amber
          dotColor: const Color(0xFFF59E0B), // Amber
          textColor: const Color(0xFFF59E0B), // Amber
        );
    }
  }
}

/// Configuration class for status badge appearance
class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color dotColor;
  final Color textColor;

  const _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.dotColor,
    required this.textColor,
  });
}

/// Enum representing different duty status types
enum DutyStatusType {
  /// User is currently clocked in and working
  onDuty,
  
  /// User is clocked out
  offDuty,
  
  /// User is on a break
  onBreak,
}