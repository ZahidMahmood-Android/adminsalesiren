import 'package:flutter/material.dart';

import 'app_loading_indicator.dart';
import 'app_loader.dart';

/// Centered branded loader for page-level and section-level loading states.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.label = '', this.size = 118});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return AppLoader(size: size);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLoadingIndicator(size: size),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
