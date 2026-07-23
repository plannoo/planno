import 'package:intl/intl.dart';

abstract final class DateFormatter {
  /// e.g. "9:05 AM" (en) / "09:05" (de) — respects Intl.defaultLocale
  static String formatTime(DateTime time) =>
      DateFormat.jm(Intl.defaultLocale).format(time);

  /// e.g. "06:15:22" — locale-independent timer/duration display
  static String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  /// e.g. "Monday, Oct 23" (en) / "Montag, 23. Okt." (de)
  static String formatWeekdayDate(DateTime date) {
    final locale  = Intl.defaultLocale ?? 'en';
    final pattern = locale.startsWith('de') ? 'EEEE, d. MMM' : 'EEEE, MMM d';
    return DateFormat(pattern, locale).format(date);
  }

  /// e.g. "Oct 23" (en) / "23. Okt." (de)
  static String formatShortDate(DateTime date) {
    final locale  = Intl.defaultLocale ?? 'en';
    final pattern = locale.startsWith('de') ? 'd. MMM' : 'MMM d';
    return DateFormat(pattern, locale).format(date);
  }

  /// e.g. "Oct 23, 2024" (en) / "23. Okt. 2024" (de)
  static String formatShortDateWithYear(DateTime date) {
    final locale  = Intl.defaultLocale ?? 'en';
    final pattern = locale.startsWith('de') ? 'd. MMM yyyy' : 'MMM d, yyyy';
    return DateFormat(pattern, locale).format(date);
  }

  /// Short weekday — no trailing dot: "Mon" (en) / "Mo" (de)
  static String formatWeekdayShort(DateTime date) =>
      DateFormat('EEE', Intl.defaultLocale ?? 'en').format(date).replaceAll('.', '');

  /// e.g. "Jul 12 – Jul 19, 2024" (en) / "12. Jul. – 19. Jul. 2024" (de)
  static String formatDateRange(DateTime start, DateTime end) {
    final locale = Intl.defaultLocale ?? 'en';
    final isDE   = locale.startsWith('de');
    final fmt    = DateFormat(isDE ? 'd. MMM' : 'MMM d', locale);
    final s      = fmt.format(start);
    final e      = fmt.format(end);
    return isDE ? '$s – $e ${start.year}' : '$s – $e, ${start.year}';
  }

  /// e.g. "150m" or "1.50km" — locale-independent
  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(2)}km';
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
