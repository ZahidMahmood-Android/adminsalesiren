import 'package:flutter/material.dart';

import 'app_loader.dart';

/// Exposes whether an ancestor [AppLoadingOverlay] is showing the global loader.
class AppLoadingScope extends InheritedWidget {
  const AppLoadingScope({
    required this.isLoading,
    required super.child,
    super.key,
  });

  final bool isLoading;

  static AppLoadingScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLoadingScope>();
  }

  static bool isActive(BuildContext context) {
    return maybeOf(context)?.isLoading ?? false;
  }

  @override
  bool updateShouldNotify(AppLoadingScope oldWidget) {
    return isLoading != oldWidget.isLoading;
  }
}

/// Dims page content and shows the branded loader during async work.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    required this.isLoading,
    required this.child,
    this.loaderSize = 96,
    super.key,
  });

  final bool isLoading;
  final Widget child;
  final double loaderSize;

  @override
  Widget build(BuildContext context) {
    return AppLoadingScope(
      isLoading: isLoading,
      child: Stack(
        children: [
          child,
          if (isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.08),
                child: AppLoader(size: loaderSize),
              ),
            ),
        ],
      ),
    );
  }
}

/// Button icon: shows a small spinner only when loading **and** no global overlay.
class AppAsyncButtonIcon extends StatelessWidget {
  const AppAsyncButtonIcon({
    required this.isLoading,
    required this.icon,
    this.size = 18,
    super.key,
  });

  final bool isLoading;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isLoading && !AppLoadingScope.isActive(context)) {
      return SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(icon);
  }
}

/// Field suffix / inline progress: hidden while the global app loader is active.
class AppAsyncProgressIcon extends StatelessWidget {
  const AppAsyncProgressIcon({
    required this.isLoading,
    required this.idle,
    this.size = 18,
    this.color,
    super.key,
  });

  final bool isLoading;
  final Widget idle;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (isLoading && !AppLoadingScope.isActive(context)) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      );
    }
    return idle;
  }
}
