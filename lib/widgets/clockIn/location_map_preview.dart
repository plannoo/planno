import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Interactive map preview widget showing the workplace geofence.
///
/// This widget contains no hardcoded visible text strings â€” all visual
/// content is purely graphical (icons, colours, animation). No l10n changes
/// are required here.
class LocationMapPreview extends StatefulWidget {
  final bool      isWithinWorkZone;
  final bool      isLoadingLocation;
  final Position? currentPosition;
  final VoidCallback onRefresh;

  const LocationMapPreview({
    super.key,
    required this.isWithinWorkZone,
    required this.isLoadingLocation,
    this.currentPosition,
    required this.onRefresh,
  });

  @override
  State<LocationMapPreview> createState() =>
      _LocationMapPreviewState();
}

class _LocationMapPreviewState extends State<LocationMapPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),

          // Pulsing geofence circle
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, _) {
                final v       = _pulseController.value;
                final size    = 200 + (v * 20);
                final opacity = 0.6 - (v * 0.3);
                return Container(
                  width:  size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _geofenceColor.withValues(alpha: opacity),
                      width: 3,
                    ),
                    color: _geofenceColor.withValues(alpha: 0.1),
                  ),
                );
              },
            ),
          ),

          // Workplace marker
          Center(
            child: Container(
              width:  50,
              height: 50,
              decoration: BoxDecoration(
                color:  _geofenceColor,
                shape:  BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:       _geofenceColor.withValues(alpha: 0.5),
                    blurRadius:  20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.apartment,
                  color: Colors.white, size: 28),
            ),
          ),

          // User position marker (only when outside zone)
          if (!widget.isWithinWorkZone &&
              widget.currentPosition != null)
            Positioned(
              top: 60, right: 60,
              child: Container(
                width:  24,
                height: 24,
                decoration: BoxDecoration(
                  color:  const Color(0xFF2563EB),
                  shape:  BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color:      const Color(0xFF2563EB)
                          .withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),

          // Refresh button
          Positioned(
            bottom: 16, right: 16,
            child: GestureDetector(
              onTap: widget.isLoadingLocation ? null : widget.onRefresh,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:  Theme.of(context).colorScheme.surface,
                  shape:  BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: widget.isLoadingLocation
                    ? const SizedBox(
                        width:  24,
                        height: 24,
                        child:  CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2563EB)),
                        ),
                      )
                    : const Icon(Icons.my_location,
                        color: Color(0xFF2563EB), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _geofenceColor => widget.isWithinWorkZone
      ? const Color(0xFF2563EB)
      : const Color(0xFFF59E0B);
}