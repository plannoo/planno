import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Button with icon and text in a clean layout.
///
/// The [text] label is supplied by the caller as a localized string.
/// This widget contains no hardcoded visible text.
class IconTextButton extends StatelessWidget {
  final IconData   icon;
  final String     text;
  final VoidCallback? onPressed;
  final Color?     color;
  final Color?     backgroundColor;
  final double?    iconSize;

  const IconTextButton({
    super.key,
    required this.icon,
    required this.text,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size:  iconSize ?? AppDimensions.iconSm,
        color: color ?? AppColors.primary,
      ),
      label: Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(
            color: color ?? AppColors.primary),
      ),
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical:   AppDimensions.spacingSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );
  }
}