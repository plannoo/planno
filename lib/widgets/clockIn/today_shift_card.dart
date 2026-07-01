import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/shift_model.dart';

/// Compact card showing today's scheduled shift at the top of the clock screen.
/// Shows a "no shift" placeholder when [shift] is null.
class TodayShiftCard extends StatelessWidget {
  const TodayShiftCard({super.key, this.shift, this.onViewDetails});

  final ShiftModel?   shift;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs   = Theme.of(context).colorScheme;

    if (shift == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:        cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border:       Border.all(color: cs.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color:        cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.work_outline_rounded,
                  color: cs.onSurfaceVariant, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clockTodaysShiftLabel,
                    style: AppTextStyles.overline.copyWith(
                      color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.noShiftsDay,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        // Theme-aware tint so the card stays legible in dark mode (was a fixed
        // light-blue background with near-black text).
        color:        AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border:       Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_outline_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.clockTodaysShiftLabel,
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.primary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  shift!.role,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: cs.onSurface, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.access_time_outlined,
                        size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(shift!.timeRange,
                        style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    const SizedBox(width: 10),
                    Icon(Icons.location_on_outlined,
                        size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(shift!.location,
                          style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12, color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onViewDetails,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:        AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
