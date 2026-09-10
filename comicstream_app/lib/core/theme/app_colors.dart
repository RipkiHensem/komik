import 'package:flutter/material.dart';

/// ComicStream color palette — Supports both Dark & Light (White) mode
class AppColors {
  AppColors._();

  /// Global theme toggle flag
  static bool isDark = true;

  // ── Background & Surface (OLED Deep Velvet & Frosted Glass) ─────────
  static Color get background => isDark ? const Color(0xFF090B10) : const Color(0xFFF8FAFC);
  static Color get surface => isDark ? const Color(0xFF11141D) : const Color(0xFFFFFFFF);
  static Color get surfaceLight => isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
  static Color get card => isDark ? const Color(0xFF161A24) : const Color(0xFFFFFFFF);
  static Color get cardHover => isDark ? const Color(0xFF1D2230) : const Color(0xFFF1F5F9);
  static Color get cardElevated => isDark ? const Color(0xFF1A1F2C) : const Color(0xFFFFFFFF);
  static Color get bottomNav => isDark ? const Color(0xDD0D111A) : const Color(0xEEFFFFFF);
  static Color get divider => isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0);
  static Color get glassBorder => isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Primary / Accent (World-class Indigo-Violet) ────────────
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static Color get primarySurface => isDark ? const Color(0xFF1A1B30) : const Color(0xFFEEF2FF);

  // ── Secondary / Electric Cyan ──────────────────────────────
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);

  // ── Status Colors ─────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Badge Colors ──────────────────────────────────────────
  static const Color badgeNew = Color(0xFF10B981);
  static const Color badgeUp = Color(0xFFFF3B30);
  static const Color badgeHot = Color(0xFFFF6B00);
  static const Color badgePopular = Color(0xFFFFB800);

  // ── Text Colors ───────────────────────────────────────────
  static Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  static Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF64748B);
  static Color get textHint => isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);

  // ── Rating ────────────────────────────────────────────────
  static const Color ratingStar = Color(0xFFFFB800);

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3B30), Color(0xFFFF6B00)],
  );

  static LinearGradient get heroOverlay => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      isDark ? const Color(0xCC090B10) : const Color(0xCCF8FAFC),
      background,
    ],
    stops: const [0.0, 0.6, 1.0],
  );

  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xDD090B10),
    ],
    stops: [0.35, 1.0],
  );

  static LinearGradient get shimmerGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: isDark
        ? const [
            Color(0xFF11141D),
            Color(0xFF1D2230),
            Color(0xFF11141D),
          ]
        : const [
            Color(0xFFE2E8F0),
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
          ],
  );
}
