import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

// Widget imports
import '../widgets/location_map_preview.dart';
import '../widgets/location_card.dart';
import '../widgets/today_shift_card.dart'; // Avoid name conflicts
import '../widgets/recent_activity.dart';
import '../widgets/on_duty_status.dart';

// Model imports
import '../models/workplace_location.dart';
import '../models/activity_model.dart';
import '../models/shift_model.dart';

/// Main time clock screen for employee attendance tracking
/// 
/// Features:
/// - Real-time location tracking with geofencing
/// - Clock in/out functionality with location verification
/// - Session time tracking
/// - Activity history
/// - Shift information display
/// 
/// The screen enforces geofencing for clock-in (must be within work zone)
/// but allows clock-out from anywhere for flexibility
class TimeClockScreen extends StatefulWidget {
  const TimeClockScreen({super.key});

  @override
  State<TimeClockScreen> createState() => _TimeClockScreenState();
}

class _TimeClockScreenState extends State<TimeClockScreen> 
    with SingleTickerProviderStateMixin {
  
  // ========== STATE VARIABLES ==========
  
  /// Whether the employee is currently clocked in
  bool _isOnDuty = false;
  
  /// Whether the employee is within the workplace geofence zone
  bool _isWithinWorkZone = false;
  
  /// Duration of the current work session
  Duration _sessionTime = const Duration(hours: 6, minutes: 15, seconds: 22);
  
  /// Timer for updating session time every second
  Timer? _timer;
  
  /// Animation controller for UI pulse effects
  late AnimationController _pulseController;
  
  // ========== GEOLOCATION VARIABLES ==========
  
  /// Current GPS position of the employee
  Position? _currentPosition;
  
  /// Distance from the workplace in meters
  double _distanceFromWorkplace = 0.0;
  
  /// Whether location is currently being fetched
  bool _isLoadingLocation = true;
  
  /// Error message if location fetch fails
  String _locationError = '';
  
  // ========== WORKPLACE CONFIGURATION ==========
  
  /// Workplace location configuration
  /// In a production app, this would be loaded from a database or API
  final WorkplaceLocation _workplace = const WorkplaceLocation(
    name: 'Main Office, Berlin',
    address: 'Friedrichstraße 123, 10117 Berlin',
    latitude: 52.5200,
    longitude: 13.4050,
    geofenceRadiusMeters: 200.0,  // 200m radius from workplace
    gpsBufferMeters: 10.0,        // 10m buffer for GPS inaccuracy
  );

  // ========== LIFECYCLE METHODS ==========

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _checkLocationPermissionAndGetLocation();
    
    // Start timer if already on duty (e.g., returning to screen)
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

  // ========== INITIALIZATION METHODS ==========

  /// Initialize the pulse animation for UI effects
  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  // ========== LOCATION PERMISSION & FETCHING ==========

  /// Check location permissions and fetch current location
  /// This is called on initialization and handles all permission states
  Future<void> _checkLocationPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled on the device
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Location services are disabled. Please enable them in settings.';
      });
      return;
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if not yet asked
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location permission denied. Please grant permission in settings.';
        });
        return;
      }
    }

    // Handle permanently denied permission
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Location permissions are permanently denied. Please enable them in settings.';
      });
      return;
    }

    // Permission granted, fetch location
    await _getCurrentLocation();
  }

  /// Fetch current GPS location and calculate distance from workplace
  Future<void> _getCurrentLocation() async {
    try {
      // Get high-accuracy position with 10-second timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Calculate straight-line distance to workplace
      final distanceInMeters = _workplace.distanceTo(position);

      setState(() {
        _currentPosition = position;
        _distanceFromWorkplace = distanceInMeters;
        _isWithinWorkZone = _workplace.isWithinWorkZone(position);
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

  /// Refresh location manually when user taps the refresh button
  Future<void> _refreshLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    await _getCurrentLocation();
  }

  // ========== TIMER METHODS ==========

  /// Start the session timer (increments every second)
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sessionTime = _sessionTime + const Duration(seconds: 1);
        });
      }
    });
  }

  /// Stop the session timer
  void _stopTimer() {
    _timer?.cancel();
  }

  // ========== FORMATTING METHODS ==========

  /// Format duration as HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  /// Format distance for display (e.g., "150m" or "1.5km")
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    }
  }

  // ========== CLOCK IN/OUT HANDLERS ==========

  /// Handle clock-in action
  /// REQUIRES the user to be within the work zone
  Future<void> _handleClockIn() async {
    // Geofencing check: only allow clock-in if within work zone
    if (!_isWithinWorkZone) {
      _showLocationWarningDialog();
      return;
    }
    
    setState(() {
      _isOnDuty = true;
      _sessionTime = Duration.zero;
    });
    
    _startTimer();

    // Save clock-in event to database
    await _saveClockInToDatabase(
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      distance: _distanceFromWorkplace,
      accuracy: _currentPosition?.accuracy,
    );

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Clocked in successfully! (${_formatDistance(_distanceFromWorkplace)} from workplace)',
          ),
          backgroundColor: const Color(0xFF22C55E),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle clock-out action
  /// ALWAYS allowed regardless of location for flexibility
  /// Location is captured for record-keeping but doesn't block the action
  Future<void> _handleClockOut() async {
    setState(() {
      _isOnDuty = false;
    });
    
    _stopTimer();

    // Attempt to capture location for record-keeping
    Position? clockOutPosition;
    double? clockOutDistance;
    double? clockOutAccuracy;
    String locationStatus = 'success';
    String locationNote = '';

    try {
      // Use medium accuracy and shorter timeout for clock-out
      clockOutPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      clockOutDistance = _workplace.distanceTo(clockOutPosition);
      clockOutAccuracy = clockOutPosition.accuracy;
      locationStatus = 'success';
      locationNote = 'Location captured successfully';
      
    } on TimeoutException {
      locationStatus = 'timeout';
      locationNote = 'GPS timeout - user may be indoors or in poor signal area';
      
    } catch (e) {
      // Categorize the error for better logging
      if (e.toString().contains('location service')) {
        locationStatus = 'service_disabled';
        locationNote = 'Location services disabled';
      } else if (e.toString().contains('permission')) {
        locationStatus = 'permission_denied';
        locationNote = 'Location permission not granted';
      } else {
        locationStatus = 'error';
        locationNote = 'Error: ${e.toString()}';
      }
    }

    // Save clock-out event to database with detailed status
    await _saveClockOutToDatabase(
      latitude: clockOutPosition?.latitude,
      longitude: clockOutPosition?.longitude,
      distance: clockOutDistance,
      accuracy: clockOutAccuracy,
      locationStatus: locationStatus,
      locationNote: locationNote,
    );

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            clockOutPosition != null
                ? 'Clocked out successfully! (${_formatDistance(clockOutDistance!)} from workplace)'
                : 'Clocked out successfully! (Location: $locationStatus)',
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ========== DATABASE OPERATIONS ==========
  // These would interact with your backend API or local database

  /// Save clock-in event to database
  /// In a real app, this would make an API call or database insert
  Future<void> _saveClockInToDatabase({
    double? latitude,
    double? longitude,
    double? distance,
    double? accuracy,
  }) async {
    // TODO: Implement actual database save
    // Example:
    // await apiService.saveClockIn(
    //   timestamp: DateTime.now(),
    //   latitude: latitude,
    //   longitude: longitude,
    //   distance: distance,
    //   accuracy: accuracy,
    // );
    
    debugPrint('Clock-in saved: lat=$latitude, lon=$longitude, distance=$distance');
  }

  /// Save clock-out event to database with detailed location status
  Future<void> _saveClockOutToDatabase({
    double? latitude,
    double? longitude,
    double? distance,
    double? accuracy,
    required String locationStatus,
    required String locationNote,
  }) async {
    // TODO: Implement actual database save
    // Example:
    // await apiService.saveClockOut(
    //   timestamp: DateTime.now(),
    //   latitude: latitude,
    //   longitude: longitude,
    //   distance: distance,
    //   accuracy: accuracy,
    //   locationStatus: locationStatus,
    //   locationNote: locationNote,
    // );
    
    debugPrint('Clock-out saved: status=$locationStatus, note=$locationNote');
  }

  // ========== DIALOG METHODS ==========

  /// Show warning dialog when user tries to clock in outside work zone
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
          'You must be within ${_workplace.geofenceRadiusMeters.toInt()}m of the workplace to clock in.\n\n'
          'Current distance: ${_formatDistance(_distanceFromWorkplace)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshLocation();
            },
            child: const Text('Refresh Location'),
          ),
        ],
      ),
    );
  }

  // ========== UI BUILD METHODS ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light gray background
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Show error message if location fetch failed
              if (_locationError.isNotEmpty)
                _buildLocationError(),
              
              // Duty status badge or clock-in button
              if (_isOnDuty)
                const OnDutyStatus()
              else
                _buildLocationStatus(),
              
              const SizedBox(height: 24),
              
              // Session timer or map preview
              if (_isOnDuty)
                _buildSessionTimer()
              else
                _buildLocationMapPreview(),
              
              const SizedBox(height: 24),
              
              // Action buttons (clock in/out, break)
              if (_isOnDuty)
                _buildActionButtons()
              else ...[
                _buildLocationCard(),
                const SizedBox(height: 16),
                if (!_isWithinWorkZone && _currentPosition != null)
                  _buildLocationOverrideButton(),
                const SizedBox(height: 16),
                _buildClockInButton(),
              ],
              
              const SizedBox(height: 24),
              _buildLocationDisclaimer(),
              const SizedBox(height: 24),
              
              // Today's shift information
              _buildTodayShiftCard(),
              const SizedBox(height: 16),
              
              // Recent activity list
              _buildRecentActivity(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the app bar with title and potential menu
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Time Clock',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF0F172A)),
        onPressed: () {
          // TODO: Open navigation drawer
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A)),
          onPressed: () {
            // TODO: Open notifications
          },
        ),
      ],
    );
  }

  /// Build location error message widget
  Widget _buildLocationError() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2), // Light red background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _locationError,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build session timer display
  Widget _buildSessionTimer() {
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

  /// Build action buttons (break and clock out)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Start Break button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement break functionality
              },
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
          
          // Clock Out button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleClockOut,
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

  /// Build location map preview widget
  Widget _buildLocationMapPreview() {
    return LocationMapPreview(
      isWithinWorkZone: _isWithinWorkZone,
      isLoadingLocation: _isLoadingLocation,
      currentPosition: _currentPosition,
      onRefresh: _refreshLocation,
    );
  }

  /// Build location card widget
  Widget _buildLocationCard() {
    return LocationCard(
      workplace: _workplace,
      isWithinWorkZone: _isWithinWorkZone,
      distanceText: _currentPosition != null 
          ? _formatDistance(_distanceFromWorkplace) 
          : null,
    );
  }

  /// Build location status indicator
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
            color: _isWithinWorkZone 
                ? const Color(0xFF22C55E) 
                : const Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isWithinWorkZone 
                  ? 'You are within the work zone'
                  : 'You are outside the work zone',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isWithinWorkZone 
                    ? const Color(0xFF22C55E) 
                    : const Color(0xFFF59E0B),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build location override request button
  Widget _buildLocationOverrideButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton.icon(
        onPressed: _showOverrideRequestDialog,
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

  /// Show dialog for requesting location override
  void _showOverrideRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Override'),
        content: const Text(
          'Send a location override request to your manager? '
          'They will be notified and can approve your clock-in remotely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Send override request to manager
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Override request sent to manager'),
                  backgroundColor: Color(0xFF2563EB),
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  /// Build clock-in button
  Widget _buildClockInButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: _isLoadingLocation ? null : _handleClockIn,
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
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  /// Build location disclaimer text
  Widget _buildLocationDisclaimer() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Clock In: Must be within work zone.\n'
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

  /// Build today's shift card
  Widget _buildTodayShiftCard() {
    return TodayShiftCard(
      onViewDetails: () {
        // TODO: Navigate to shift details
        debugPrint('View shift details tapped');
      },
    );
  }

  /// Build recent activity widget
  Widget _buildRecentActivity() {
    return const RecentActivity();
  }
}