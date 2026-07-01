import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import '../core/network/api_exceptions.dart';
import '../models/activity_model.dart';
import '../models/work_location_model.dart';
import '../repositories/clock_repository.dart';
import '../core/utils/date_formatter.dart';

enum ClockStatus { idle, clockedIn, onBreak }

/// Manages clock-in / clock-out / break state, session timer, and geolocation.
///
/// Design decisions:
/// - All clock actions are **pessimistic**: state only mutates after the API
///   call succeeds. If the API throws, the state is rolled back and an error
///   is surfaced to the UI via [lastError].
/// - [isActionLoading] gates button taps so the user cannot double-submit.
/// - [workplace] is loaded from the repository, not hardcoded.
/// - Session time tracks only active (non-break) minutes. Break duration is
///   tracked separately via [breakTime].
class ClockProvider extends ChangeNotifier {
  ClockProvider({required ClockRepository clockRepository})
      : _repo = clockRepository;

  final ClockRepository _repo;

  // ── Clock state ────────────────────────────────────────────────────────────
  ClockStatus _clockStatus   = ClockStatus.idle;
  Duration    _sessionTime   = Duration.zero;
  Duration    _breakTime     = Duration.zero;
  Timer?      _sessionTimer;
  Timer?      _breakTimer;
  DateTime?   _clockInTime;

  ClockStatus get clockStatus      => _clockStatus;
  Duration    get sessionTime      => _sessionTime;
  Duration    get breakTime        => _breakTime;
  bool        get isOnDuty         => _clockStatus == ClockStatus.clockedIn;
  bool        get isOnBreak        => _clockStatus == ClockStatus.onBreak;
  String      get formattedSession => DateFormatter.formatDuration(_sessionTime);
  String      get formattedBreak   => DateFormatter.formatDuration(_breakTime);

  // ── Loading / error state ──────────────────────────────────────────────────

  /// True while any clock action (in/out/break) is awaiting the API.
  bool    _isActionLoading = false;
  String? _lastError;

  bool    get isActionLoading => _isActionLoading;
  String? get lastError       => _lastError;

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // ── Location state ─────────────────────────────────────────────────────────
  bool      _isLoadingLocation = true;
  bool      _isWithinWorkZone  = false;
  double    _distanceMeters    = 0.0;
  Position? _currentPosition;
  String?   _locationError;

  bool      get isLoadingLocation => _isLoadingLocation;
  bool      get isWithinWorkZone  => _isWithinWorkZone;
  double    get distanceMeters    => _distanceMeters;
  Position? get currentPosition   => _currentPosition;
  String?   get locationError     => _locationError;

  String? get formattedDistance => _currentPosition != null
      ? DateFormatter.formatDistance(_distanceMeters)
      : null;

  // ── Workplace config (loaded from repo, not hardcoded) ─────────────────────
  WorkLocationModel? _workplace;
  bool               _isLoadingWorkplace = true;
  String?            _workplaceError;
  Object?            _lastWorkplaceLoadError;

  WorkLocationModel? get workplace          => _workplace;
  bool               get isLoadingWorkplace  => _isLoadingWorkplace;
  String?            get workplaceError      => _workplaceError;
  bool               get workplaceAuthError => _lastWorkplaceLoadError is UnauthorizedException;

  // ── Activity log ───────────────────────────────────────────────────────────
  final List<ActivityModel> _activities = [];
  List<ActivityModel> get activities => List.unmodifiable(_activities);

  // ── Initialisation ──────────────────────────────────────────────────────────

  Future<void> initialise() async {
    await Future.wait([
      _loadWorkplace(),
      checkLocationPermissionAndFetch(),
    ]);

    // Restore clock state from today's server-side activities.
    // This handles app restart / page reload while clocked in or on break.
    if (_workplace != null) {
      await _restoreSessionState();
      notifyListeners();
    }
  }

  Future<void> _restoreSessionState() async {
    try {
      final session = await _repo.getCurrentSession();
      if (session.isEmpty) return;

      final isClockedIn = session['is_clocked_in'] == true;
      final isOnBreak   = session['is_on_break'] == true;

      if (isClockedIn) {
        final clockInAt = session['clock_in_at'] as String?;
        if (clockInAt != null) {
          _clockInTime = DateTime.parse(clockInAt);
          _sessionTime = DateTime.now().difference(_clockInTime!);
        }
        _clockStatus = ClockStatus.clockedIn;
        _startSessionTimer();
      }

      if (isOnBreak) {
        _clockStatus = ClockStatus.onBreak;
        final breakAt = session['break_started_at'] as String?;
        if (breakAt != null) {
          _breakTime = DateTime.now().difference(DateTime.parse(breakAt));
        }
        _startBreakTimer();
      }
    } catch (e) {
      debugPrint('[Clock] Could not restore session state: $e');
    }
  }

  Future<void> _loadWorkplace() async {
    _isLoadingWorkplace = true;
    _workplaceError = null;
    _lastWorkplaceLoadError = null;
    notifyListeners();

    // Retry once after a short delay: the first call can fail transiently while
    // a token refresh is in flight or the (cold-starting) backend is slow.
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        _workplace = await _repo.getWorkLocation();
        _workplaceError = null;
        lastError = null;
        break;
      } catch (e) {
        lastError = e;
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }
    }
    _lastWorkplaceLoadError = lastError;
    if (lastError != null) {
      _workplaceError = 'Could not load work location: $lastError';
    }
    _isLoadingWorkplace = false;
    notifyListeners();
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> checkLocationPermissionAndFetch() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    if (!await Geolocator.isLocationServiceEnabled()) {
      return _setLocationError('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _setLocationError('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return _setLocationError(
        'Location permanently denied. Please enable it in your device settings.',
      );
    }

    await fetchCurrentLocation();
  }

  Future<void> fetchCurrentLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _currentPosition = position;

      if (_workplace != null) {
        _distanceMeters   = _workplace!.distanceTo(position);
        _isWithinWorkZone = _workplace!.isWithinWorkZone(position);
      }

      _isLoadingLocation = false;
      _locationError = null;
    } on TimeoutException {
      _isLoadingLocation = false;
      _locationError = 'Location request timed out. Please try again.';
    } catch (e) {
      _isLoadingLocation = false;
      _locationError = 'Failed to get location: $e';
    }

    notifyListeners();
  }

  void _setLocationError(String msg) {
    _isLoadingLocation = false;
    _locationError = msg;
    notifyListeners();
  }

  // ── Clock actions ──────────────────────────────────────────────────────────
  //
  // Pattern for every action:
  //   1. Guard: reject if already loading or state is wrong.
  //   2. Snapshot previous state for rollback.
  //   3. Set loading flag.
  //   4. Call API.
  //   5a. On success → mutate state, add activity.
  //   5b. On failure → rollback snapshot, surface error.
  //   6. Clear loading flag, notify.

  /// Returns an error string if clock-in is blocked, null on success.
  /// [shiftId] is the specific shift to clock into. Without it the server may
  /// reject the request with "No active shift right now".
  Future<String?> clockIn({String? shiftId}) async {
    if (_isActionLoading) return null;

    // Self-heal: if the work location failed to load earlier (e.g. a cold-start
    // timeout), try once more here instead of dead-ending the user.
    if (_workplace == null) {
      await _loadWorkplace();
    }
    if (_workplace == null) {
      if (workplaceAuthError) {
        return 'Unauthorized: Your session has expired. Please log in again.';
      }
      return 'Work location could not be loaded. Pull to refresh or check '
          'your connection, then try again.';
    }
    // If we never got a GPS fix, attempt one now.
    if (_currentPosition == null && !_isLoadingLocation) {
      await checkLocationPermissionAndFetch();
    }
    if (_isLoadingLocation) {
      return 'Still fetching your location. Please wait.';
    }
    if (_locationError != null) {
      return 'Location unavailable: $_locationError';
    }
    if (!_isWithinWorkZone) {
      return 'You must be within the work zone to clock in '
          '(currently ${DateFormatter.formatDistance(_distanceMeters)} away).';
    }

    _setActionLoading(true);

    final previousStatus = _clockStatus;
    final previousClockInTime = _clockInTime;

    try {
      // Security: only send the raw GPS reading. The server must compute
      // distance from the workplace polygon itself — never trust a
      // client-supplied distance value.
      //
      // locationId pins the server's geofence check to the exact workplace
      // we already validated `_isWithinWorkZone` against. Without it the
      // server re-resolves "closest assigned location" independently and
      // can land on a different (or, when no assigned location is within
      // range, an arbitrary fallback) location — rejecting a clock-in the
      // client just showed as "within work zone".
      await _repo.clockIn(
        latitude:   _currentPosition?.latitude,
        longitude:  _currentPosition?.longitude,
        accuracy:   _currentPosition?.accuracy,
        shiftId:    shiftId,
        locationId: _workplace?.id,
      );

      // Only mutate state after API confirms success
      _clockInTime = DateTime.now();
      _clockStatus = ClockStatus.clockedIn;
      _sessionTime = Duration.zero;
      _breakTime   = Duration.zero;
      _startSessionTimer();
      _addActivity('Clock In', ActivityType.clockIn, const Color(0xFF22C55E));
      _lastError = null;
    } catch (e) {
      // Rollback
      _clockStatus  = previousStatus;
      _clockInTime  = previousClockInTime;
      _lastError    = 'Clock-in failed: $e';
    } finally {
      _setActionLoading(false);
    }

    return _lastError;
  }

  Future<String?> clockOut() async {
    if (_isActionLoading) return null;
    if (_clockStatus == ClockStatus.idle) return null;

    _setActionLoading(true);

    final previousStatus   = _clockStatus;
    final previousSession  = _sessionTime;
    final previousBreak    = _breakTime;
    final previousClockIn  = _clockInTime;

    // Stop timer optimistically (avoids it ticking during the API call),
    // but we restore it on failure.
    _stopSessionTimer();

    try {
      await _repo.clockOut(
        latitude:  _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        accuracy:  _currentPosition?.accuracy,
      );

      _clockStatus  = ClockStatus.idle;
      _clockInTime  = null;
      _lastError    = null;
      _addActivity('Clock Out', ActivityType.clockOut, const Color(0xFFEF4444));
    } catch (e) {
      // Rollback — resume timer if we were clocked in
      _clockStatus = previousStatus;
      _sessionTime = previousSession;
      _breakTime   = previousBreak;
      _clockInTime = previousClockIn;
      if (previousStatus == ClockStatus.clockedIn) _startSessionTimer();
      _lastError = 'Clock-out failed: $e';
    } finally {
      _setActionLoading(false);
    }

    return _lastError;
  }

  Future<String?> startBreak() async {
    if (_isActionLoading) return null;
    if (_clockStatus != ClockStatus.clockedIn) return null;

    _setActionLoading(true);
    _stopSessionTimer();

    final previousStatus = _clockStatus;

    try {
      await _repo.startBreak();

      _clockStatus = ClockStatus.onBreak;
      _startBreakTimer();
      _addActivity('Break Started', ActivityType.breakStart, const Color(0xFFF59E0B));
      _lastError = null;
    } catch (e) {
      // Rollback — resume work timer
      _clockStatus = previousStatus;
      _startSessionTimer();
      _lastError = 'Could not start break: $e';
    } finally {
      _setActionLoading(false);
    }

    return _lastError;
  }

  Future<String?> endBreak() async {
    if (_isActionLoading) return null;
    if (_clockStatus != ClockStatus.onBreak) return null;

    _setActionLoading(true);
    _stopSessionTimer(); // stops break timer (shared field)

    final previousStatus = _clockStatus;
    final previousBreak  = _breakTime;

    try {
      await _repo.endBreak();

      _clockStatus = ClockStatus.clockedIn;
      _startSessionTimer();
      _addActivity('Break Ended', ActivityType.breakEnd, const Color(0xFF3B82F6));
      _lastError = null;
    } catch (e) {
      // Rollback — resume break timer
      _clockStatus = previousStatus;
      _breakTime   = previousBreak;
      _startBreakTimer();
      _lastError = 'Could not end break: $e';
    } finally {
      _setActionLoading(false);
    }

    return _lastError;
  }

  /// Sends a location-override request to the manager.
  Future<String?> requestOverride({String? reason}) async {
    if (_isActionLoading) return null;
    _setActionLoading(true);

    try {
      await _repo.requestOverride(
        latitude:  _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        reason:    reason,
      );
      _lastError = null;
    } catch (e) {
      _lastError = 'Override request failed: $e';
    } finally {
      _setActionLoading(false);
    }

    return _lastError;
  }

  // ── Timers ──────────────────────────────────────────────────────────────────

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionTime += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _startBreakTimer() {
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _breakTime += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _breakTimer?.cancel();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _setActionLoading(bool value) {
    _isActionLoading = value;
    notifyListeners();
  }

  void _addActivity(String title, ActivityType type, Color color) {
    final now = DateTime.now();
    _activities.insert(
      0,
      ActivityModel(
        id:    now.millisecondsSinceEpoch.toString(),
        icon:  _iconFor(type),
        title: title,
        date:  now,
        time:  now,
        color: color,
        type:  type,
      ),
    );
    // Keep log bounded
    if (_activities.length > 50) _activities.removeLast();
  }

  IconData _iconFor(ActivityType t) => switch (t) {
    ActivityType.clockIn    => const IconData(0xe3ab, fontFamily: 'MaterialIcons'),
    ActivityType.clockOut   => const IconData(0xe879, fontFamily: 'MaterialIcons'),
    ActivityType.breakStart => const IconData(0xe1a5, fontFamily: 'MaterialIcons'),
    ActivityType.breakEnd   => const IconData(0xe1a5, fontFamily: 'MaterialIcons'),
    _                       => const IconData(0xe7ee, fontFamily: 'MaterialIcons'),
  };

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _breakTimer?.cancel();
    _breakTimer = null;
    super.dispose();
  }
}
