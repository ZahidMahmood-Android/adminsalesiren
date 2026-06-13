import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBadge extends StatelessWidget {
  const AppBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color == Colors.white ? AppTheme.ink : color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
