import 'package:flutter/material.dart';

class AppTheme {
  static const primaryBlue = Color(0xFF246BFD); // The vibrant blue in your button
  static const backgroundWhite = Colors.white;
  static const textBlack = Color(0xFF000000);
  static const textGray = Color(0xFF616161);
  static const indicatorGray = Color(0xFFE0E0E0);

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundWhite,
    fontFamily: 'Inter', // Or similar clean Sans-Serif
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56), // Tall, accessible buttons
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
  );
}