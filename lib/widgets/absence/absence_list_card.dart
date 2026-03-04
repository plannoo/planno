import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/absence.dart';

/// Displays a single absence row. Set [isExpandable] for collapsible past items.
class AbsenceListCard extends StatelessWidget {
  final AbsenceModel absence;
  final bool showWorkingDays;
  final bool isExpandable;

  const AbsenceListCard({
    super.key,
    required this.absence,
    this.showWorkingDays = false,
    this.isExpandable = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = _CardContent(absence: absence);
    if (isExpandable) {
      return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: card,
        children: [
          if (absence.reason != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingMd, 0, AppDimensions.spacingMd, AppDimensions.spacingMd),
              child: Text(absence.reason!, style: AppTextStyles.bodySmall),
            ),
        ],
      );
    }

    return Column(
      children: [
        card,
        if (showWorkingDays)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, AppDimensions.spacingSm),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: AppDimensions.iconXs, color: AppColors.slate400),
                const SizedBox(width: 6),
                Text(
                  '${absence.workingDays} working day${absence.workingDays > 1 ? 's' : ''}',
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, size: AppDimensions.iconSm, color: AppColors.slate300),
              ],
            ),
          ),
      ],
    );
  }
}

class _CardContent extends StatelessWidget {
  final AbsenceModel absence;
  const _CardContent({required this.absence});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingXs),
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: absence.typeBackgroundColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(absence.typeIcon, color: absence.typeIconColor, size: AppDimensions.iconSm),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(absence.typeLabel, style: AppTextStyles.bodyBold),
                Text(absence.formattedDateRange, style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: absence.statusBackgroundColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              absence.statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: absence.statusTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}