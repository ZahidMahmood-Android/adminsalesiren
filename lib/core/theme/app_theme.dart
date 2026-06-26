import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  // Keep direct color aliases so existing code that reads `AppTheme.deepGreen`
  // continues to work without changes.
  static const ink = AppColors.ink;
  static const deepGreen = AppColors.deepGreen;
  static const freshGreen = AppColors.freshGreen;
  static const coral = AppColors.coral;
  static const saffron = AppColors.saffron;
  static const paper = AppColors.paper;
  static const line = AppColors.line;

  // ── Light theme ──────────────────────────────────────────────────────
  static ThemeData light() => _build(Brightness.light);

  // ── Dark theme ───────────────────────────────────────────────────────
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final primary = AppColors.deepGreen;
    final bg = AppColors.background(brightness);
    final surface = AppColors.surface(brightness);
    final borderColor = AppColors.border(brightness);
    final textColor = AppColors.textPrimary(brightness);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: AppColors.coral,
      tertiary: AppColors.saffron,
      surface: surface,
      surfaceContainerHighest: bg,
      outline: borderColor,
      onSurface: textColor,
      onSurfaceVariant: AppColors.textMuted(brightness),
      error: AppColors.error,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );
    final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.deepGreen, width: 1.4),
        ),
        labelStyle: TextStyle(color: AppColors.textMuted(brightness)),
        hintStyle: TextStyle(
          color: AppColors.textMuted(brightness).withValues(alpha: 0.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(112, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bg,
        selectedColor: AppColors.greenTint,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(bg),
        headingTextStyle: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
        ),
        dataTextStyle: TextStyle(color: textColor),
        dividerThickness: 0.8,
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 0.8),
      listTileTheme: ListTileThemeData(
        textColor: textColor,
        iconColor: AppColors.textMuted(brightness),
        tileColor: Colors.transparent,
        selectedTileColor: isDark
            ? primary.withValues(alpha: 0.14)
            : AppColors.greenTint,
      ),
      iconTheme: IconThemeData(color: AppColors.textMuted(brightness)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textMuted(brightness),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : borderColor,
        ),
      ),
    );
  }
}
