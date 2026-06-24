import 'package:flutter/material.dart';

import 'app_loader.dart';

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
    return Stack(
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
    );
  }
}
