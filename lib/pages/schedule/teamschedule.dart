import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import 'create_shift_page.dart';

/// Formats an ISO datetime (shift startTime/endTime) to a local HH:MM label.
String _hhmm(String? iso) {
  if (iso == null || iso.isEmpty) return '--:--';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '--:--';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Formats a shift's "HH:MM"-"HH:MM" start/end (plus optional break minutes)
/// into a duration label like "8h" or "7h 30m". Handles overnight shifts.
String _shiftDuration(String? start, String? end, num? breakMinutes) {
  final s = _parseHhMm(start);
  final e = _parseHhMm(end);
  if (s == null || e == null) return '--';
  var minutes = e - s;
  if (minutes < 0) minutes += 24 * 60; // overnight shift
  minutes -= (breakMinutes ?? 0).toInt();
  if (minutes < 0) minutes = 0;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

int? _parseHhMm(String? hhmm) {
  if (hhmm == null || !hhmm.contains(':')) return null;
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

// â”€â”€ Main Page (3 tabs) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class TeamSchedulePage extends StatefulWidget {
  const TeamSchedulePage({super.key});

  @override
  State<TeamSchedulePage> createState() => _TeamSchedulePageState();
}

class _TeamSchedulePageState extends State<TeamSchedulePage> {
  int _tab = 0; // 0=My Schedule, 1=Day plan, 2=Week plan

  static const _tabs = ['My Schedule', 'Day plan', 'Week plan'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // This page doubles as a root bottom-nav tab (navigation_shell.dart) and
    // as a pushed sub-page (e.g. from the dashboard's "Open shifts" row) â€” it
    // needs a back button only in the latter case, so this is decided by
    // Navigator.canPop rather than a constructor flag.
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      body: SafeArea(
        child: Column(
        children: [
          if (canPop)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                _MyScheduleTab(),
                _DayPlanTab(),
                _WeekPlanTab(),
              ],
            ),
          ),

          // â”€â”€ Bottom tab row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            color: cs.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                Padding(
                  padding: EdgeInsets.only(
                      top: 8,
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_tabs.length, (i) {
                      final active = i == _tab;
                      return GestureDetector(
                        onTap: () => setState(() => _tab = i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                              color: active ? AppColors.primary : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// â”€â”€ Shared: week header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

int _isoWeek(DateTime d) {
  final startOfYear = DateTime(d.year, 1, 1);
  final dayOfYear = d.difference(startOfYear).inDays + 1;
  final wday = d.weekday; // 1=Mon
  return ((dayOfYear - wday + 10) ~/ 7);
}

DateTime _startOfWeek(DateTime d) {
  return d.subtract(Duration(days: d.weekday - 1));
}


// â”€â”€ MY SCHEDULE TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MyScheduleTab extends StatefulWidget {
  const _MyScheduleTab();

  @override
  State<_MyScheduleTab> createState() => _MyScheduleTabState();
}

class _MyScheduleTabState extends State<_MyScheduleTab> {
  late DateTime _weekStart;
  List<Map<String, dynamic>> _shifts = [];
  bool _loading = false;
  String _location = '';
  bool _showEntireMonth   = false;
  bool _minimizeEmptyDays = false;

  @override
  void initState() {
    super.initState();
    _weekStart = _startOfWeek(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // All days for the current view (week or full month)
  List<DateTime> get _allDays {
    if (_showEntireMonth) {
      final daysInMonth = DateUtils.getDaysInMonth(_weekStart.year, _weekStart.month);
      return List.generate(daysInMonth, (i) => DateTime(_weekStart.year, _weekStart.month, i + 1));
    }
    return List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  }

  // Days after applying "minimize empty days" filter
  List<DateTime> get _viewDays {
    if (!_minimizeEmptyDays || _shifts.isEmpty) return _allDays;
    final shiftDates = _shifts
        .map((s) => (s['date'] as String? ?? '').split('T').first)
        .toSet();
    return _allDays.where((d) {
      final isoKey =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return shiftDates.contains(isoKey);
    }).toList();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final monthStart = DateTime(_weekStart.year, _weekStart.month, 1);
      final monthEnd   = DateTime(_weekStart.year, _weekStart.month,
          DateUtils.getDaysInMonth(_weekStart.year, _weekStart.month));
      final from = (_showEntireMonth ? monthStart : _weekStart)
          .toIso8601String().split('T')[0];
      final to   = (_showEntireMonth ? monthEnd : _weekStart.add(const Duration(days: 6)))
          .toIso8601String().split('T')[0];
      // "My Schedule" = the signed-in user's own shifts (the original intent).
      final data = await ApiClient.instance.get(
          '/api/shifts?from=$from&to=$to&limit=100') as Map<String, dynamic>;
      if (!mounted) return;
      final raw = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
      // Normalise the backend shape (startTime/endTime + nested user) to the
      // flat start/end/name fields this view reads.
      final normalised = raw.map((s) {
        final user = s['user'] as Map<String, dynamic>?;
        final name = user == null
            ? ''
            : '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
        return {
          ...s,
          'start': _hhmm(s['startTime'] as String?),
          'end':   _hhmm(s['endTime']   as String?),
          'name':  name,
        };
      }).toList();
      setState(() {
        _shifts   = normalised;
        _location = data['location'] as String? ?? '';
      });
    } catch (_) {
      if (mounted) setState(() { _shifts = []; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevWeek() { setState(() { _weekStart = _weekStart.subtract(const Duration(days: 7)); _load(); }); }
  void _nextWeek() { setState(() { _weekStart = _weekStart.add(const Duration(days: 7)); _load(); }); }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleSettingsSheet(
        showMonth:     _showEntireMonth,
        minimizeEmpty: _minimizeEmptyDays,
        onShowMonth:   (v) { setState(() => _showEntireMonth = v); _load(); },
        onMinimize:    (v) => setState(() => _minimizeEmptyDays = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cw = _isoWeek(_weekStart);
    final today = DateTime.now();
    final days = _viewDays;

    return Column(
      children: [
        // â”€â”€ Blue CW header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text.rich(TextSpan(children: [
                    const TextSpan(
                      text: 'CW ',
                      style: TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: '$cw',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: '  ${_weekStart.year}',
                      style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w400),
                    ),
                  ])),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
                    onPressed: _showSettings,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  _NavButtons(onPrev: _prevWeek, onNext: _nextWeek),
                ],
              ),
            ),
          ),
        ),

        // â”€â”€ Location banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_location.isNotEmpty)
          Container(
            width: double.infinity,
            color: cs.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Plan not published for: $_location',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),

        // â”€â”€ Days list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: days.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                    itemBuilder: (_, i) {
                      final day   = days[i];
                      final isToday = day.year == today.year &&
                                      day.month == today.month &&
                                      day.day == today.day;
                      final dayShifts = _shifts.where((s) {
                        final d = s['date'] as String? ?? '';
                        return d.startsWith(day.toIso8601String().split('T')[0]);
                      }).toList();

                      return _WeekDayRow(
                        day: day,
                        isToday: isToday,
                        shifts: dayShifts,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _WeekDayRow extends StatelessWidget {
  const _WeekDayRow({required this.day, required this.isToday, required this.shifts});
  final DateTime day;
  final bool     isToday;
  final List<Map<String, dynamic>> shifts;

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final locale  = Intl.defaultLocale ?? 'en';
    final abbrev  = DateFormat('EEE', locale).format(day).replaceAll('.', '').toUpperCase();
    final date    = DateFormat(locale.startsWith('de') ? 'd. MMM' : 'MMM d', locale).format(day);

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  abbrev,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isToday ? AppColors.primary : cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Shift chips
          Expanded(
            child: shifts.isEmpty
                ? const SizedBox.shrink()
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: shifts.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${s['start'] ?? ''} â€“ ${s['end'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ DAY PLAN TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DayPlanTab extends StatefulWidget {
  const _DayPlanTab();

  @override
  State<_DayPlanTab> createState() => _DayPlanTabState();
}

class _DayPlanTabState extends State<_DayPlanTab> {
  late DateTime _weekStart;
  late DateTime _selectedDay;
  List<Map<String, dynamic>> _allShifts = []; // unfiltered from API
  List<Map<String, dynamic>> _shifts    = []; // filtered by location
  List<Map<String, dynamic>> _absences   = [];
  List<Map<String, dynamic>> _allEmployees = []; // unfiltered from API
  List<Map<String, dynamic>> _employees  = []; // filtered by location
  int _absentCount     = 0;
  bool _loading        = false;
  bool _employeesLoading = false;
  bool _isPublished    = false;
  String _location     = '';
  bool _absentExpanded = false;
  final Set<String> _collapsedRoles = {};

  // Palette for role-group headers (cycles by group order), Ã  la the Wrenta app.
  static const List<Color> _rolePalette = [
    Color(0xFFEF4444), // red
    Color(0xFFF97316), // orange
    Color(0xFFF59E0B), // amber
    Color(0xFF84CC16), // lime
    Color(0xFF22C55E), // green
    Color(0xFFFB7185), // blue
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart   = _startOfWeek(now);
    _selectedDay = now;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d    = _selectedDay.toIso8601String().split('T')[0];
      final locParam = _location.isNotEmpty && _location != 'Alle Standorte'
          ? '&location=${Uri.encodeQueryComponent(_location)}' : '';
      final wrap = await ApiClient.instance
          .get('/api/dashboard/schedule/day-plan?date=$d$locParam') as Map<String, dynamic>;
      final data = (wrap['data'] ?? wrap) as Map<String, dynamic>;
      if (!mounted) return;
      _allShifts = List<Map<String, dynamic>>.from(data['shifts'] as List? ?? []);
      if (_location.isEmpty) _location = data['locationName'] as String? ?? '';
      _applyLocationFilter();
      setState(() {
        _absences    = List<Map<String, dynamic>>.from(data['absences'] as List? ?? []);
        _absentCount = (data['absentCount'] as num? ?? 0).toInt();
        _isPublished = data['published'] as bool? ?? false;
      });
      _loadEmployees();
    } catch (_) {
      if (mounted) setState(() { _allShifts = []; _shifts = []; _absences = []; _absentCount = 0; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyLocationFilter() {
    if (_location.isEmpty || _location == 'Alle Standorte') {
      _shifts = List.from(_allShifts);
      _employees = List.from(_allEmployees);
      return;
    }
    final filtered = _allShifts.where((s) {
      final loc = s['location'] as String? ?? '';
      return loc == _location;
    }).toList();
    _shifts = filtered.isEmpty ? List.from(_allShifts) : filtered;
    _employees = _allEmployees.where((e) {
      final firstName = e['firstName'] as String? ?? '';
      final lastName = e['lastName'] as String? ?? '';
      final name = '$firstName $lastName'.trim();
      return _shifts.any((s) => (s['employeeName'] as String? ?? '') == name);
    }).toList();
  }

  Future<void> _loadEmployees() async {
    setState(() => _employeesLoading = true);
    try {
      final data = await ApiClient.instance.get('/api/users?limit=200');
      final raw = data is List ? data : (data as Map<String, dynamic>)['data'] as List? ?? [];
      if (mounted) {
        _allEmployees = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _applyLocationFilter();
        setState(() {});
      }
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _employeesLoading = false);
    }
  }

  void _showSwitch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSwitchSheet(
        selected: _location,
        onSelect: (loc) {
          // _load() re-fetches from the server with the new location as a
          // query param. _allShifts is already scoped to whatever location
          // was active at the last fetch, so re-filtering it client-side
          // (the old behavior) just filtered an already-filtered list down
          // to nothing and silently fell back to showing the stale data â€”
          // i.e. switching locations appeared to do nothing.
          setState(() => _location = loc);
          _load();
        },
      ),
    );
  }

  void _showPublish() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PublishSheet(
          cw: _isoWeek(_weekStart), weekStart: _weekStart, location: _location),
    ).then((published) {
      if (published == true) _load(); // refresh so the banner shows "published"
    });
  }

  void _showDaySettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DayPlanSettingsSheet(),
    );
  }

  void _selectDay(DateTime d) {
    setState(() => _selectedDay = d);
    _load();
  }

  void _prevWeek() {
    setState(() { _weekStart = _weekStart.subtract(const Duration(days: 7)); });
    _load();
  }

  void _nextWeek() {
    setState(() { _weekStart = _weekStart.add(const Duration(days: 7)); });
    _load();
  }

  String get _selectedDayLabel {
    final locale = Intl.defaultLocale ?? 'en';
    final isDE = locale.startsWith('de');
    return DateFormat(isDE ? 'EEE d. MMM' : 'EEE, MMM d', locale).format(_selectedDay);
  }

  int get _cwNum => _isoWeek(_weekStart);

  /// Groups the day's shifts by role and renders a colored, collapsible
  /// header per role (role name + count) with the shift rows underneath.
  /// Open (unassigned) shifts get their own prominent group at the top.
  List<Widget> _buildRoleGroups(ColorScheme cs) {
    final open   = <Map<String, dynamic>>[];
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final s in _shifts) {
      final isOpen = (s['employeeName'] as String? ?? '').trim().isEmpty;
      if (isOpen) { open.add(s); continue; }
      final r = (s['role'] as String?)?.trim();
      final role = (r == null || r.isEmpty) ? 'Unassigned' : r;
      groups.putIfAbsent(role, () => []).add(s);
    }

    // Render open shifts first, under a dedicated dark "OPEN SHIFTS" header.
    final ordered = <MapEntry<String, List<Map<String, dynamic>>>>[
      if (open.isNotEmpty) MapEntry('Open shifts', open),
      ...groups.entries,
    ];

    final widgets = <Widget>[];
    var i = 0;
    for (final entry in ordered) {
      final role  = entry.key;
      final items = entry.value;
      final isOpenGroup = role == 'Open shifts';
      final color     = isOpenGroup
          ? const Color(0xFF334155) // slate â€” distinct from role colors
          : _rolePalette[i % _rolePalette.length];
      final collapsed = _collapsedRoles.contains(role);
      widgets.add(Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            // Colored role header
            Material(
              color: color,
              child: InkWell(
                onTap: () => setState(() {
                  if (collapsed) {
                    _collapsedRoles.remove(role);
                  } else {
                    _collapsedRoles.add(role);
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(collapsed ? Icons.chevron_right : Icons.expand_more,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(role.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700,
                                fontSize: 14, letterSpacing: 0.3)),
                      ),
                      Text('${items.length}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
            if (!collapsed)
              for (int j = 0; j < items.length; j++) ...[
                if (j > 0) Divider(height: 1, color: cs.outline.withValues(alpha: 0.15)),
                _groupedShiftRow(cs, items[j]),
              ],
          ],
        ),
      ));
      if (!isOpenGroup) i++;
    }
    return widgets;
  }

  Widget _groupedShiftRow(ColorScheme cs, Map<String, dynamic> s) {
    final start = s['start'] as String? ?? '--:--';
    final end   = s['end']   as String? ?? '--:--';
    final brk   = (s['break'] as num?)?.toInt() ?? 0;
    final name  = s['employeeName'] as String? ?? '';
    final label = (s['label'] as String?)?.trim();
    final locText = (label != null && label.isNotEmpty) ? label : _location;
    final unassigned = name.isEmpty;
    final shiftId = s['id'] as String?;

    return InkWell(
      // Admins and managers can tap a shift to edit it.
      onTap: shiftId == null ? null : () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateShiftPage(
            date:         _selectedDay,
            location:     _location,
            shiftId:      shiftId,
            initialStart: start,
            initialEnd:   end,
          ),
        ),
      ).then((_) => _load()),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Time + break
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$start â€“ $end',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('/ $brk',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  if (unassigned) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Icon(Icons.priority_high,
                          size: 11, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Spacer(),
          // Employee + location
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(unassigned ? 'Open shift' : name,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: unassigned ? AppColors.error : cs.onSurface)),
              if (locText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(locText,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // â”€â”€ Blue header: day selector â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Row: < MO DI MI ... SO >
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      _ArrowBtn(icon: Icons.chevron_left, onTap: _prevWeek),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (i) {
                            final day     = _weekStart.add(Duration(days: i));
                            final abbrev  = DateFormat('EEE', Intl.defaultLocale ?? 'en').format(day).replaceAll('.', '').toUpperCase();
                            final isActive = day.year == _selectedDay.year &&
                                             day.month == _selectedDay.month &&
                                             day.day == _selectedDay.day;
                            return GestureDetector(
                              onTap: () => _selectDay(day),
                              child: Container(
                                width: 40,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  border: isActive
                                      ? Border.all(color: Colors.white, width: 2)
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(abbrev,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                          color: isActive ? Colors.white : Colors.white70,
                                        )),
                                    Text('${day.day}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                          color: isActive ? Colors.white : Colors.white70,
                                        )),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      _ArrowBtn(icon: Icons.chevron_right, onTap: _nextWeek),
                    ],
                  ),
                ),

                // Second row: "Mo 22. Juni" + location pill + gear
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        _selectedDayLabel,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _showSwitch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                              _location.isEmpty || _location == 'Alle Standorte'
                                  ? l10n.scheduleAllLocations
                                  : _location,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showDaySettings,
                        child: const Icon(Icons.settings_outlined,
                            color: Colors.white70, size: 22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Not published banner
                      if (!_isPublished)
                        GestureDetector(
                          onTap: _showPublish,
                          child: Container(
                            color: cs.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.visibility_off_outlined,
                                    size: 18, color: AppColors.error),
                                const SizedBox(width: 8),
                                Text(
                                  'CW $_cwNum not published',
                                  style: const TextStyle(fontSize: 14, color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Shifts grouped by role (colored headers + counts), or empty
                      if (_shifts.isEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('No shifts',
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                          ),
                        )
                      else
                        ..._buildRoleGroups(cs),
                      const SizedBox(height: 8),

                      // Employees at this location
                      if (_employeesLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))),
                        )
                      else if (_employees.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                                child: Text('Employees at location (${_employees.length})',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                        color: cs.onSurface)),
                              ),
                              ..._employees.take(20).map((e) {
                                final name = ('${e['firstName'] ?? ''} ${e['lastName'] ?? ''}').trim();
                                final role = e['role'] as String? ?? '';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 18, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(name,
                                            style: TextStyle(fontSize: 13, color: cs.onSurface)),
                                      ),
                                      Text(role.toUpperCase(),
                                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                    ],
                                  ),
                                );
                              }),
                              if (_employees.length > 20)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                                  child: Text('+ ${_employees.length - 20} more',
                                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Absent employees expandable
                      if (_absentCount > 0)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _absentExpanded = !_absentExpanded),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(Icons.event_busy_outlined,
                                          size: 20, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 12),
                                      Text('Absent employees: $_absentCount',
                                          style: TextStyle(fontSize: 14, color: cs.onSurface)),
                                      const Spacer(),
                                      Icon(_absentExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                          color: cs.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              ),
                              if (_absentExpanded) ...[
                                Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                                ..._absences.map((a) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        child: Text(a['dateLabel'] as String? ?? '',
                                            style: TextStyle(
                                                fontSize: 12, color: cs.onSurfaceVariant)),
                                      ),
                                      Expanded(
                                        child: Text(a['name'] as String? ?? '',
                                            style: TextStyle(
                                                fontSize: 13, color: cs.onSurface)),
                                      ),
                                      Text(a['type'] as String? ?? '',
                                          style: TextStyle(
                                              fontSize: 12, color: cs.onSurfaceVariant)),
                                    ],
                                  ),
                                )),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Create shift button (admins + managers)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateShiftPage(
                                  date: _selectedDay,
                                  location: _location,
                                ),
                              ),
                            ).then((_) => _load()),
                            icon: Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                            ),
                            label: Text('Create shift',
                                style: TextStyle(fontSize: 14, color: cs.onSurface)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: cs.outline),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// â”€â”€ WEEK PLAN TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WeekPlanTab extends StatefulWidget {
  const _WeekPlanTab();

  @override
  State<_WeekPlanTab> createState() => _WeekPlanTabState();
}

class _WeekPlanTabState extends State<_WeekPlanTab> {
  late DateTime _weekStart;
  // employees Ã— days grid: Map<employeeId, Map<dateIso, List<shift>>>
  List<_Employee>  _employees  = [];
  bool _loading    = false;
  bool _published  = false;
  String _location = 'Schweinfurt';
  // View prefs from the settings sheet.
  bool _hideWeekends = false;
  bool _hideSundays  = false;
  bool _hideEmpty    = false;
  bool _showTimes    = true;
  bool _showDuration = false;
  bool _showLabels   = false;

  @override
  void initState() {
    super.initState();
    _weekStart = _startOfWeek(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadViewPrefs();
      _load();
    });
  }

  Future<void> _loadViewPrefs() async {
    final r = await Future.wait([
      PrefsService.getViewBool('week_hide_weekends'),
      PrefsService.getViewBool('week_hide_sundays'),
      PrefsService.getViewBool('week_hide_empty'),
      PrefsService.getViewBool('week_show_times', fallback: true),
      PrefsService.getViewBool('week_show_duration'),
      PrefsService.getViewBool('week_show_labels'),
    ]);
    if (!mounted) return;
    setState(() {
      _hideWeekends = r[0]; _hideSundays = r[1]; _hideEmpty = r[2];
      _showTimes = r[3]; _showDuration = r[4]; _showLabels = r[5];
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final from = _weekStart.toIso8601String().split('T')[0];
      final locParam = _location.isNotEmpty && _location != 'Alle Standorte'
          ? '&location=${Uri.encodeQueryComponent(_location)}' : '';
      final data = await ApiClient.instance
          .get('/api/dashboard/schedule/week?date=$from$locParam') as Map<String, dynamic>;
      if (!mounted) return;
      final shifts = List<Map<String, dynamic>>.from(data['shifts'] as List? ?? []);
      _published   = data['published'] as bool? ?? false;
      if (_location.isEmpty) _location = data['locationName'] as String? ?? _location;

      // Build employee grid
      final Map<String, _Employee> empMap = {};
      for (final s in shifts) {
        final emp = s['employee'] as String? ?? 'Unknown';
        empMap.putIfAbsent(emp, () => _Employee(name: emp, cells: {}));
        final dateKey = (s['date'] as String? ?? '').substring(0, 10);
        empMap[emp]!.cells.putIfAbsent(dateKey, () => []).add(s);
      }
      setState(() => _employees = empMap.values.toList());
    } catch (_) {
      if (mounted) setState(() => _employees = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevWeek() { setState(() { _weekStart = _weekStart.subtract(const Duration(days: 7)); }); _load(); }
  void _nextWeek() { setState(() { _weekStart = _weekStart.add(const Duration(days: 7)); }); _load(); }

  void _showSwitch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSwitchSheet(
        selected: _location,
        onSelect: (r) {
          setState(() => _location = r);
          _load();
        },
      ),
    );
  }

  void _showPublish() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PublishSheet(
          cw: _isoWeek(_weekStart), weekStart: _weekStart, location: _location),
    ).then((published) {
      if (published == true) _load(); // refresh so the banner shows "published"
    });
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WeekSettingsSheet(),
    ).then((_) => _loadViewPrefs()); // re-apply toggles when the sheet closes
  }

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final cw   = _isoWeek(_weekStart);
    // Day count respects the "hide weekends / hide Sundays" toggles.
    final dayCount = _hideWeekends ? 5 : (_hideSundays ? 6 : 7);
    final days = List.generate(dayCount, (i) => _weekStart.add(Duration(days: i)));
    // "Hide empty" drops employees with no shifts in the visible week.
    final employees = _hideEmpty
        ? _employees.where((e) => e.cells.values.any((l) => l.isNotEmpty)).toList()
        : _employees;

    String dayHeader(DateTime d) {
      final abbrev = DateFormat('EEE', Intl.defaultLocale ?? 'en').format(d).replaceAll('.', '');
      final dd = d.day.toString().padLeft(2,'0');
      final mm = d.month.toString().padLeft(2,'0');
      return '$abbrev\n$dd.$mm';
    }

    return Column(
      children: [
        // â”€â”€ Blue CW header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Location chip
                  GestureDetector(
                    onTap: _showSwitch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                                _location == 'Alle Standorte'
                                    ? l10n.scheduleAllLocations
                                    : _location,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.filter_list, color: Colors.white70, size: 20),
                  const Spacer(),
                  Text.rich(TextSpan(children: [
                    const TextSpan(text: 'CW ', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    TextSpan(text: '$cw', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    TextSpan(text: '  ${_weekStart.year}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ])),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                    onPressed: _showSettings,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  _NavButtons(onPrev: _prevWeek, onNext: _nextWeek),
                ],
              ),
            ),
          ),
        ),

        // â”€â”€ "Not published" warning â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (!_published)
          GestureDetector(
            onTap: _showPublish,
            child: Container(
              width: double.infinity,
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  Icon(Icons.visibility_off_outlined, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('CW $cw not published',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),

        // â”€â”€ Grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // â”€â”€ Column headers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Row(
                        children: [
                          // "+" new open shift
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => CreateShiftPage(
                                  date: _weekStart, location: _location)))
                                .then((_) => _load()),
                            child: Container(
                              width: 110, height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                    right: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                                    bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
                              ),
                              child: Icon(Icons.add, color: AppColors.primary, size: 22),
                            ),
                          ),
                          ...days.map((d) => Container(
                            width: 64, height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: Border(
                                  left: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                                  bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
                            ),
                            child: Text(dayHeader(d),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface,
                                    height: 1.5)),
                          )),
                        ],
                      ),

                      // â”€â”€ Open Shifts row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Row(
                        children: [
                          Container(
                            width: 110, height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                                bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                              ),
                            ),
                            child: const Text('Open\nShifts',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.primary,
                                    fontWeight: FontWeight.w500)),
                          ),
                          ...days.map((_) => Container(
                            width: 64, height: 56,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: Border(
                                left: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                                bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                              ),
                            ),
                          )),
                        ],
                      ),

                      // â”€â”€ Employee rows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      ...employees.map((emp) => Row(
                        children: [
                          // Name cell
                          Container(
                            width: 110, height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border(
                                  right: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                                  bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
                            ),
                            child: Text(emp.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: cs.onSurface)),
                          ),
                          ...days.map((d) {
                            final key = d.toIso8601String().split('T')[0];
                            final cell = emp.cells[key] ?? [];
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => CreateShiftPage(
                                    date: d, location: _location)))
                                  .then((_) => _load()),
                              child: Container(
                                width: 64, height: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                      left: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                                      bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
                                ),
                                child: cell.isEmpty
                                    ? Icon(Icons.add, size: 16, color: cs.outline)
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: cell.map((s) {
                                          final label = (s['label'] as String?)?.trim();
                                          final lines = <String>[
                                            if (_showTimes)
                                              '${s['start'] ?? ''}-${s['end'] ?? ''}',
                                            if (_showDuration)
                                              _shiftDuration(s['start'] as String?,
                                                  s['end'] as String?, s['break'] as num?),
                                            if (_showLabels && label != null && label.isNotEmpty)
                                              label,
                                          ];
                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 1),
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: lines.map((t) => Text(
                                                t,
                                                style: const TextStyle(
                                                    fontSize: 9, color: AppColors.primary,
                                                    fontWeight: FontWeight.w500),
                                              )).toList(),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            );
                          }),
                        ],
                      )),

                      // â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      if (employees.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text('No shifts this week',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Employee {
  _Employee({required this.name, required this.cells});
  final String name;
  final Map<String, List<Map<String, dynamic>>> cells;
}

// â”€â”€ Shared small widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NavButtons extends StatelessWidget {
  const _NavButtons({required this.onPrev, required this.onNext});
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
      const SizedBox(width: 4),
      _NavBtn(icon: Icons.chevron_right, onTap: onNext),
    ],
  );
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData     icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white60),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({required this.icon, required this.onTap});
  final IconData     icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, color: Colors.white70, size: 28),
  );
}

// â”€â”€ Schedule Settings sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ScheduleSettingsSheet extends StatefulWidget {
  const _ScheduleSettingsSheet({
    required this.showMonth,
    required this.minimizeEmpty,
    required this.onShowMonth,
    required this.onMinimize,
  });

  final bool showMonth, minimizeEmpty;
  final ValueChanged<bool> onShowMonth, onMinimize;

  @override
  State<_ScheduleSettingsSheet> createState() => _ScheduleSettingsSheetState();
}

class _ScheduleSettingsSheetState extends State<_ScheduleSettingsSheet> {
  late final bool _showEntireMonth   = widget.showMonth;
  late final bool _minimizeEmptyDays = widget.minimizeEmpty;

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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text(
                    'Settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          // Toggles
          SwitchListTile(
            title: Text('Show entire month',
                style: TextStyle(fontSize: 15, color: cs.onSurface)),
            value: _showEntireMonth,
            onChanged: (v) {
              widget.onShowMonth(v);
              Navigator.pop(context);
            },
            activeThumbColor: AppColors.primary,
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          SwitchListTile(
            title: Text('Minimize empty days',
                style: TextStyle(fontSize: 15, color: cs.onSurface)),
            value: _minimizeEmptyDays,
            onChanged: (v) {
              widget.onMinimize(v);
              Navigator.pop(context);
            },
            activeThumbColor: AppColors.primary,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// â”€â”€ Location Switch sheet (fetches real locations from API) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LocationSwitchSheet extends StatefulWidget {
  const _LocationSwitchSheet({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  State<_LocationSwitchSheet> createState() => _LocationSwitchSheetState();
}

class _LocationSwitchSheetState extends State<_LocationSwitchSheet> {
  List<String> _all      = [];
  List<String> _filtered = [];
  bool _loading          = true;
  final _searchCtrl      = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() => _filtered = _all
          .where((l) => l.toLowerCase().contains(q))
          .toList());
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/api/locations');
      final List<dynamic> list = data is List ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      final names = list
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _all      = ['Alle Standorte', ...names];
          _filtered = _all;
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _all = ['Alle Standorte']; _filtered = _all; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                  ),
                  const Expanded(
                    child: Text('Switch',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                      itemBuilder: (_, i) {
                        final loc = _filtered[i];
                        return InkWell(
                          onTap: () { widget.onSelect(loc); Navigator.pop(context); },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Text(
                                loc == 'Alle Standorte' ? l10n.scheduleAllLocations : loc,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: loc == widget.selected
                                        ? AppColors.primary : cs.onSurface,
                                    fontWeight: loc == widget.selected
                                        ? FontWeight.w600 : FontWeight.w400)),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Publish weekly schedule sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PublishSheet extends StatefulWidget {
  const _PublishSheet({required this.cw, required this.weekStart, required this.location});
  final int      cw;
  final DateTime weekStart;
  final String   location;

  @override
  State<_PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends State<_PublishSheet> {
  bool _notify  = false;
  bool _loading = false;

  Future<void> _publish() async {
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post('/api/dashboard/schedule/publish', data: {
        'cw': widget.cw,
        'weekStart': widget.weekStart.toIso8601String().split('T').first,
        'location': widget.location,
        'notify': _notify,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom
              + MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Publish weekly schedule',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KW ${widget.cw}',
                    style: TextStyle(fontSize: 15, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text('Selected branch:',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(widget.location.isEmpty ? 'â€”' : widget.location,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 16),
                Text(
                  'By publishing the weekly plan, the shifts of this week become visible to the employees.',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 20),
                // Notify toggle in outlined box
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SwitchListTile(
                    dense: true,
                    title: Text('Notify employees',
                        style: TextStyle(fontSize: 15, color: cs.onSurface)),
                    value: _notify,
                    onChanged: (v) => setState(() => _notify = v),
                    activeThumbColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 24),
                // Publish button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _publish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Publish',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Week plan Settings sheet (6 toggles) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WeekSettingsSheet extends StatefulWidget {
  const _WeekSettingsSheet();

  @override
  State<_WeekSettingsSheet> createState() => _WeekSettingsSheetState();
}

class _WeekSettingsSheetState extends State<_WeekSettingsSheet> {
  bool _showTimes       = true;
  bool _showDuration    = false;
  bool _showLabels      = false;
  bool _hideEmpty       = false;
  bool _hideWeekends    = false;
  bool _hideSundays     = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final r = await Future.wait([
      PrefsService.getViewBool('week_show_times',    fallback: true),
      PrefsService.getViewBool('week_show_duration'),
      PrefsService.getViewBool('week_show_labels'),
      PrefsService.getViewBool('week_hide_empty'),
      PrefsService.getViewBool('week_hide_weekends'),
      PrefsService.getViewBool('week_hide_sundays'),
    ]);
    if (!mounted) return;
    setState(() {
      _showTimes    = r[0]; _showDuration = r[1]; _showLabels  = r[2];
      _hideEmpty    = r[3]; _hideWeekends = r[4]; _hideSundays = r[5];
    });
  }

  void _set(String key, bool value, void Function(bool) apply) {
    setState(() => apply(value));
    PrefsService.setViewBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget row(String label, bool val, ValueChanged<bool> cb) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(label, style: TextStyle(fontSize: 15, color: cs.onSurface)),
          value: val,
          onChanged: cb,
          activeThumbColor: AppColors.primary,
        ),
        Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
      ],
    );

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          row('Show shift times',             _showTimes,    (v) => _set('week_show_times',    v, (x) => _showTimes    = x)),
          row('Show shift duration',          _showDuration, (v) => _set('week_show_duration', v, (x) => _showDuration = x)),
          row('Show labels',                  _showLabels,   (v) => _set('week_show_labels',   v, (x) => _showLabels   = x)),
          row('Hide employees without shifts',_hideEmpty,    (v) => _set('week_hide_empty',    v, (x) => _hideEmpty    = x)),
          row('Hide weekends',                _hideWeekends, (v) => _set('week_hide_weekends', v, (x) => _hideWeekends = x)),
          SwitchListTile(
            title: Text('Hide Sundays', style: TextStyle(fontSize: 15, color: cs.onSurface)),
            value: _hideSundays,
            onChanged: (v) => _set('week_hide_sundays', v, (x) => _hideSundays = x),
            activeThumbColor: AppColors.primary,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// â”€â”€ Day plan Settings sheet ("Group by role" only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DayPlanSettingsSheet extends StatefulWidget {
  const _DayPlanSettingsSheet();

  @override
  State<_DayPlanSettingsSheet> createState() => _DayPlanSettingsSheetState();
}

class _DayPlanSettingsSheetState extends State<_DayPlanSettingsSheet> {
  bool _groupByRole = false;

  @override
  void initState() {
    super.initState();
    PrefsService.getViewBool('dayplan_group_by_role').then((v) {
      if (mounted) setState(() => _groupByRole = v);
    });
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          SwitchListTile(
            title: Text('Group by role',
                style: TextStyle(fontSize: 15, color: cs.onSurface)),
            value: _groupByRole,
            onChanged: (v) {
              setState(() => _groupByRole = v);
              PrefsService.setViewBool('dayplan_group_by_role', v);
            },
            activeThumbColor: AppColors.primary,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}
