import 'package:flutter/material.dart';
import '../core/utils/date_formatter.dart';

enum AbsenceType { vacation, training, sickLeave, personalDay, unpaid, standby }
enum AbsenceStatus { pending, approved, rejected }

class AbsenceModel {
  const AbsenceModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.workingDays,
    required this.status,
    this.reason,
  });

  final String        id;
  final AbsenceType   type;
  final DateTime      startDate;
  final DateTime      endDate;
  final int           workingDays;
  final AbsenceStatus status;
  final String?       reason;

  String get formattedDateRange =>
      DateFormatter.formatDateRange(startDate, endDate);

  String get typeLabel => switch (type) {
    AbsenceType.vacation    => 'Vacation',
    AbsenceType.training    => 'Training',
    AbsenceType.sickLeave   => 'Sick Leave',
    AbsenceType.personalDay => 'Personal Day',
    AbsenceType.unpaid      => 'Unpaid Leave',
    AbsenceType.standby     => 'Stand-by',
  };

  IconData get typeIcon => switch (type) {
    AbsenceType.vacation    => Icons.beach_access,
    AbsenceType.training    => Icons.school,
    AbsenceType.sickLeave   => Icons.medical_services,
    AbsenceType.personalDay => Icons.calendar_today,
    AbsenceType.unpaid      => Icons.money_off,
    AbsenceType.standby     => Icons.timer,
  };

  Color get typeBackgroundColor => switch (type) {
    AbsenceType.vacation    => const Color(0xFFE3F2FD),
    AbsenceType.training    => const Color(0xFFF3E5F5),
    AbsenceType.sickLeave   => const Color(0xFFFFEBEE),
    AbsenceType.personalDay => const Color(0xFFF5F5F5),
    AbsenceType.unpaid      => const Color(0xFFFFF3E0),
    AbsenceType.standby     => const Color(0xFFE8F5E9),
  };

  Color get typeIconColor => switch (type) {
    AbsenceType.vacation    => const Color(0xFF2196F3),
    AbsenceType.training    => const Color(0xFF9C27B0),
    AbsenceType.sickLeave   => const Color(0xFFF44336),
    AbsenceType.personalDay => const Color(0xFF757575),
    AbsenceType.unpaid      => const Color(0xFFFF9800),
    AbsenceType.standby     => const Color(0xFF4CAF50),
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

  Color    get typeColor        => typeBackgroundColor;
  String   get typeDisplayName  => typeLabel;
  Color    get statusColor      => statusBackgroundColor;
  String   get statusDisplayName => statusLabel;

  /// The exact enum value the backend `createAbsenceSchema` accepts.
  /// The app has more granular types than the API, so a couple map onto the
  /// nearest supported value (`unpaid`/`standby` → `UNEXCUSED`/`PERSONAL_DAY`).
  String get apiType => apiTypeFor(type);

  static String apiTypeFor(AbsenceType type) => switch (type) {
    AbsenceType.vacation    => 'VACATION',
    AbsenceType.training    => 'TRAINING',
    AbsenceType.sickLeave   => 'SICK_LEAVE',
    AbsenceType.personalDay => 'PERSONAL_DAY',
    AbsenceType.unpaid      => 'UNEXCUSED',
    AbsenceType.standby     => 'PERSONAL_DAY',
  };

  factory AbsenceModel.fromJson(Map<String, dynamic> j) {
    final rawType   = (j['type']   as String?) ?? '';
    final rawStatus = (j['status'] as String?) ?? '';

    return AbsenceModel(
      id:          j['id'] as String,
      type:        _parseType(rawType),
      status:      _parseStatus(rawStatus),
      startDate:   _parseDate(j['start_date'] ?? j['startDate']),
      endDate:     _parseDate(j['end_date']   ?? j['endDate']),
      workingDays: (j['working_days'] ?? j['workingDays'] ?? 1) as int,
      reason:      j['reason'] as String? ?? j['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':           id,
    'type':         type.name,
    'start_date':   startDate.toIso8601String().split('T').first,
    'end_date':     endDate.toIso8601String().split('T').first,
    'working_days': workingDays,
    'status':       status.name,
    'reason':       reason,
  };

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.parse(v as String);
  }

  static AbsenceType _parseType(String raw) {
    final normalised = raw.toLowerCase().replaceAll('_', '');
    return switch (normalised) {
      'vacation'     || 'urlaub'        => AbsenceType.vacation,
      'training'     || 'qualifikation' => AbsenceType.training,
      'sickleave'    || 'krankheit'     => AbsenceType.sickLeave,
      'personalday'  || 'wunschfrei'    => AbsenceType.personalDay,
      'unpaid'       || 'unentschuldigt'=> AbsenceType.unpaid,
      'standby'      => AbsenceType.standby,
      _              => AbsenceType.vacation,
    };
  }

  static AbsenceStatus _parseStatus(String raw) {
    return switch (raw.toLowerCase()) {
      'approved' || 'genehmigt'    => AbsenceStatus.approved,
      'rejected' || 'abgelehnt'    => AbsenceStatus.rejected,
      _                            => AbsenceStatus.pending,
    };
  }
}

typedef Absence = AbsenceModel;
