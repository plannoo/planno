import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// Custom floating action button with consistent styling.
///
/// The optional [tooltip] is supplied by the caller as a localized string.
/// This widget contains no hardcoded visible text.
class CustomFAB extends StatelessWidget {
  final IconData   icon;
  final VoidCallback onPressed;
  final String?    tooltip;
  final Color?     backgroundColor;
  final Color?     foregroundColor;

  const CustomFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed:       onPressed,
      tooltip:         tooltip,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation:       4,
      child: Icon(icon, size: AppDimensions.iconMd),
    );
  }
}