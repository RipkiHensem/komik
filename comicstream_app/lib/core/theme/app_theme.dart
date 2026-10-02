import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Shared typography and component styles for the monochrome app.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final font = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: background,
        secondary: primary,
        onSecondary: background,
        error: isDark ? const Color(0xFFE5E5E5) : const Color(0xFF404040),
        onError: background,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: font.copyWith(
        displayLarge: font.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.15,
        ),
        displayMedium: font.displayMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.2,
        ),
        headlineLarge: font.headlineLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: font.headlineMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: font.headlineSmall?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: font.titleLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleMedium: font.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: font.titleSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodyLarge: font.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: font.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: font.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: font.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: font.labelMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: font.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(44, 44),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          minimumSize: const Size(44, 44),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(44, 44),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        labelStyle: TextStyle(color: textSecondary, fontSize: 12),
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: textPrimary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: textPrimary,
        linearTrackColor: border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkElevated : AppColors.lightElevated,
        contentTextStyle: TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(false),
        trackVisibility: const WidgetStatePropertyAll(false),
        thickness: const WidgetStatePropertyAll(3),
        radius: const Radius.circular(999),
        thumbColor: WidgetStatePropertyAll(textMuted.withValues(alpha: 0.5)),
      ),
    );
  }
}
