import 'package:flutter/material.dart';

/// Central color palette for Salesiren Admin Panel.
/// Never use raw [Colors] values outside this file — always pick from here
/// so that any brand-color change only needs one place to update.
class AppColors {
  const AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const deepGreen = Color(0xFF0F766E);
  static const freshGreen = Color(0xFF14A38B);
  static const lightGreen = Color(0xFFD1FAF0);
  static const coral = Color(0xFFE76F51);
  static const saffron = Color(0xFFC99700);

  // ── Light-mode neutrals ────────────────────────────────────────────────
  static const ink = Color(0xFF17201D);
  static const inkMuted = Color(0xFF6B7280);
  static const paper = Color(0xFFF7F9F8);
  static const white = Color(0xFFFFFFFF);
  static const line = Color(0xFFE3E8E5);

  // ── Dark-mode neutrals ─────────────────────────────────────────────────
  static const darkBg = Color(0xFF0B1612);
  static const darkSurface = Color(0xFF15231F);
  static const darkCard = Color(0xFF1C302B);
  static const darkBorder = Color(0xFF2A4540);
  static const darkText = Color(0xFFCFE8E2);
  static const darkTextMuted = Color(0xFF7AADA5);

  // ── Status ────────────────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // ── Derived helpers ───────────────────────────────────────────────────
  /// Low-opacity tint of deepGreen used for selected nav items, chips, etc.
  static const greenTint = Color(0xFFE5F4F1);

  /// Returns the correct "surface" color for the given [brightness].
  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? darkCard : white;

  /// Returns the correct "background" color for the given [brightness].
  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? darkBg : paper;

  /// Returns the correct border color for the given [brightness].
  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : line;

  /// Returns the correct primary text color for the given [brightness].
  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? darkText : ink;

  /// Returns the correct muted text color for the given [brightness].
  static Color textMuted(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextMuted : inkMuted;
}
