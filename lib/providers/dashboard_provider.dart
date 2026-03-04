import 'package:flutter/foundation.dart';
import '../../../models/shift_model.dart';
import '../../../models/user_model.dart';
import '../../../repositories/shift_repository.dart';

enum DashboardLoadState { initial, loading, loaded, error }

/// Provides data consumed by the Dashboard screen:
///   - Greeting / user info (from AuthProvider via ProxyProvider or direct read)
///   - Today's shift card
///   - Weekly hours summary
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({required ShiftRepository shiftRepository})
      : _repo = shiftRepository;

  final ShiftRepository _repo;

  // ── State ──────────────────────────────────────────────────────────────────
  DashboardLoadState _state     = DashboardLoadState.initial;
  ShiftModel?        _todayShift;
  double             _weeklyHours      = 0.0;
  double             _targetWeeklyHours = 40.0;
  String?            _errorMessage;

  DashboardLoadState get state             => _state;
  ShiftModel?        get todayShift        => _todayShift;
  double             get weeklyHours       => _weeklyHours;
  double             get targetWeeklyHours => _targetWeeklyHours;
  String?            get errorMessage      => _errorMessage;
  bool               get isLoading         => _state == DashboardLoadState.loading;

  // ── Greeting ───────────────────────────────────────────────────────────────

  /// Returns an appropriate greeting based on the current hour.
  String greetingFor(String firstName) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    return '$salutation, $firstName';
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_state == DashboardLoadState.loading) return;
    _setState(DashboardLoadState.loading);
    try {
      _todayShift  = await _repo.getTodayShift();
      // TODO: fetch real weekly hours from a time-tracking repository
      _weeklyHours = 32.5;
      _setState(DashboardLoadState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(DashboardLoadState.error);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setState(DashboardLoadState s) {
    _state = s;
    notifyListeners();
  }
}