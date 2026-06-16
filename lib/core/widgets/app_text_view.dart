import 'package:flutter/material.dart';

/// Semantic text-style names used by [AppTextView].
///
/// Maps directly to Material 3 type-scale slots so that dark/light themes
/// pick up the right colors automatically.
enum AppTextStyle {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

/// A standardised text widget that pulls its [TextStyle] from the current
/// [ThemeData.textTheme], making every text in the app respect the active
/// light / dark theme automatically.
///
/// Usage examples:
/// ```dart
/// AppTextView('Hello', style: AppTextStyle.headlineMedium)
/// AppTextView.label('Subtotal')
/// AppTextView.body('Some description text')
/// AppTextView.title('Section title')
/// ```
class AppTextView extends StatelessWidget {
  const AppTextView(
    this.text, {
    super.key,
    this.appStyle = AppTextStyle.bodyMedium,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.fontSize,
    this.height,
    this.letterSpacing,
  });

  // ── Convenience constructors ──────────────────────────────────────────

  /// Large display / hero text (e.g. stats on the dashboard).
  const AppTextView.display(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.fontSize,
    this.height,
    this.letterSpacing,
  }) : appStyle = AppTextStyle.displayMedium;

  /// Page / section heading.
  const AppTextView.heading(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.fontSize,
    this.height,
    this.letterSpacing,
  }) : appStyle = AppTextStyle.headlineMedium;

  /// Card / dialog title.
  const AppTextView.title(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.fontSize,
    this.height,
    this.letterSpacing,
  }) : appStyle = AppTextStyle.titleMedium;

  /// Standard body copy.
  const AppTextView.body(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.fontSize,
    this.height,
    this.letterSpacing,
  }) : appStyle = AppTextStyle.bodyMedium;

  /// Small label / metadata text.
  const AppTextView.label(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.fontSize,
    this.height,
    this.letterSpacing,
  }) : appStyle = AppTextStyle.labelMedium;

  // ── Fields ────────────────────────────────────────────────────────────

  final String text;
  final AppTextStyle appStyle;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextDecoration? decoration;
  final double? fontSize;
  final double? height;
  final double? letterSpacing;

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final base = _resolveStyle(context);
    final merged = base?.copyWith(
      color: color,
      fontWeight: fontWeight,
      decoration: decoration,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
    );

    return Text(
      text,
      style: merged,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  TextStyle? _resolveStyle(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return switch (appStyle) {
      AppTextStyle.displayLarge => tt.displayLarge,
      AppTextStyle.displayMedium => tt.displayMedium,
      AppTextStyle.displaySmall => tt.displaySmall,
      AppTextStyle.headlineLarge => tt.headlineLarge,
      AppTextStyle.headlineMedium => tt.headlineMedium,
      AppTextStyle.headlineSmall => tt.headlineSmall,
      AppTextStyle.titleLarge => tt.titleLarge,
      AppTextStyle.titleMedium => tt.titleMedium,
      AppTextStyle.titleSmall => tt.titleSmall,
      AppTextStyle.bodyLarge => tt.bodyLarge,
      AppTextStyle.bodyMedium => tt.bodyMedium,
      AppTextStyle.bodySmall => tt.bodySmall,
      AppTextStyle.labelLarge => tt.labelLarge,
      AppTextStyle.labelMedium => tt.labelMedium,
      AppTextStyle.labelSmall => tt.labelSmall,
    };
  }
}
