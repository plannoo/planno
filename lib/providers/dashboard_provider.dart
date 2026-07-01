import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/network/api_exceptions.dart';
import '../models/shift_model.dart';
import '../repositories/shift_repository.dart';

enum DashboardLoadState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({required ShiftRepository shiftRepository})
      : _repo = shiftRepository;

  final ShiftRepository _repo;
  Timer? _pollTimer;

  DashboardLoadState _state              = DashboardLoadState.initial;
  ShiftModel?        _todayShift;
  double             _weeklyHours        = 0.0;
  double             _targetWeeklyHours  = 40.0;
  String?            _errorMessage;
  bool               _lastErrorWasAuth  = false;

  DashboardLoadState get state             => _state;
  ShiftModel?        get todayShift        => _todayShift;
  double             get weeklyHours       => _weeklyHours;
  double             get targetWeeklyHours => _targetWeeklyHours;
  String?            get errorMessage      => _errorMessage;
  bool               get isLoading         => _state == DashboardLoadState.loading;
  bool               get lastErrorWasAuth  => _lastErrorWasAuth;

  String greetingFor(String firstName) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    return '$salutation, $firstName';
  }

  Future<void> load() async {
    if (_state == DashboardLoadState.loading) return;
    _setState(DashboardLoadState.loading);
    try {
      _todayShift  = await _repo.getTodayShift();
      _weeklyHours = 32.5; // TODO: fetch from time-tracking repository
      _lastErrorWasAuth = false;
      _setState(DashboardLoadState.loaded);
      _startPolling();
    } catch (e) {
      _lastErrorWasAuth = e is UnauthorizedException;
      _errorMessage = e.toString();
      _setState(DashboardLoadState.error);
    }
  }

  /// Silent background refresh — does not set loading state so UI doesn't flicker.
  Future<void> refresh() async {
    try {
      final shift = await _repo.getTodayShift();
      _lastErrorWasAuth = false;
      if (shift?.id != _todayShift?.id || shift?.startTime != _todayShift?.startTime) {
        _todayShift = shift;
        notifyListeners();
      }
    } catch (e) {
      _lastErrorWasAuth = e is UnauthorizedException;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _setState(DashboardLoadState s) {
    _state = s;
    notifyListeners();
  }
}
