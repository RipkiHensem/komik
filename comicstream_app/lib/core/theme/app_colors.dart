import 'package:flutter/material.dart';

/// Central monochrome design tokens used across the ComicStream interface.
class AppColors {
  AppColors._();

  /// The app currently launches in dark mode; retained for existing theme-aware UI.
  static bool isDark = true;

  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF141414);
  static const Color darkElevated = Color(0xFF1C1C1C);
  static const Color darkBorder = Color(0xFF262626);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  static const Color darkTextMuted = Color(0xFF737373);

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightElevated = Color(0xFFEEEEEE);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightTextPrimary = Color(0xFF0A0A0A);
  static const Color lightTextSecondary = Color(0xFF525252);
  static const Color lightTextMuted = Color(0xFF737373);

  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get surfaceLight => isDark ? darkElevated : lightElevated;
  static Color get card => surface;
  static Color get cardHover => surfaceLight;
  static Color get cardElevated => surfaceLight;
  static Color get bottomNav => surface;
  static Color get divider => isDark ? darkBorder : lightBorder;
  static Color get glassBorder => divider;
  static Color get border => divider;
  static List<BoxShadow> get cardShadow => const [];

  static const Color darkPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF0A0A0A);
  static Color get primary => isDark ? darkPrimary : lightPrimary;
  static Color get primaryLight => primary;
  static Color get primaryDark => primary;
  static Color get primarySurface => surfaceLight;

  // Compatibility aliases retained for existing screens; the interface stays neutral.
  static Color get secondary => primary;
  static Color get secondaryLight => primary;
  static Color get secondaryDark => primary;
  static Color get success => isDark ? const Color(0xFF262626) : const Color(0xFF525252);
  static Color get warning => textSecondary;
  static Color get error => isDark ? const Color(0xFF333333) : const Color(0xFF404040);
  static Color get info => textSecondary;
  static Color get badgeNew => textSecondary;
  static Color get badgeUp => textSecondary;
  static Color get badgeHot => textPrimary;
  static Color get badgePopular => textPrimary;
  static Color get ratingStar => textPrimary;

  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted => isDark ? darkTextMuted : lightTextMuted;
  static Color get textHint => textMuted;

  /// Neutral aliases for older components that still consume these gradients.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1C1C1C), Color(0xFF1C1C1C)],
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF737373), Color(0xFF737373)],
  );

  static LinearGradient get heroOverlay => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      isDark ? const Color(0xCC0A0A0A) : const Color(0xCCFFFFFF),
      background,
    ],
    stops: const [0.0, 0.6, 1.0],
  );

  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xDD0A0A0A)],
    stops: [0.35, 1.0],
  );

  static LinearGradient get shimmerGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: isDark
        ? const [Color(0xFF141414), Color(0xFF262626), Color(0xFF141414)]
        : const [Color(0xFFE5E5E5), Color(0xFFF5F5F5), Color(0xFFE5E5E5)],
  );
}
