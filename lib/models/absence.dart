import 'package:flutter/material.dart';
import '../../core/utils/date_formatter.dart';

enum AbsenceType { vacation, training, sickLeave, personalDay }
enum AbsenceStatus { pending, approved, rejected }

/// Represents an employee absence request.
class AbsenceModel {
  final String id;
  final AbsenceType type;
  final DateTime startDate;
  final DateTime endDate;
  final int workingDays;
  final AbsenceStatus status;
  final String? reason;

  const AbsenceModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.workingDays,
    required this.status,
    this.reason,
  });

  // ── Display helpers ────────────────────────────────────────────────────────

  String get formattedDateRange => DateFormatter.formatDateRange(startDate, endDate);

  String get typeLabel => switch (type) {
    AbsenceType.vacation    => 'Vacation',
    AbsenceType.training    => 'Training',
    AbsenceType.sickLeave   => 'Sick Leave',
    AbsenceType.personalDay => 'Personal Day',
  };

  IconData get typeIcon => switch (type) {
    AbsenceType.vacation    => Icons.beach_access,
    AbsenceType.training    => Icons.school,
    AbsenceType.sickLeave   => Icons.medical_services,
    AbsenceType.personalDay => Icons.calendar_today,
  };

  Color get typeBackgroundColor => switch (type) {
    AbsenceType.vacation    => const Color(0xFFE3F2FD),
    AbsenceType.training    => const Color(0xFFF3E5F5),
    AbsenceType.sickLeave   => const Color(0xFFFFEBEE),
    AbsenceType.personalDay => const Color(0xFFF5F5F5),
  };

  Color get typeIconColor => switch (type) {
    AbsenceType.vacation    => const Color(0xFF2196F3),
    AbsenceType.training    => const Color(0xFF9C27B0),
    AbsenceType.sickLeave   => const Color(0xFFF44336),
    AbsenceType.personalDay => const Color(0xFF757575),
  };

  String get statusLabel => switch (status) {
    AbsenceStatus.approved => 'APPROVED',
    AbsenceStatus.pending  => 'PENDING',
    AbsenceStatus.rejected => 'REJECTED',
  };

  Color get statusBackgroundColor => switch (status) {
    AbsenceStatus.approved => const Color(0xFFD4EDDA),
    AbsenceStatus.pending  => const Color(0xFFFFF4E5),
    AbsenceStatus.rejected => const Color(0xFFF8D7DA),
  };

  Color get statusTextColor => switch (status) {
    AbsenceStatus.approved => const Color(0xFF155724),
    AbsenceStatus.pending  => const Color(0xFF856404),
    AbsenceStatus.rejected => const Color(0xFF721C24),
  };

  // ── Aliases for backward compatibility ────────────────────────────────

  /// Alias for typeBackgroundColor for backward compatibility with widgets
  Color get typeColor => typeBackgroundColor;

  /// Alias for typeLabel for backward compatibility with widgets
  String get typeDisplayName => typeLabel;

  /// Alias for statusBackgroundColor for backward compatibility with widgets
  Color get statusColor => statusBackgroundColor;

  /// Alias for statusLabel for backward compatibility with widgets
  String get statusDisplayName => statusLabel;

  // ── JSON ──────────────────────────────────────────────────────────────────

  factory AbsenceModel.fromJson(Map<String, dynamic> json) => AbsenceModel(
    id: json['id'] as String,
    type: AbsenceType.values.firstWhere((e) => e.name == json['type']),
    startDate: DateTime.parse(json['start_date'] as String),
    endDate: DateTime.parse(json['end_date'] as String),
    workingDays: json['working_days'] as int,
    status: AbsenceStatus.values.firstWhere((e) => e.name == json['status']),
    reason: json['reason'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'working_days': workingDays,
    'status': status.name,
    'reason': reason,
  };
}

/// Type alias for AbsenceModel for backward compatibility
typedef Absence = AbsenceModel;