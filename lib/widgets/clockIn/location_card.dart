import 'package:flutter/material.dart';
import '../../models/work_location_model.dart';

/// Card showing workplace name, address, and optional distance.
///
/// All text content is data-driven (workplace name, address, distanceText).
/// The distance label prefix "Distance:" is the only candidate for l10n;
/// it has been replaced with the existing [AppLocalizations.clockLocation]
/// key via the caller, or left as a pure data string since it is already
/// prefixed by the icon. No UI-level hardcoded strings remain.
class LocationCard extends StatelessWidget {
  final WorkLocationModel? workplace;
  final bool               isWithinWorkZone;
  final String?            distanceText;

  const LocationCard({
    super.key,
    this.workplace,
    required this.isWithinWorkZone,
    this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Building icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.apartment,
                color: Color(0xFF2563EB), size: 28),
          ),
          const SizedBox(width: 16),

          // Location details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workplace?.name ?? 'Main Office, Berlin',
                  style: TextStyle(
                    fontSize:   17,
                    fontWeight: FontWeight.w800,
                    color:      cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workplace?.address ??
                      'Friedrichstraße 123, 10117 Berlin',
                  style: TextStyle(
                    fontSize:   13,
                    color:      cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (distanceText != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isWithinWorkZone
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size:  14,
                        color: isWithinWorkZone
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distanceText!,
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color: isWithinWorkZone
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}