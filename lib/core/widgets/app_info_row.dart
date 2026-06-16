import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_text_view.dart';

/// A horizontal label → value row for detail / profile cards.
///
/// Usage:
/// ```dart
/// AppInfoRow(label: 'Status', value: 'Active')
/// AppInfoRow(label: 'Plan', value: brand.planName, valueWidget: chip)
/// AppInfoRow.divider()
/// ```
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.icon,
    this.onTap,
  });

  const AppInfoRow.divider({super.key})
    : label = '',
      value = null,
      valueWidget = null,
      icon = null,
      onTap = null;

  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData? icon;
  final VoidCallback? onTap;

  bool get _isDivider => label.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isDivider) {
      return Divider(
        height: 1,
        thickness: 0.8,
        color: AppColors.border(Theme.of(context).colorScheme.brightness),
      );
    }

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: AppColors.textMuted(
                Theme.of(context).colorScheme.brightness,
              ),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: AppTextView.label(
              label,
              color: AppColors.textMuted(
                Theme.of(context).colorScheme.brightness,
              ),
            ),
          ),
          Expanded(
            child:
                valueWidget ??
                AppTextView.body(value ?? '—', fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: row);
    }
    return row;
  }
}
