import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../repositories/schedule_repository.dart';

enum ScheduleLoadState { initial, loading, loaded, error }

/// Drives the My Shifts view on the schedule screen.
///
/// Inject via [ChangeNotifierProxyProvider] in [AppProviders].
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider({required ScheduleRepository repository})
      : _repo = repository;

  final ScheduleRepository _repo;

  // ── Selected date ─────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    _loadMyShifts();
  }

  // ── My shifts ─────────────────────────────────────────────────────────────
  List<ShiftModel> _myShifts = [];
  List<ShiftModel> get myShifts => _myShifts;

  /// Shifts that fall on [selectedDate]
  List<ShiftModel> get myShiftsForSelectedDate => _myShifts
      .where((s) => DateUtils.isSameDay(s.date, _selectedDate))
      .toList();

  // ── Weekly hours ──────────────────────────────────────────────────────────

  /// Target hours per week (configurable; default 40 h).
  double get weeklyTargetHours => 40.0;

  /// Total logged hours (minus breaks) for the ISO week containing [selectedDate].
  double get weeklyHoursLogged {
    return _shiftsForSelectedWeek.fold(0.0, (sum, s) {
      final worked = s.duration.inMinutes - (s.breakMinutes ?? 0);
      return sum + worked / 60.0;
    });
  }

  /// Hours worked per day Mon(index 0) – Sun(index 6) for the selected week.
  List<double> get weeklyDailyHours {
    final weekStart = _mondayOf(_selectedDate);
    return List.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      return _myShifts
          .where((s) => DateUtils.isSameDay(s.date, day))
          .fold(0.0, (sum, s) => sum + s.duration.inMinutes / 60.0);
    });
  }

  /// Human-readable label for the selected week, e.g. "Oct 21 – Oct 27".
  String get weekRangeLabel {
    final start = _mondayOf(_selectedDate);
    final end   = start.add(const Duration(days: 6));
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final s = '${months[start.month - 1]} ${start.day}';
    final e = '${months[end.month - 1]} ${end.day}';
    return '$s – $e';
  }
   /// The Monday of the ISO week containing [selectedDate].
  DateTime get weekStart => _mondayOf(_selectedDate);
  /// Shifts for the ISO week containing [selectedDate].
  List<ShiftModel> get _shiftsForSelectedWeek {
    final weekStart = this.weekStart;
    final weekEnd   = weekStart.add(const Duration(days: 6));
    return _myShifts.where((s) =>
        !s.date.isBefore(weekStart) && !s.date.isAfter(weekEnd)).toList();
  }
  /// Returns shifts for any specific [date] — used by the bar chart breakdown.
  List<ShiftModel> shiftsForDay(DateTime date) =>
      _myShifts.where((s) => DateUtils.isSameDay(s.date, date)).toList();

  DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day)
          .subtract(Duration(days: d.weekday - 1));

  // ── Cancel-token support ──────────────────────────────────────────────────
  CancelToken? _cancelToken;

  // ── Load state ────────────────────────────────────────────────────────────
  ScheduleLoadState _state = ScheduleLoadState.initial;
  ScheduleLoadState get state => _state;
  bool get isLoading => _state == ScheduleLoadState.loading;
  String? _error;
  String? get error => _error;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> initialise() async {
    _setState(ScheduleLoadState.loading);
    try {
      await _loadMyShifts();
    } catch (e) {
      _error = e.toString();
      _setState(ScheduleLoadState.error);
    }
  }

  // ── Internal loaders ──────────────────────────────────────────────────────

  Future<void> _loadMyShifts() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    _setState(ScheduleLoadState.loading);
    try {
      _myShifts = await _repo.getMyShifts(_selectedDate,
          cancelToken: _cancelToken);
      if (_cancelToken?.isCancelled == true) return;
      _setState(ScheduleLoadState.loaded);
    } on CancelledError {
      // silently ignore — a newer request is already running
    } catch (e) {
      _error = e.toString();
      _setState(ScheduleLoadState.error);
    }
  }

  void _setState(ScheduleLoadState s) {
    _state = s;
    notifyListeners();
  }
}
