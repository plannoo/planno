import 'package:flutter/material.dart';
import '../models/workplace_location.dart';

/// Widget that displays workplace location information in a card format
/// Shows the workplace name, address, and optional distance information
/// 
/// The card's styling changes based on whether the user is within the work zone
class LocationCard extends StatelessWidget {
  /// The workplace location to display
  final WorkplaceLocation? workplace;
  
  /// Whether the user is currently within the work zone
  final bool isWithinWorkZone;
  
  /// Optional distance text to display (e.g., "150m")
  final String? distanceText;

  const LocationCard({
    super.key,
    this.workplace,
    required this.isWithinWorkZone,
    this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Row(
        children: [
          // Building/workplace icon
          _buildLocationIcon(),
          const SizedBox(width: 16),
          
          // Location details
          Expanded(
            child: _buildLocationDetails(),
          ),
        ],
      ),
    );
  }

  /// Builds the card decoration with rounded corners and border
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFFF1F5F9), // Light gray border
      ),
      // Optional: Add subtle shadow for depth
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Builds the building/apartment icon with blue background
  Widget _buildLocationIcon() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE), // Light blue background
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.apartment,
        color: Color(0xFF2563EB), // Blue icon
        size: 28,
      ),
    );
  }

  /// Builds the location name, address, and optional distance
  Widget _buildLocationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location name (e.g., "Main Office, Berlin")
        Text(
          workplace?.name ?? 'Main Office, Berlin',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A), // Dark slate color
          ),
        ),
        const SizedBox(height: 4),
        
        // Full address
        Text(
          workplace?.address ?? 'Friedrichstraße 123, 10117 Berlin',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B), // Slate gray
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // Distance indicator (if available)
        if (distanceText != null) ...[
          const SizedBox(height: 8),
          _buildDistanceIndicator(),
        ],
      ],
    );
  }

  /// Builds the distance indicator with appropriate color
  /// Green if within work zone, amber if outside
  Widget _buildDistanceIndicator() {
    return Row(
      children: [
        Icon(
          isWithinWorkZone ? Icons.check_circle : Icons.info_outline,
          size: 14,
          color: isWithinWorkZone 
              ? const Color(0xFF22C55E) // Green
              : const Color(0xFFF59E0B), // Amber
        ),
        const SizedBox(width: 4),
        Text(
          'Distance: $distanceText',
          style: TextStyle(
            fontSize: 12,
            color: isWithinWorkZone 
                ? const Color(0xFF22C55E) // Green
                : const Color(0xFFF59E0B), // Amber
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}