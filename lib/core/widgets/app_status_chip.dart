import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/display_label_utils.dart';

/// A compact status pill used throughout lists and detail cards.
///
/// Automatically picks colors based on the [status] string.
/// Pass [customColor] to override.
///
/// Usage:
/// ```dart
/// AppStatusChip(status: 'active')
/// AppStatusChip(status: 'pending', customColor: Colors.orange)
/// AppStatusChip.mini(status: 'expired')
/// ```
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.status,
    this.customColor,
    this.compact = false,
  });

  /// Smaller variant without padding — useful inside table cells.
  const AppStatusChip.mini({super.key, required this.status, this.customColor})
    : compact = true;

  final String status;
  final Color? customColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final color = customColor ?? _colorFor(lower);
    final label = _labelFor(lower);

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static Color _colorFor(String s) {
    if (s.contains('active') || s.contains('paid') || s.contains('verified')) {
      return AppColors.success;
    }
    if (s.contains('trial')) return AppColors.info;
    if (s.contains('pending') || s.contains('unverified')) {
      return AppColors.warning;
    }
    if (s.contains('expired') ||
        s.contains('inactive') ||
        s.contains('deactivated') ||
        s.contains('cancelled') ||
        s.contains('rejected') ||
        s.contains('unpaid')) {
      return AppColors.error;
    }
    if (s.contains('approved')) return AppColors.success;
    return AppColors.inkMuted;
  }

  static String _labelFor(String s) {
    if (s.isEmpty) return '—';
    return DisplayLabelUtils.slug(s);
  }
}
