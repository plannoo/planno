import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/activity_model.dart';
import '../../widgets/common/section_header.dart';

/// List of recent clock-in/out activity entries.
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key, required this.activities});

  final List<ActivityModel> activities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title from l10n
        SectionHeader(title: l10n.recentActivityTitle),
        const SizedBox(height: AppDimensions.spacingMd),
        if (activities.isEmpty)
          _EmptyState()
        else
          ...activities.map((a) => _ActivityItem(activity: a)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border:       Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_toggle_off_outlined,
              size: 28, color: AppColors.slate300),
          const SizedBox(height: 8),
          Text(
            l10n.clockNoActivityToday,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.slate400),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity});

  final ActivityModel activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border:       Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width:  38,
            height: 38,
            decoration: BoxDecoration(
              color:        activity.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(activity.icon,
                color: activity.color, size: 18),
          ),
          const SizedBox(width: 12),

          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: AppTextStyles.bodyBold
                        .copyWith(fontSize: 14)),
                const SizedBox(height: 1),
                Text(activity.formattedDate,
                    style: AppTextStyles.caption),
              ],
            ),
          ),

          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              activity.formattedTime,
              style: AppTextStyles.captionBold.copyWith(
                color:    AppColors.slate600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}