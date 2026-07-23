import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Primary action button with optional loading state and icon.
///
/// The button's [text] label is always passed in by the caller, which
/// should already be a localized string from AppLocalizations. This widget
/// itself contains no hardcoded visible text.
class PrimaryButton extends StatelessWidget {
  final String   text;
  final VoidCallback? onPressed;
  final bool     isLoading;
  final IconData? icon;
  final Color?   backgroundColor;
  final Color?   foregroundColor;
  final double?  height;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading       = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor:         backgroundColor ?? AppColors.primary,
      foregroundColor:         foregroundColor ?? Colors.white,
      disabledBackgroundColor: AppColors.slate200,
      disabledForegroundColor: AppColors.slate400,
      elevation:   0,
      minimumSize: Size(double.infinity,
          height ?? AppDimensions.buttonHeightLg),
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingH,
            vertical:   AppDimensions.buttonPaddingV,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    );

    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style:     style,
        child: const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
            strokeWidth:  2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style:     style,
        icon:      Icon(icon, size: AppDimensions.iconSm),
        label:     Text(text, style: AppTextStyles.buttonLarge),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style:     style,
      child:     Text(text, style: AppTextStyles.buttonLarge),
    );
  }
}