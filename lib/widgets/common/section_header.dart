import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A section heading row with an optional action link (e.g. "View all").
///
/// [uppercase] defaults to false — titles render in title-case as written.
/// Set [uppercase] to true for ALL-CAPS overline-style headers if needed.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.uppercase = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// When true the title is rendered in ALL CAPS with the overline style.
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          uppercase ? title.toUpperCase() : title,
          style: uppercase ? AppTextStyles.sectionLabel : AppTextStyles.h5,
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.withColor(
                AppTextStyles.labelMedium,
                AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}