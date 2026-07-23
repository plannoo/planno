import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Secondary (outlined) button.
///
/// The [text] label is always supplied by the caller as a localized string.
/// This widget contains no hardcoded visible text.
class SecondaryButton extends StatelessWidget {
  final String   text;
  final VoidCallback? onPressed;
  final bool     isLoading;
  final IconData? icon;
  final Color?   borderColor;
  final Color?   textColor;
  final double?  height;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading   = false,
    this.icon,
    this.borderColor,
    this.textColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor:         textColor ?? AppColors.slate700,
      backgroundColor:         Theme.of(context).colorScheme.surface,
      disabledForegroundColor: AppColors.slate300,
      side: BorderSide(
        color: borderColor ?? AppColors.slate200,
        width: AppDimensions.borderThin,
      ),
      minimumSize: Size(double.infinity,
          height ?? AppDimensions.buttonHeightMd),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.buttonPaddingH,
        vertical:   AppDimensions.buttonPaddingV,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    );

    if (isLoading) {
      return OutlinedButton(
        onPressed: null,
        style:     style,
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? AppColors.slate700),
          ),
        ),
      );
    }

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style:     style,
        icon:      Icon(icon, size: AppDimensions.iconSm),
        label:     Text(text, style: AppTextStyles.buttonMedium),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style:     style,
      child:     Text(text, style: AppTextStyles.buttonMedium),
    );
  }
}