import 'package:flutter/material.dart';

/// Cloud Company palette — matches the website (ink navy + brand blue).
class AppColors {
  AppColors._();

  // ── Brand ───────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB); // brand blue
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color ink = Color(0xFF021327); // website header navy
  static const Color inkSoft = Color(0xFF0D1B3E);

  // ── Status ──────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // ── Light ───────────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
}
