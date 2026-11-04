import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════
// LyricFlow — Theme System
// Material 3 con Dark/Light mode premium
// ══════════════════════════════════════════════

/// Provider para el modo de tema (dark/light/system)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Colores de la marca
class AppColors {
  AppColors._();

  // ─── Primary Palette ───
  static const primary = Color(0xFF7C3AED);        // Violet 600
  static const primaryLight = Color(0xFFA78BFA);    // Violet 400
  static const primaryDark = Color(0xFF5B21B6);     // Violet 800
  static const primaryContainer = Color(0xFF1E1145); // Custom deep violet

  // ─── Accent ───
  static const accent = Color(0xFFEC4899);          // Pink 500
  static const accentLight = Color(0xFFF472B6);     // Pink 400
  static const accentContainer = Color(0xFF3D1131);  // Custom deep pink

  // ─── Semantic Colors ───
  static const success = Color(0xFF22C55E);
  static const successContainer = Color(0xFF0A2E1A);
  static const warning = Color(0xFFF59E0B);
  static const warningContainer = Color(0xFF2D1F05);
  static const error = Color(0xFFEF4444);
  static const errorContainer = Color(0xFF2D0A0A);
  static const info = Color(0xFF3B82F6);

  // ─── Dark Theme ───
  static const darkBg = Color(0xFF0A0A14);
  static const darkSurface = Color(0xFF12121F);
  static const darkElevated = Color(0xFF1A1A2E);
  static const darkCard = Color(0xFF16162A);
  static const darkBorder = Color(0xFF2A2A40);

  // ─── Light Theme ───
  static const lightBg = Color(0xFFF8F9FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightElevated = Color(0xFFF1F3F8);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);

  // ─── Text ───
  static const darkTextPrimary = Color(0xFFF1F1F5);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkTextMuted = Color(0xFF6B7280);

  static const lightTextPrimary = Color(0xFF1A1A2E);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextMuted = Color(0xFF9CA3AF);

  // ─── Gradients ───
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1145), Color(0xFF3D1131)],
  );

  static const glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x15FFFFFF),
      Color(0x08FFFFFF),
    ],
  );
}

/// Tema de la aplicación
class AppTheme {
  AppTheme._();

  // ─── Tipografía base ───
  static TextTheme get _baseTextTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  // ════════════════════════════════════════
  // DARK THEME
  // ════════════════════════════════════════
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accentContainer,
      onSecondaryContainer: AppColors.accentLight,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder.withValues(alpha: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: _applyDarkTextColors(_baseTextTheme),

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg.withValues(alpha: 0.8),
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.3,
        ),
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Filled Button ───
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.darkBorder),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Icon Button ───
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darkTextSecondary,
        ),
      ),

      // ─── Input ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.darkTextMuted,
          fontSize: 14,
        ),
      ),

      // ─── Bottom Nav ───
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // ─── Snackbar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkElevated,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkElevated,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // ─── Progress Indicator ───
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.darkElevated,
      ),
    );
  }

  // ════════════════════════════════════════
  // LIGHT THEME
  // ════════════════════════════════════════
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary.withValues(alpha: 0.1),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accent.withValues(alpha: 0.1),
      onSecondaryContainer: AppColors.accent,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorder.withValues(alpha: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: _applyLightTextColors(_baseTextTheme),

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg.withValues(alpha: 0.9),
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.3,
        ),
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ─── Input ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ─── Helpers ───
  static TextTheme _applyDarkTextColors(TextTheme textTheme) {
    return textTheme.apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    );
  }

  static TextTheme _applyLightTextColors(TextTheme textTheme) {
    return textTheme.apply(
      bodyColor: AppColors.lightTextPrimary,
      displayColor: AppColors.lightTextPrimary,
    );
  }
}

/// Extensiones de tema para acceso rápido
extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDark => theme.brightness == Brightness.dark;
}
