import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the app-wide [ThemeMode].
/// Toggle dark / light from any widget via:
/// ```dart
/// ref.read(themeModeProvider.notifier).toggle();
/// // or
/// ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
/// ```
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() =>
      state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
