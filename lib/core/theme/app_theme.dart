import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Global [ThemeData] configuration for the Wrenta app.
abstract final class AppTheme {
  static const TextTheme _lightTextTheme = TextTheme(
    displayLarge:  TextStyle(color: AppColors.slate900),
    displayMedium: TextStyle(color: AppColors.slate900),
    displaySmall:  TextStyle(color: AppColors.slate900),
    headlineLarge: TextStyle(color: AppColors.slate900),
    headlineMedium: TextStyle(color: AppColors.slate900),
    headlineSmall: TextStyle(color: AppColors.slate900),
    titleLarge:    TextStyle(color: AppColors.slate800),
    titleMedium:   TextStyle(color: AppColors.slate700),
    titleSmall:    TextStyle(color: AppColors.slate600),
    bodyLarge:     TextStyle(color: AppColors.slate700),
    bodyMedium:    TextStyle(color: AppColors.slate600),
    bodySmall:     TextStyle(color: AppColors.slate500),
    labelLarge:    TextStyle(color: AppColors.slate700),
    labelMedium:   TextStyle(color: AppColors.slate600),
    labelSmall:    TextStyle(color: AppColors.slate400),
  );

  // Brighter than iOS defaults — the muted greys (0xFF8E8E93 / 0xFF636366)
  // were too dim to read on the dark surfaces, especially on the profile page.
  static const TextTheme _darkTextTheme = TextTheme(
    displayLarge:  TextStyle(color: Color(0xFFFFFFFF)),
    displayMedium: TextStyle(color: Color(0xFFFFFFFF)),
    displaySmall:  TextStyle(color: Color(0xFFFFFFFF)),
    headlineLarge: TextStyle(color: Color(0xFFFFFFFF)),
    headlineMedium: TextStyle(color: Color(0xFFFFFFFF)),
    headlineSmall: TextStyle(color: Color(0xFFFFFFFF)),
    titleLarge:    TextStyle(color: Color(0xFFF2F2F7)),
    titleMedium:   TextStyle(color: Color(0xFFE5E5EA)),
    titleSmall:    TextStyle(color: Color(0xFFD1D1D6)),
    bodyLarge:     TextStyle(color: Color(0xFFF2F2F7)),
    bodyMedium:    TextStyle(color: Color(0xFFE5E5EA)),
    bodySmall:     TextStyle(color: Color(0xFFC7C7CC)),
    labelLarge:    TextStyle(color: Color(0xFFF2F2F7)),
    labelMedium:   TextStyle(color: Color(0xFFE5E5EA)),
    labelSmall:    TextStyle(color: Color(0xFFC7C7CC)),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
      surfaceTint: Colors.transparent,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    textTheme: _lightTextTheme,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.slate900,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.h5,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: AppTextStyles.buttonMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.slate700,
        side: const BorderSide(color: AppColors.slate200),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: AppTextStyles.buttonMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.slate50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: AppTextStyles.labelMedium,
      hintStyle: AppTextStyles.bodySmall,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.slate400,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.slate100,
      thickness: 1,
      space: 0,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: _darkTextTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      // Slightly warmer dark tones — less harsh than pure navy
      surface: const Color(0xFF1C1C1E),
      surfaceTint: Colors.transparent,
    ).copyWith(
      surface:              const Color(0xFF1C1C1E),
      surfaceContainerHighest: const Color(0xFF2C2C2E),
      onSurface:            const Color(0xFFF2F2F7),
      // Brighter so secondary text (cs.onSurfaceVariant) stays legible.
      onSurfaceVariant:     const Color(0xFFC7C7CC),
      outline:              const Color(0xFF48484A),
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
    cardColor: const Color(0xFF1C1C1E),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      foregroundColor: Color(0xFFF2F2F7),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: Color(0xFFF2F2F7), height: 1.4),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: AppTextStyles.buttonMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFAEAEB2),
        side: const BorderSide(color: Color(0xFF3A3A3C)),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: AppTextStyles.buttonMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: const TextStyle(
          fontSize: 14, color: Color(0xFF636366), fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1C1C1E),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFF636366),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3A3A3C),
      thickness: 1,
      space: 0,
    ),
  );
}
