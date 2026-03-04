import '../../core/utils/date_formatter.dart';

/// Summary of an employee's absence quota for the year.
class AbsenceSummaryModel {
  final int usedDays;
  final int totalDays;
  final DateTime validUntil;

  const AbsenceSummaryModel({
    required this.usedDays,
    required this.totalDays,
    required this.validUntil,
  });

  int    get remainingDays    => totalDays - usedDays;
  double get usagePercentage  => totalDays > 0 ? usedDays / totalDays : 0;
  String get formattedValidUntil => DateFormatter.formatWeekdayDate(validUntil);
}