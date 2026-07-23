import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

DateTime _monday(DateTime d) {
  final diff = d.weekday - 1;
  return DateTime(d.year, d.month, d.day - diff);
}

String _cwLabel(DateTime d) {
  final jan4 = DateTime(d.year, 1, 4);
  final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
  final diff = d.difference(startOfWeek1).inDays;
  return 'CW ${(diff ~/ 7) + 1}';
}

/// Formats an ISO datetime string (e.g. the shift's startTime/endTime) to a
/// local HH:MM label. Returns '--:--' when the value is missing/unparseable.
String _hhmm(String? iso) {
  if (iso == null || iso.isEmpty) return '--:--';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '--:--';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _Shift {
  final String id;
  final String dateIso;
  final String start;
  final String end;
  final int    breakMin;
  final String role;

  const _Shift({
    required this.id,
    required this.dateIso,
    required this.start,
    required this.end,
    required this.breakMin,
    required this.role,
  });
}

/// A school-holiday range (e.g. "Sommerferien", 20 Jul – 1 Sep).
class _Holiday {
  final String name;
  final DateTime start;
  final DateTime end;
  const _Holiday(this.name, this.start, this.end);

  /// True if [d]'s calendar day falls within the holiday range (inclusive).
  bool covers(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final s   = DateTime(start.year, start.month, start.day);
    final e   = DateTime(end.year, end.month, end.day);
    return !day.isBefore(s) && !day.isAfter(e);
  }

  factory _Holiday.fromJson(Map<String, dynamic> j) => _Holiday(
        j['name'] as String? ?? 'Holiday',
        DateTime.parse(j['startDate'] as String),
        DateTime.parse(j['endDate'] as String),
      );
}

// ── Main page ──────────────────────────────────────────────────────────────────

class MySchedulePage extends StatefulWidget {
  const MySchedulePage({super.key});

  @override
  State<MySchedulePage> createState() => _MySchedulePageState();
}

class _MySchedulePageState extends State<MySchedulePage> {

  late DateTime _weekStart;
  late DateTime _selectedDay;
  bool _showEntireMonth = false;
  bool _minimizeEmpty   = false;
  List<_Shift> _shifts  = [];
  List<_Holiday> _holidays = [];
  bool _loading         = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart   = _monday(now);
    _selectedDay = now;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  // All days for the current view (week or full month)
  List<DateTime> get _allDays {
    if (_showEntireMonth) {
      final daysInMonth = DateUtils.getDaysInMonth(_weekStart.year, _weekStart.month);
      return List.generate(daysInMonth, (i) => DateTime(_weekStart.year, _weekStart.month, i + 1));
    }
    return List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  }

  // Days after applying "minimize empty days" filter
  List<DateTime> get _weekDays {
    if (!_minimizeEmpty || _shifts.isEmpty) return _allDays;
    final shiftDates = _shifts.map((s) => s.dateIso).toSet();
    return _allDays.where((d) {
      final isoKey =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return shiftDates.contains(isoKey);
    }).toList();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final rangeStart = _showEntireMonth
          ? DateTime(_weekStart.year, _weekStart.month, 1)
          : _weekStart;
      final rangeEnd = _showEntireMonth
          ? DateTime(_weekStart.year, _weekStart.month,
              DateUtils.getDaysInMonth(_weekStart.year, _weekStart.month))
          : _weekEnd;
      final from = rangeStart.toIso8601String().split('T')[0];
      final to   = rangeEnd.toIso8601String().split('T')[0];
      // Fetch shifts and school holidays for the visible range together.
      final results = await Future.wait([
        ApiClient.instance.get('/api/shifts?from=$from&to=$to&limit=100'),
        ApiClient.instance
            .get('/api/absences/school-holidays?year=${_weekStart.year}')
            .catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      final rawShifts = (data['data'] as List<dynamic>?) ?? [];
      final hData = results[1] is Map<String, dynamic>
          ? results[1] as Map<String, dynamic>
          : <String, dynamic>{};
      final rawHolidays = (hData['data'] as List<dynamic>?) ?? [];
      setState(() {
        _shifts   = rawShifts.map((s) {
          final m = s as Map<String, dynamic>;
          return _Shift(
            id:       m['id']     as String? ?? '',
            dateIso:  (m['date']  as String? ?? '').split('T').first,
            start:    _hhmm(m['startTime'] as String?),
            end:      _hhmm(m['endTime']   as String?),
            breakMin: (m['breakMinutes'] as num? ?? 0).toInt(),
            role:     m['role']   as String? ?? '',
          );
        }).toList();
        _holidays = rawHolidays
            .map((h) => _Holiday.fromJson(h as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      // silently keep empty state
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Employee requests to give up / swap one of their shifts. Releases it to
  /// the open pool on approval (no specific target colleague for now).
  Future<void> _requestSwap(_Shift s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   const Text('Request shift swap'),
        content: Text('Request to give up your shift on ${s.dateIso} '
            '(${s.start}–${s.end})? A manager must approve it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Request')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiClient.instance.post('/api/shifts/${s.id}/swap-request', data: {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Swap request sent to your manager'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static TimeOfDay? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Employee proposes new start/end times for their own shift; a manager
  /// approves via the change-request review flow.
  Future<void> _requestChange(_Shift s) async {
    final newStart = await showTimePicker(
      context: context,
      initialTime: _parseTime(s.start) ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'New start time',
    );
    if (newStart == null || !mounted) return;
    final newEnd = await showTimePicker(
      context: context,
      initialTime: _parseTime(s.end) ?? const TimeOfDay(hour: 17, minute: 0),
      helpText: 'New end time',
    );
    if (newEnd == null || !mounted) return;
    try {
      await ApiClient.instance.post('/api/shifts/${s.id}/change-request', data: {
        'proposedStartTime': '${s.dateIso}T${_two(newStart.hour)}:${_two(newStart.minute)}:00.000Z',
        'proposedEndTime':   '${s.dateIso}T${_two(newEnd.hour)}:${_two(newEnd.minute)}:00.000Z',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Change request sent to your manager'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _prevWeek() {
    setState(() {
      _weekStart   = _weekStart.subtract(const Duration(days: 7));
      _selectedDay = _weekStart;
    });
    _load();
  }

  void _nextWeek() {
    setState(() {
      _weekStart   = _weekStart.add(const Duration(days: 7));
      _selectedDay = _weekStart;
    });
    _load();
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettingsSheet(
        showMonth:    _showEntireMonth,
        minimizeEmpty: _minimizeEmpty,
        onShowMonth:   (v) { setState(() => _showEntireMonth = v); _load(); },
        onMinimize:    (v) => setState(() => _minimizeEmpty   = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      body: Column(
        children: [
          _buildHeader(cs),
          Expanded(
            child: _MyScheduleTab(
              weekDays:    _weekDays,
              selectedDay: _selectedDay,
              shifts:      _shifts,
              holidays:    _holidays,
              loading:     _loading,
              onSelectDay: (d) => setState(() => _selectedDay = d),
              onRequestSwap: _requestSwap,
              onRequestChange: _requestChange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    final cw   = _cwLabel(_weekStart);
    final year = _weekStart.year;
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'Inter'),
                  children: [
                    TextSpan(
                      text: '$cw ',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                    TextSpan(
                      text: '$year',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w400,
                          color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white70, size: 22),
                onPressed: _showSettings,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              _NavButtons(onPrev: _prevWeek, onNext: _nextWeek),
            ],
          ),
        ),
      ),
    );
  }

}

// ── Nav buttons ────────────────────────────────────────────────────────────────

class _NavButtons extends StatelessWidget {
  const _NavButtons({required this.onPrev, required this.onNext});
  final VoidCallback onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
          Container(width: 1, height: 32, color: Colors.white54),
          _NavBtn(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

// ── "My Schedule" tab ──────────────────────────────────────────────────────────

class _MyScheduleTab extends StatelessWidget {
  const _MyScheduleTab({
    required this.weekDays,
    required this.selectedDay,
    required this.shifts,
    required this.holidays,
    required this.loading,
    required this.onSelectDay,
    required this.onRequestSwap,
    required this.onRequestChange,
  });

  final List<DateTime>     weekDays;
  final DateTime           selectedDay;
  final List<_Shift>       shifts;
  final List<_Holiday>     holidays;
  final bool               loading;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<_Shift>   onRequestSwap;
  final ValueChanged<_Shift>   onRequestChange;

  void _showShiftActions(BuildContext context, _Shift s) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Request swap'),
              onTap: () { Navigator.pop(ctx); onRequestSwap(s); },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('Request change'),
              onTap: () { Navigator.pop(ctx); onRequestChange(s); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final now = DateTime.now();

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: weekDays.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
      itemBuilder: (_, i) {
        final d       = weekDays[i];
        final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
        final isSelected = d.year == selectedDay.year &&
            d.month == selectedDay.month && d.day == selectedDay.day;
        final isoKey  = '${d.year.toString().padLeft(4,'0')}-'
            '${d.month.toString().padLeft(2,'0')}-'
            '${d.day.toString().padLeft(2,'0')}';
        final dayShifts = shifts.where((s) => s.dateIso == isoKey).toList();
        final hasShift  = dayShifts.isNotEmpty;
        String? holidayName;
        for (final h in holidays) {
          if (h.covers(d)) { holidayName = h.name; break; }
        }

        return InkWell(
          onTap: () => onSelectDay(d),
          child: Container(
            // Tint shift days and the selected row, and mark shift days with a
            // left accent border. (A bordered container avoids the unbounded-
            // height issue a stretched Row stripe causes inside a ListView.)
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : hasShift
                      ? AppColors.primary.withValues(alpha: 0.04)
                      : cs.surface,
              border: Border(
                left: BorderSide(
                  width: 4,
                  color: hasShift ? AppColors.primary : Colors.transparent,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day label
                SizedBox(
                  width: 52,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE', Intl.defaultLocale ?? 'en').format(d).replaceAll('.', '').toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: (isToday || hasShift)
                              ? AppColors.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        DateFormat((Intl.defaultLocale ?? 'en').startsWith('de') ? 'd. MMM' : 'MMM d', Intl.defaultLocale ?? 'en').format(d),
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Shift chips, holiday badge, or a muted placeholder
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasShift)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: dayShifts.map((s) => GestureDetector(
                            onTap: () => _showShiftActions(context, s), // tap for swap/change actions
                            child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${s.start} – ${s.end}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))).toList(),
                        )
                      else if (holidayName == null)
                        Text('No shift',
                            style: AppTextStyles.caption.copyWith(
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.6))),
                      // School-holiday badge (shown even alongside a shift).
                      if (holidayName != null)
                        Padding(
                          padding: EdgeInsets.only(top: hasShift ? 4 : 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.celebration_outlined,
                                    size: 13, color: Color(0xFF16A34A)),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    holidayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFF16A34A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasShift)
                  Container(
                    margin: const EdgeInsets.only(top: 4, left: 6),
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Settings sheet ─────────────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({
    required this.showMonth,
    required this.minimizeEmpty,
    required this.onShowMonth,
    required this.onMinimize,
  });

  final bool showMonth, minimizeEmpty;
  final ValueChanged<bool> onShowMonth, onMinimize;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late bool _showMonth, _minimizeEmpty;

  @override
  void initState() {
    super.initState();
    _showMonth     = widget.showMonth;
    _minimizeEmpty = widget.minimizeEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          SwitchListTile(
            value: _showMonth,
            onChanged: (v) {
              widget.onShowMonth(v);
              Navigator.pop(context);
            },
            title: Text('Show entire month',
                style: TextStyle(fontSize: 15, color: cs.onSurface)),
            activeThumbColor: AppColors.primary,
          ),
          Divider(height: 1, indent: 16, color: cs.outline.withValues(alpha: 0.2)),
          SwitchListTile(
            value: _minimizeEmpty,
            onChanged: (v) {
              widget.onMinimize(v);
              Navigator.pop(context);
            },
            title: Text('Minimize empty days',
                style: TextStyle(fontSize: 15, color: cs.onSurface)),
            activeThumbColor: AppColors.primary,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
