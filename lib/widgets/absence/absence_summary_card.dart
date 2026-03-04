import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/absence_summary.dart';

/// Quota card showing used / remaining / total absence days.
class AbsenceSummaryCard extends StatelessWidget {
  final AbsenceSummaryModel summary;
  const AbsenceSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCell(label: 'Used',      value: '${summary.usedDays}',      color: AppColors.primary),
              _StatCell(label: 'Remaining', value: '${summary.remainingDays}', color: AppColors.success),
              _StatCell(label: 'Total',     value: '${summary.totalDays}',     color: AppColors.slate400),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: summary.usagePercentage,
              minHeight: 8,
              backgroundColor: AppColors.slate100,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Valid until ${summary.formattedValidUntil}', style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, height: 1.1)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ],
  );
}