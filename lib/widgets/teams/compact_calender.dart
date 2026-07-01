import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A compact horizontal week-strip calendar.
///
/// Shows the 7 days of the current week. Tapping a day calls [onDateSelected].
/// The selected day is highlighted with a filled primary circle.
/// Today gets a subtle underline dot when not selected.
class CompactCalendar extends StatefulWidget {
  const CompactCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.markedDates = const {},
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Dates that have a small indicator dot (e.g. user has shifts on those days).
  final Set<DateTime> markedDates;

  @override
  State<CompactCalendar> createState() => _CompactCalendarState();
}

class _CompactCalendarState extends State<CompactCalendar> {
  late DateTime _weekStart;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(widget.selectedDate);
  }

  @override
  void didUpdateWidget(CompactCalendar old) {
    super.didUpdateWidget(old);
    // Keep the calendar week aligned with the selected date
    if (!DateUtils.isSameDay(
        _mondayOf(widget.selectedDate), _weekStart)) {
      _weekStart = _mondayOf(widget.selectedDate);
    }
  }

  DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  void _prevWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Month label + navigation arrows ───────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                _monthLabel(_weekStart),
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.slate600,
                  letterSpacing: 0.8,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              _NavArrow(
                icon: Icons.chevron_left,
                onTap: _prevWeek,
              ),
              const SizedBox(width: 4),
              _NavArrow(
                icon: Icons.chevron_right,
                onTap: _nextWeek,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Day cells ─────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day      = _weekStart.add(Duration(days: i));
            final isToday  = DateUtils.isSameDay(day, today);
            final selected = DateUtils.isSameDay(day, widget.selectedDate);
            final marked   = widget.markedDates
                .any((d) => DateUtils.isSameDay(d, day));

            return _DayCell(
              dayLabel: _dayLabels[i],
              dayNumber: day.day,
              isToday:   isToday,
              isSelected: selected,
              hasMarker:  marked,
              onTap: () => widget.onDateSelected(day),
            );
          }),
        ),
      ],
    );
  }

  String _monthLabel(DateTime d) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayLabel,
    required this.dayNumber,
    required this.isToday,
    required this.isSelected,
    required this.hasMarker,
    required this.onTap,
  });

  final String dayLabel;
  final int dayNumber;
  final bool isToday;
  final bool isSelected;
  final bool hasMarker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        child: Column(
          children: [
            // Day letter
            Text(
              dayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.slate400,
              ),
            ),
            const SizedBox(height: 4),

            // Number circle
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? AppColors.primary
                          : AppColors.slate700,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Marker dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasMarker
                    ? (isSelected ? Colors.white : AppColors.primary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.slate500),
      ),
    );
  }
}