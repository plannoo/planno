import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import '../../models/activity_model.dart';
import '../../models/work_location_model.dart';
import '../../repositories/clock_repository.dart';
import '../../core/utils/date_formatter.dart';

enum ClockStatus { idle, clockedIn, onBreak }

/// Manages all state for the time-clock feature:
///   - Clock in / out / break
///   - Live session timer
///   - Geolocation and work-zone checking
///   - Recent activity log
class ClockProvider extends ChangeNotifier {
  ClockProvider({required ClockRepository clockRepository})
      : _repo = clockRepository;

  final ClockRepository _repo;

  // ── Clock state ────────────────────────────────────────────────────────────
  ClockStatus _clockStatus = ClockStatus.idle;
  Duration    _sessionTime = Duration.zero;
  Timer?      _sessionTimer;
  DateTime?   _clockInTime;

  ClockStatus get clockStatus     => _clockStatus;
  Duration    get sessionTime     => _sessionTime;
  bool        get isOnDuty        => _clockStatus == ClockStatus.clockedIn;
  bool        get isOnBreak       => _clockStatus == ClockStatus.onBreak;
  String      get formattedSession => DateFormatter.formatDuration(_sessionTime);

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

  // ── Activity log ───────────────────────────────────────────────────────────
  final List<ActivityModel> _activities = [];
  List<ActivityModel> get activities => List.unmodifiable(_activities);

  // ── Workplace (static config; load from repository in production) ──────────
  static const WorkLocationModel workplace = WorkLocationModel(
    id: 1,
    name: 'Main Office, Berlin',
    address: 'Friedrichstraße 123, 10117 Berlin',
    locationCode: 'BER-01',
    latitude: 52.5200,
    longitude: 13.4050,
    geofenceRadiusMeters: 200.0,
    gpsBufferMeters: 10.0,
  );

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialise() => checkLocationPermissionAndFetch();

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
      return _setLocationError('Location permanently denied. Enable in settings.');
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
        timeLimit: const Duration(seconds: 10),
      );
      _currentPosition   = position;
      _distanceMeters    = workplace.distanceTo(position);
      _isWithinWorkZone  = workplace.isWithinWorkZone(position);
      _isLoadingLocation = false;
      _locationError     = null;
    } catch (e) {
      _isLoadingLocation = false;
      _locationError = 'Failed to get location: $e';
    }
    notifyListeners();
  }

  void _setLocationError(String message) {
    _isLoadingLocation = false;
    _locationError = message;
    notifyListeners();
  }

  // ── Clock actions ──────────────────────────────────────────────────────────

  /// Returns an error string if clock-in is blocked, null on success.
  Future<String?> clockIn() async {
    if (!_isWithinWorkZone) {
      return 'You must be within the work zone to clock in.';
    }

    _clockInTime = DateTime.now();
    _clockStatus = ClockStatus.clockedIn;
    _sessionTime = Duration.zero;
    _startSessionTimer();

    _addActivity(ActivityModel(
      id: _clockInTime!.millisecondsSinceEpoch.toString(),
      icon: const IconData(0xe3ab, fontFamily: 'MaterialIcons'), // login
      title: 'Clock In',
      date: _clockInTime!,
      time: _clockInTime!,
      color: const Color(0xFF22C55E),
      type: ActivityType.clockIn,
    ));

    await _repo.clockIn(
      latitude:              _currentPosition?.latitude,
      longitude:             _currentPosition?.longitude,
      distanceFromWorkplace: _distanceMeters,
      accuracy:              _currentPosition?.accuracy,
    );

    notifyListeners();
    return null;
  }

  Future<void> clockOut() async {
    _stopSessionTimer();
    _clockStatus = ClockStatus.idle;

    _addActivity(ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      icon: const IconData(0xe879, fontFamily: 'MaterialIcons'), // logout
      title: 'Clock Out',
      date: DateTime.now(),
      time: DateTime.now(),
      color: const Color(0xFFEF4444),
      type: ActivityType.clockOut,
    ));

    await _repo.clockOut(
      latitude:  _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      accuracy:  _currentPosition?.accuracy,
    );

    notifyListeners();
  }

  Future<void> startBreak() async {
    _stopSessionTimer();
    _clockStatus = ClockStatus.onBreak;

    _addActivity(ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      icon: const IconData(0xe1a5, fontFamily: 'MaterialIcons'), // coffee
      title: 'Break Started',
      date: DateTime.now(),
      time: DateTime.now(),
      color: const Color(0xFFF59E0B),
      type: ActivityType.breakStart,
    ));

    notifyListeners();
  }

  Future<void> endBreak() async {
    _clockStatus = ClockStatus.clockedIn;
    _startSessionTimer();

    _addActivity(ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      icon: const IconData(0xe1a5, fontFamily: 'MaterialIcons'), // coffee
      title: 'Break Ended',
      date: DateTime.now(),
      time: DateTime.now(),
      color: const Color(0xFF3B82F6),
      type: ActivityType.breakEnd,
    ));

    notifyListeners();
  }

  // ── Timer helpers ──────────────────────────────────────────────────────────

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionTime += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _stopSessionTimer() => _sessionTimer?.cancel();

  void _addActivity(ActivityModel activity) {
    _activities.insert(0, activity);
    if (_activities.length > 50) _activities.removeLast();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}