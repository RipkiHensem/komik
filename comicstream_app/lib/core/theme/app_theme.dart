import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ComicStream theme — Premium dark theme
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),

      // ── Typography (Plus Jakarta Sans) ─────────────────────
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
            height: 1.15,
          ),
          displayMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
          headlineMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
          labelMedium: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── AppBar ──────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Bottom Navigation ───────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNav,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      // ── Card (Double-Bezel & Fine Hairline) ─────────────────
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input Decoration ────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Elevated Button ─────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.surface;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryLight;
            }
            return AppColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 6.0;
            return 0.0;
          }),
          shadowColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.5)),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.15);
            }
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.25);
            }
            return null;
          }),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary;
            }
            return AppColors.textPrimary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(color: AppColors.primary, width: 1.2);
            }
            return BorderSide(color: AppColors.divider);
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.1);
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.12);
            }
            return null;
          }),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryLight;
            }
            return AppColors.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.15);
            }
            return null;
          }),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),

      // ── Icon Button ─────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.12);
            }
            return null;
          }),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),

      // ── Chip ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySurface,
        disabledColor: AppColors.surface,
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Snackbar ────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ─────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Progress Indicator ──────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surface,
      ),

      // ── Tab Bar ─────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Scrollbar ───────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(true),
        interactive: true,
        thickness: const WidgetStatePropertyAll(8.0),
        radius: const Radius.circular(6.0),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return AppColors.primary;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primary.withValues(alpha: 0.85);
          }
          return Colors.white.withValues(alpha: 0.35);
        }),
        trackColor: const WidgetStatePropertyAll(Colors.black26),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.8,
            height: 1.15,
          ),
          displayMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
            height: 1.2,
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
          headlineMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          headlineSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          titleLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          titleSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF0F172A),
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF475569),
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Color(0xFF64748B),
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: 0.3,
          ),
          labelMedium: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
            letterSpacing: 0.2,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: const Color(0xFF0F172A),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFE2E8F0);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryLight;
            }
            return AppColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 6.0;
            return 0.0;
          }),
          shadowColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.4)),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.15);
            }
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.25);
            }
            return null;
          }),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary;
            }
            return const Color(0xFF0F172A);
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(color: AppColors.primary, width: 1.2);
            }
            return const BorderSide(color: Color(0xFFE2E8F0));
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.12);
            }
            return null;
          }),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryLight;
            }
            return AppColors.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.1);
            }
            return null;
          }),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.black.withValues(alpha: 0.08);
            }
            return null;
          }),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: const Color(0xFFEDE9FE),
        disabledColor: const Color(0xFFF1F5F9),
        labelStyle: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFFF1F5F9),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(true),
        interactive: true,
        thickness: const WidgetStatePropertyAll(8.0),
        radius: const Radius.circular(6.0),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return AppColors.primary;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primary.withValues(alpha: 0.85);
          }
          return Colors.black.withValues(alpha: 0.25);
        }),
        trackColor: const WidgetStatePropertyAll(Colors.black12),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
