import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/shift_model.dart';

/// A compact shift card for the "My Shifts" tab.
///
/// Intentionally smaller than [TeamMemberShiftCard] — shows just the
/// essential info: role, location, and time range in a tight single row.
class MyShiftCard extends StatelessWidget {
  const MyShiftCard({
    super.key,
    required this.shift,
    this.isToday = false,
    this.onTap,
  });

  final ShiftModel shift;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isToday ? AppColors.primaryLighter : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday ? AppColors.primaryLight : cs.outline.withValues(alpha: 0.3),
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: isToday
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Coloured left accent bar
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Role + location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.role,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isToday
                          ? AppColors.primary
                          : AppColors.slate800,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: AppColors.slate400,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          shift.location,
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Time range
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  shift.formattedStartTime,
                  style: AppTextStyles.captionBold.copyWith(
                    color: isToday ? AppColors.primary : AppColors.slate700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  shift.formattedEndTime,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}