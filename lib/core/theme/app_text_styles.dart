import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography system for the Wrenta application.
///
/// Colors are intentionally omitted so text inherits from the nearest
/// DefaultTextStyle — which Flutter derives from the active ThemeData.
/// Widgets that need an explicit accent color (error, primary, etc.) should
/// call `.copyWith(color: ...)` at the call site.
abstract final class AppTextStyles {
  static const TextStyle h4 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.4);
  static const TextStyle h5 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.4);
  static const TextStyle h6 = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.4);

  static const TextStyle bodyLarge  = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5);
  static const TextStyle bodyMedium = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5);
  static const TextStyle bodySmall  = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5);
  static const TextStyle bodyBold   = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.5);

  static const TextStyle labelLarge  = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle labelMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle labelSmall  = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3);

  static const TextStyle caption     = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle captionBold = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.4);
  static const TextStyle overline    = TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5, height: 1.3);
  static const TextStyle sectionLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.3);

  static const TextStyle buttonLarge  = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2);
  static const TextStyle buttonMedium = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2);

  static const TextStyle monospace = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Courier', height: 1.2);
  static const TextStyle link      = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary, decoration: TextDecoration.underline, height: 1.2);

  static TextStyle withColor(TextStyle style, Color color)       => style.copyWith(color: color);
  static TextStyle withWeight(TextStyle style, FontWeight weight) => style.copyWith(fontWeight: weight);
}
