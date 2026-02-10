import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Interactive map preview widget showing the workplace location
/// Features a pulsing animation to indicate the work zone radius
/// and a refresh button to update the user's current location
/// 
/// The widget uses different colors to indicate whether the user
/// is within (blue) or outside (amber) the work zone
class LocationMapPreview extends StatefulWidget {
  /// Whether the user is currently within the work zone
  final bool isWithinWorkZone;
  
  /// Whether location is currently being fetched
  final bool isLoadingLocation;
  
  /// The user's current GPS position (if available)
  final Position? currentPosition;
  
  /// Callback function when the refresh button is tapped
  final VoidCallback onRefresh;

  const LocationMapPreview({
    super.key,
    required this.isWithinWorkZone,
    required this.isLoadingLocation,
    this.currentPosition,
    required this.onRefresh,
  });

  @override
  State<LocationMapPreview> createState() => _LocationMapPreviewState();
}

class _LocationMapPreviewState extends State<LocationMapPreview> 
    with SingleTickerProviderStateMixin {
  /// Animation controller for the pulsing geofence circle
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
  }

  /// Initialize the pulse animation that repeats continuously
  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Continuous repeat for smooth pulsing effect
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 280,
      decoration: _buildMapBackgroundDecoration(),
      child: Stack(
        children: [
          // Dark gradient overlay for better contrast
          _buildGradientOverlay(),
          
          // Pulsing geofence circle
          _buildPulsingGeofence(),
          
          // Center workplace marker
          _buildWorkplaceMarker(),
          
          // User position indicator (when outside work zone)
          if (!widget.isWithinWorkZone && widget.currentPosition != null)
            _buildUserPositionMarker(),
          
          // Refresh location button
          _buildRefreshButton(),
        ],
      ),
    );
  }

  /// Builds the map background with image
  BoxDecoration _buildMapBackgroundDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      image: const DecorationImage(
        // Using a generic office/city image as placeholder
        image: NetworkImage(
          'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
        ),
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds a gradient overlay for better text/icon visibility
  Widget _buildGradientOverlay() {
    return Container(
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
    );
  }

  /// Builds the animated pulsing circle representing the geofence
  Widget _buildPulsingGeofence() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // Calculate pulse effect: grows from 200 to 220 and fades out
          final pulseValue = _pulseController.value;
          final size = 200 + (pulseValue * 20);
          final opacity = 0.6 - (pulseValue * 0.3);
          
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getGeofenceColor().withOpacity(opacity),
                width: 3,
              ),
              color: _getGeofenceColor().withOpacity(0.1),
            ),
          );
        },
      ),
    );
  }

  /// Builds the central workplace marker icon
  Widget _buildWorkplaceMarker() {
    return Center(
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _getGeofenceColor(),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getGeofenceColor().withOpacity(0.5),
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
    );
  }

  /// Builds a small marker showing the user's position when outside work zone
  Widget _buildUserPositionMarker() {
    return Positioned(
      top: 60,
      right: 60,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB), // Blue for user position
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.5),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the refresh/my location button
  Widget _buildRefreshButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onTap: widget.isLoadingLocation ? null : widget.onRefresh,
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
          child: widget.isLoadingLocation
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2563EB),
                    ),
                  ),
                )
              : const Icon(
                  Icons.my_location,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
        ),
      ),
    );
  }

  /// Returns the appropriate color based on work zone status
  /// Blue if within zone, amber if outside
  Color _getGeofenceColor() {
    return widget.isWithinWorkZone 
        ? const Color(0xFF2563EB) // Blue
        : const Color(0xFFF59E0B); // Amber
  }
}