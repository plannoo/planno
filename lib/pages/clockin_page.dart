import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class TimeClockScreen extends StatefulWidget {
  const TimeClockScreen({super.key});

  @override
  State<TimeClockScreen> createState() => _TimeClockScreenState();
}

class _TimeClockScreenState extends State<TimeClockScreen> with SingleTickerProviderStateMixin {
  bool _isOnDuty = false;
  bool _isWithinWorkZone = false;
  Duration _sessionTime = const Duration(hours: 6, minutes: 15, seconds: 22);
  Timer? _timer;
  late AnimationController _pulseController;
  
  // Geolocation variables
  Position? _currentPosition;
  double _distanceFromWorkplace = 0.0;
  bool _isLoadingLocation = true;
  String _locationError = '';
  
  // Workplace coordinates (Main Office, Berlin - example coordinates)
  static const double _workplaceLat = 52.5200;
  static const double _workplaceLon = 13.4050;
  static const double _geofenceRadiusMeters = 200.0;
  
  // GPS BUFFER: Add tolerance for GPS inaccuracy (10m buffer = 5% of radius)
  static const double _gpsBufferMeters = 10.0;
  static const double _effectiveRadiusMeters = _geofenceRadiusMeters + _gpsBufferMeters;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _checkLocationPermissionAndGetLocation();
    
    if (_isOnDuty) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // Check location permissions and get current location
  Future<void> _checkLocationPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Location services are disabled. Please enable them in settings.';
      });
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location permission denied. Please grant permission in settings.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Location permissions are permanently denied. Please enable them in settings.';
      });
      return;
    }

    // Get current location
    await _getCurrentLocation();
  }

  // Get current location and calculate distance
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Calculate distance from workplace
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _workplaceLat,
        _workplaceLon,
      );

      setState(() {
        _currentPosition = position;
        _distanceFromWorkplace = distanceInMeters;
        // Use EFFECTIVE RADIUS (includes GPS buffer) for zone check
        _isWithinWorkZone = distanceInMeters <= _effectiveRadiusMeters;
        _isLoadingLocation = false;
        _locationError = '';
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Failed to get location: ${e.toString()}';
      });
    }
  }

  // Refresh location
  Future<void> _refreshLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    await _getCurrentLocation();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sessionTime = _sessionTime + const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    }
  }

  // IMPROVED: Handle Clock In - REQUIRES location check
  Future<void> _handleClockIn() async {
    // Only check geofence for CLOCK IN
    if (!_isWithinWorkZone) {
      _showLocationWarningDialog();
      return;
    }
    
    setState(() {
      _isOnDuty = true;
      _sessionTime = Duration.zero;
      _startTimer();
    });

    // Save clock-in to database with location (always has location for clock-in)
    await _saveClockInToDatabase(
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      distance: _distanceFromWorkplace,
      accuracy: _currentPosition?.accuracy,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Clocked in successfully! (${_formatDistance(_distanceFromWorkplace)} from workplace)',
          ),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
    }
  }

  // ENHANCED: Handle Clock Out with detailed location status tracking
  Future<void> _handleClockOut() async {
    // Clock out is ALWAYS allowed, regardless of location
    setState(() {
      _isOnDuty = false;
      _stopTimer();
    });

    // Try to get current location for record-keeping, but don't block if it fails
    Position? clockOutPosition;
    double? clockOutDistance;
    double? clockOutAccuracy;
    String locationStatus = 'success';  // success, timeout, permission_denied, service_disabled, error
    String locationNote = '';

    try {
      // Use shorter timeout and medium accuracy for clock out
      clockOutPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      clockOutDistance = Geolocator.distanceBetween(
        clockOutPosition.latitude,
        clockOutPosition.longitude,
        _workplaceLat,
        _workplaceLon,
      );
      
      clockOutAccuracy = clockOutPosition.accuracy;
      locationStatus = 'success';
      locationNote = 'Location captured successfully';
      
    } on TimeoutException {
      locationStatus = 'timeout';
      locationNote = 'GPS timeout after 5 seconds - user may be indoors or in poor signal area';
      
    } catch (e) {
      // Categorize the specific error for better reporting
      if (e.toString().contains('location service')) {
        locationStatus = 'service_disabled';
        locationNote = 'Location services disabled on device';
      } else if (e.toString().contains('permission')) {
        locationStatus = 'permission_denied';
        locationNote = 'Location permission not granted';
      } else {
        locationStatus = 'error';
        locationNote = 'Error: ${e.toString()}';
      }
    }

    // ENHANCED: Save clock-out with detailed location status for manager review
    await _saveClockOutToDatabase(
      latitude: clockOutPosition?.latitude,
      longitude: clockOutPosition?.longitude,
      distance: clockOutDistance,
      accuracy: clockOutAccuracy,
      locationStatus: locationStatus,  // NEW: Status flag for managers
      locationNote: locationNote,       // NEW: Detailed note explaining why location might be missing
    );

    if (mounted) {
      String message;
      Color backgroundColor;
      
      switch (locationStatus) {
        case 'success':
          message = 'Clocked out successfully! (${_formatDistance(clockOutDistance!)} from workplace)';
          backgroundColor = const Color(0xFFEF4444);
          break;
        case 'timeout':
          message = 'Clocked out successfully! (Location unavailable - GPS timeout)';
          backgroundColor = const Color(0xFFF59E0B);
          break;
        case 'service_disabled':
          message = 'Clocked out successfully! (Location services disabled)';
          backgroundColor = const Color(0xFFF59E0B);
          break;
        case 'permission_denied':
          message = 'Clocked out successfully! (Location permission denied)';
          backgroundColor = const Color(0xFFF59E0B);
          break;
        default:
          message = 'Clocked out successfully! (Location unavailable)';
          backgroundColor = const Color(0xFFF59E0B);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ENHANCED: Clock-in database save with accuracy tracking
  Future<void> _saveClockInToDatabase({
    double? latitude,
    double? longitude,
    double? distance,
    double? accuracy,
  }) async {
    // Example: Save to Firebase, SQLite, or your backend
    final clockInData = {
      'type': 'clock_in',
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'distance_from_workplace': distance,
      'gps_accuracy': accuracy,
      'within_geofence': true,  // Always true for clock-in
      'workplace_lat': _workplaceLat,
      'workplace_lon': _workplaceLon,
      'geofence_radius': _geofenceRadiusMeters,
      'gps_buffer': _gpsBufferMeters,
    };
    
    print('Saving clock in: $clockInData');
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
  }

  // ENHANCED: Clock-out database save with status flags for manager review
  Future<void> _saveClockOutToDatabase({
    double? latitude,
    double? longitude,
    double? distance,
    double? accuracy,
    required String locationStatus,  // NEW: success, timeout, permission_denied, service_disabled, error
    required String locationNote,    // NEW: Human-readable explanation
  }) async {
    // Example: Save to Firebase, SQLite, or your backend
    final clockOutData = {
      'type': 'clock_out',
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'distance_from_workplace': distance,
      'gps_accuracy': accuracy,
      'location_status': locationStatus,  // NEW: Flag for managers to filter/review
      'location_note': locationNote,      // NEW: Explanation for audit trail
      'within_geofence': distance != null ? (distance <= _effectiveRadiusMeters) : null,
      'workplace_lat': _workplaceLat,
      'workplace_lon': _workplaceLon,
      'session_duration': _formatDuration(_sessionTime),
    };
    
    print('Saving clock out: $clockOutData');
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    // OPTIONAL: Log to separate table for manager review if location unavailable
    if (locationStatus != 'success') {
      print('⚠️ MANAGER ALERT: Clock out without location - Status: $locationStatus');
      // You could trigger a notification to managers here
    }
  }

  void _showLocationWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Outside Work Zone'),
          ],
        ),
        content: Text(
          'You are ${_formatDistance(_distanceFromWorkplace)} away from the workplace.\n\n'
          'You must be within ${_geofenceRadiusMeters.toInt()}m to clock in.\n\n'
          'Note: Clock out is allowed from anywhere.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle override request
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Override request sent to manager'),
                ),
              );
            },
            child: const Text('Request Override'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Time Clock',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF64748B)),
            onPressed: _isLoadingLocation ? null : _refreshLocation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // IMPROVED: Show warning only for clock-in (not when clocked in)
            if (!_isOnDuty && !_isWithinWorkZone && !_isLoadingLocation && _locationError.isEmpty) 
              _buildLocationWarning(),
            
            if (_locationError.isNotEmpty)
              _buildErrorBanner(),
            
            if (_isOnDuty) ...[
              const SizedBox(height: 24),
              _buildOnDutyStatus(),
              const SizedBox(height: 16),
              _buildTimer(),
              const SizedBox(height: 32),
              _buildActionButtons(),
              const SizedBox(height: 32),
              _buildTodayShiftCard(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ] else ...[
              const SizedBox(height: 40),
              _buildLocationMapPreview(),
              const SizedBox(height: 32),
              _buildLocationCard(),
              const SizedBox(height: 24),
              _buildLocationStatus(),
              const SizedBox(height: 32),
              if (!_isWithinWorkZone && !_isLoadingLocation)
                _buildLocationOverrideButton()
              else if (!_isLoadingLocation)
                _buildClockInButton(),
              const SizedBox(height: 16),
              _buildLocationDisclaimer(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFEF4444),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _locationError,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF59E0B),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are ${_formatDistance(_distanceFromWorkplace)} from the workplace. '
              'You must be within ${_geofenceRadiusMeters.toInt()}m to clock in. '
              'Clock out is allowed from anywhere.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnDutyStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'ON DUTY',
            style: TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          _formatDuration(_sessionTime),
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2563EB),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Current Session Time',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.coffee, size: 18),
              label: const Text(
                'Start Break',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleClockOut, // ENHANCED: Always works with detailed status tracking
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text(
                'Clock Out',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1497366216548-37526070297c?w=800'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Overlay gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Geofence circle (shows the effective radius with buffer)
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 200 + (_pulseController.value * 20),
                  height: 200 + (_pulseController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isWithinWorkZone 
                          ? const Color(0xFF2563EB).withOpacity(0.6 - (_pulseController.value * 0.3))
                          : const Color(0xFFF59E0B).withOpacity(0.6 - (_pulseController.value * 0.3)),
                      width: 3,
                    ),
                    color: _isWithinWorkZone
                        ? const Color(0xFF2563EB).withOpacity(0.1)
                        : const Color(0xFFF59E0B).withOpacity(0.1),
                  ),
                );
              },
            ),
          ),
          // Center marker
          Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isWithinWorkZone ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isWithinWorkZone ? const Color(0xFF2563EB) : const Color(0xFFF59E0B)).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.apartment,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          // User location dot (top right when outside zone)
          if (!_isWithinWorkZone && _currentPosition != null)
            Positioned(
              top: 60,
              right: 60,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          // Re-center button
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: _refreshLocation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.my_location,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.apartment,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Main Office, Berlin',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Friedrichstraße 123, 10117 Berlin',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_currentPosition != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Distance: ${_formatDistance(_distanceFromWorkplace)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isWithinWorkZone ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    if (_isLoadingLocation) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Getting your location...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isWithinWorkZone ? Icons.check_circle : Icons.warning,
            color: _isWithinWorkZone ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isWithinWorkZone 
                  ? 'You are within the work zone (${_geofenceRadiusMeters.toInt()}m + ${_gpsBufferMeters.toInt()}m GPS buffer)'
                  : 'You are outside the work zone (Clock in requires ${_geofenceRadiusMeters.toInt()}m range)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isWithinWorkZone ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOverrideButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton.icon(
        onPressed: () {
          // Show override request dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Request Override'),
              content: const Text(
                'Send a location override request to your manager?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Handle override request
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Override request sent to manager'),
                      ),
                    );
                  },
                  child: const Text('Send Request'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.location_searching, size: 20),
        label: const Text(
          'Request Location Override',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF59E0B),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 2),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildClockInButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: _handleClockIn, // IMPROVED: Checks geofence
        icon: const Icon(Icons.fingerprint, size: 24),
        label: const Text(
          'Clock In',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDisclaimer() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Clock In: Must be within 200m of workplace.\n'
        'Clock Out: Can be done from anywhere.\n\n'
        'Your location is recorded for attendance verification.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTodayShiftCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1497366216548-37526070297c?w=800'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FLOOR MANAGER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Today's Shift",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '09:00 AM - 05:00 PM',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFEFF6FF),
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Main Office, Berlin',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT ACTIVITY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildActivityItem(
            Icons.login,
            'Clock In',
            'Monday, Oct 23',
            '09:00 AM',
            const Color(0xFF22C55E),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            Icons.coffee,
            'Break Start',
            'Monday, Oct 23',
            '12:30 PM',
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String date,
    String time,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}