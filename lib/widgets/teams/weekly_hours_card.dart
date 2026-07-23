import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/shift_model.dart';

/// Weekly hours summary card for the My Shifts tab.
///
/// Tapping a day bar reveals a [_DayBreakdownPanel] with the clock-in/out
/// detail for that day. Tap the same bar again to dismiss it.
///
/// Pass [shiftsForDay] so the card can look up actual shift records.
class WeeklyHoursCard extends StatefulWidget {
  const WeeklyHoursCard({
    super.key,
    required this.loggedHours,
    required this.targetHours,
    required this.dailyHours,
    required this.weekLabel,
    required this.weekStart,
    required this.shiftsForDay,
  });

  final double loggedHours;
  final double targetHours;

  /// Hours worked per day Mon(0)–Sun(6).
  final List<double> dailyHours;

  /// Human-readable range label, e.g. "Oct 21 – Oct 27".
  final String weekLabel;

  /// The Monday that starts the displayed week.
  final DateTime weekStart;

  /// Returns the list of [ShiftModel]s for any given date.
  final List<ShiftModel> Function(DateTime) shiftsForDay;

  @override
  State<WeeklyHoursCard> createState() => _WeeklyHoursCardState();
}

class _WeeklyHoursCardState extends State<WeeklyHoursCard> {
  /// Index 0=Mon … 6=Sun, null = no bar selected.
  int? _selectedBar;

  double get _progress =>
      widget.targetHours <= 0
          ? 0
          : (widget.loggedHours / widget.targetHours).clamp(0.0, 1.0);

  bool get _isOnTrack  => widget.loggedHours >= widget.targetHours * 0.8;
  bool get _isComplete => widget.loggedHours >= widget.targetHours;

  Color get _progressColor => _isComplete
      ? AppColors.success
      : (_isOnTrack ? AppColors.primary : AppColors.warning);

  String get _statusLabel {
    if (_isComplete) return 'COMPLETE';
    final remaining = widget.targetHours - widget.loggedHours;
    return '${remaining.toStringAsFixed(1)}h remaining';
  }

  void _onBarTapped(int index) {
    setState(() => _selectedBar = _selectedBar == index ? null : index);
  }

  DateTime _dateForBar(int index) =>
      widget.weekStart.add(Duration(days: index));

  @override
  Widget build(BuildContext context) {
    final selectedDate =
        _selectedBar == null ? null : _dateForBar(_selectedBar!);
    final selectedShifts =
        selectedDate == null ? <ShiftModel>[] : widget.shiftsForDay(selectedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _progressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isComplete
                      ? Icons.check_circle_outline_rounded
                      : Icons.access_time_outlined,
                  color: _progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Hours', style: AppTextStyles.bodyBold),
                    const SizedBox(height: 1),
                    Text(widget.weekLabel, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: widget.loggedHours.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _progressColor,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${widget.targetHours.toStringAsFixed(0)}h',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.slate400,
                          fontSize: 13,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _progressColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress bar ─────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 7,
              backgroundColor: AppColors.slate100,
              valueColor: AlwaysStoppedAnimation(_progressColor),
            ),
          ),

          const SizedBox(height: 16),

          // ── Bar chart ────────────────────────────────────────────────
          _DailyBars(
            dailyHours:   widget.dailyHours,
            selectedIndex: _selectedBar,
            onBarTapped:   _onBarTapped,
          ),

          // ── Breakdown panel (animated) ────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _selectedBar != null
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _selectedBar != null
                ? _DayBreakdownPanel(
                    date:   _dateForBar(_selectedBar!),
                    shifts: selectedShifts,
                    hours:  widget.dailyHours.length > _selectedBar!
                        ? widget.dailyHours[_selectedBar!]
                        : 0.0,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _DailyBars extends StatelessWidget {
  const _DailyBars({
    required this.dailyHours,
    required this.selectedIndex,
    required this.onBarTapped,
  });

  final List<double>  dailyHours;
  final int?          selectedIndex;
  final ValueChanged<int> onBarTapped;

  static const _labels        = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _maxBarHeight  = 36.0;
  static const _targetDayH    = 8.0;

  @override
  Widget build(BuildContext context) {
    final todayIdx = DateTime.now().weekday - 1; // 0 = Mon

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final hours      = dailyHours.length > i ? dailyHours[i] : 0.0;
        final isToday    = i == todayIdx;
        final isSelected = i == selectedIndex;
        final isFuture   = i > todayIdx;
        final ratio      = (hours / _targetDayH).clamp(0.0, 1.0);
        final barH       = (_maxBarHeight * ratio).clamp(0.0, _maxBarHeight);

        final barColor = isFuture
            ? AppColors.slate100
            : isToday
                ? AppColors.primary
                : hours >= _targetDayH
                    ? AppColors.success
                    : AppColors.primaryLight;

        return GestureDetector(
          onTap: () => onBarTapped(i),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryLighter
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hour label
                Text(
                  hours > 0 ? '${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)}h' : '',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary
                            : AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 3),

                // Bar track + fill
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 22,
                      height: _maxBarHeight,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight.withValues(alpha: 0.4)
                            : AppColors.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    if (barH > 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        width: 22,
                        height: barH.clamp(4.0, _maxBarHeight),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : barColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),

                // Day label
                Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: (isToday || isSelected)
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary
                            : AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Day breakdown panel ───────────────────────────────────────────────────────

class _DayBreakdownPanel extends StatelessWidget {
  const _DayBreakdownPanel({
    required this.date,
    required this.shifts,
    required this.hours,
  });

  final DateTime       date;
  final List<ShiftModel> shifts;
  final double         hours;

  @override
  Widget build(BuildContext context) {
    final dayLabel = _formatDate(date);
    final isToday  = DateUtils.isSameDay(date, DateTime.now());

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Panel header ────────────────────────────────────────────
          Row(
            children: [
              Text(
                isToday ? 'Today' : dayLabel,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              if (!isToday)
                Text(
                  dayLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate400,
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  hours > 0
                      ? '${hours.toStringAsFixed(1)}h logged'
                      : 'No hours',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // ── Shift rows or empty message ──────────────────────────────
          if (shifts.isEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_busy_outlined,
                    size: 16, color: AppColors.slate400),
                const SizedBox(width: 8),
                Text(
                  'No shifts scheduled',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.slate400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            ...shifts.map((s) => _ShiftBreakdownRow(shift: s)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final locale  = Intl.defaultLocale ?? 'en';
    final pattern = locale.startsWith('de') ? 'EEE, d. MMM' : 'EEE, MMM d';
    return DateFormat(pattern, locale).format(d);
  }
}

// ── Individual shift row inside breakdown ─────────────────────────────────────

class _ShiftBreakdownRow extends StatelessWidget {
  const _ShiftBreakdownRow({required this.shift});
  final ShiftModel shift;

  @override
  Widget build(BuildContext context) {
    final duration  = shift.duration;
    final durationLabel = _formatDuration(duration);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          // Clock icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.fingerprint,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Role + location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.role,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: AppColors.slate400),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        shift.location,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time range + duration
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  _TimeChip(
                    label: shift.formattedStartTime,
                    icon: Icons.login_rounded,
                    color: AppColors.success,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('→',
                        style: TextStyle(
                            color: AppColors.slate300, fontSize: 12)),
                  ),
                  _TimeChip(
                    label: shift.formattedEndTime,
                    icon: Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                durationLabel,
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.primary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String   label;
  final IconData icon;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}