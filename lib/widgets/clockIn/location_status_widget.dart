import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Compact inline location status row.
///
/// Shows a pill with icon + text describing the user's proximity to the
/// workplace. All visible strings come from [AppLocalizations].
class LocationStatusWidget extends StatelessWidget {
  const LocationStatusWidget({
    super.key,
    required this.isLoading,
    required this.isWithinWorkZone,
    this.errorMessage,
    this.distanceText,
    this.onRefresh,
  });

  final bool         isLoading;
  final bool         isWithinWorkZone;
  final String?      errorMessage;
  final String?      distanceText;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isLoading) return _loadingPill(l10n);
    if (errorMessage != null) {
      return _pill(
        icon:  Icons.location_off_outlined,
        text:  errorMessage!,
        color: AppColors.error,
        bg:    AppColors.errorLight,
      );
    }

    // Build the status text — e.g. "Within work zone · 80m"
    final zoneText = isWithinWorkZone
        ? l10n.locationWithinZone +
            (distanceText != null ? ' · $distanceText' : '')
        : l10n.locationOutsideZone +
            (distanceText != null ? ' · $distanceText ${l10n.locationAway}' : '');

    return Row(
      children: [
        Expanded(
          child: _pill(
            icon:  isWithinWorkZone
                ? Icons.my_location_rounded
                : Icons.location_searching_rounded,
            text:  zoneText,
            color: isWithinWorkZone
                ? AppColors.success
                : AppColors.warning,
            bg:    isWithinWorkZone
                ? AppColors.successLight
                : AppColors.warningLight,
          ),
        ),
        if (onRefresh != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:        Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border:       Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const Icon(Icons.refresh_rounded,
                  size: 18, color: AppColors.slate500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _loadingPill(AppLocalizations l10n) => Container(
        height:  36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color:        AppColors.slate100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(l10n.clockGettingLocation,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.slate500)),
          ],
        ),
      );

  Widget _pill({
    required IconData icon,
    required String   text,
    required Color    color,
    required Color    bg,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: AppTextStyles.labelSmall.copyWith(
                    color: color, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}