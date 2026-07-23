import 'package:flutter/material.dart';

/// Central color palette for the Wrenta application.
abstract final class AppColors {
  // ── Primary ────────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFFF43F5E);
  static const Color primaryLight  = Color(0xFFFFE4E6);
  static const Color primaryLighter = Color(0xFFFFF1F2);
  static const Color accent        = Color(0xFFFB7185);

  // ── Neutral (Slate scale) ──────────────────────────────────────────────────
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50  = Color(0xFFF8FAFC);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error        = Color(0xFFEF4444);
  static const Color errorLight   = Color(0xFFFEE2E2);
  static const Color info         = Color(0xFFF43F5E);
  static const Color infoLight    = Color(0xFFFFE4E6);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color active   = Color(0xFF22C55E);
  static const Color inactive = Color(0xFF94A3B8);
  static const Color pending  = Color(0xFFF59E0B);
  static const Color approved = Color(0xFF22C55E);
  static const Color rejected = Color(0xFFEF4444);

  // ── Surface (Light) ────────────────────────────────────────────────────────
  static const Color background     = Color(0xFFF8FAFC);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ── Surface (Dark) ─────────────────────────────────────────────────────────
  static const Color backgroundDark     = Color(0xFF0F172A);
  static const Color surfaceDark        = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color surfaceDarkCard    = Color(0xFF1E293B);

  // ── Accent extras ─────────────────────────────────────────────────────────
  static const Color purple      = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFEDE9FE);
  static const Color amber       = Color(0xFFFBBF24);
  static const Color amberLight  = Color(0xFFFEF3C7);
  static const Color orange      = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFED7AA);
}