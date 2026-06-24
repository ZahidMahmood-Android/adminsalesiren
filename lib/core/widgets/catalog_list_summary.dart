import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CatalogListSummary extends StatelessWidget {
  const CatalogListSummary({
    required this.total,
    required this.active,
    required this.inactive,
    this.extra,
    super.key,
  });

  final int total;
  final int active;
  final int inactive;
  final CatalogSummaryChip? extra;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryChip(
          label: 'Total',
          value: total,
          icon: Icons.layers_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        _SummaryChip(
          label: 'Active',
          value: active,
          icon: Icons.check_circle_outline,
          color: AppTheme.deepGreen,
        ),
        _SummaryChip(
          label: 'Inactive',
          value: inactive,
          icon: Icons.pause_circle_outline,
          color: Colors.blueGrey,
        ),
        if (extra != null)
          _SummaryChip(
            label: extra!.label,
            value: extra!.value,
            icon: extra!.icon,
            color: extra!.color,
          ),
      ],
    );
  }
}

class CatalogSummaryChip {
  const CatalogSummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
