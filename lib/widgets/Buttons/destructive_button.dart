import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'primary_button.dart';

/// Destructive action button (red / error colour).
///
/// The [text] label is supplied by the caller as a localized string.
/// This widget contains no hardcoded visible text.
class DestructiveButton extends StatelessWidget {
  final String   text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool     isLoading;

  const DestructiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text:            text,
      onPressed:       onPressed,
      icon:            icon,
      isLoading:       isLoading,
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
    );
  }
}