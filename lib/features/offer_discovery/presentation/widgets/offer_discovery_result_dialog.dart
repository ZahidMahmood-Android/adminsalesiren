import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/discovered_offers_repository.dart';

Future<void> showOfferDiscoveryResultDialog({
  required BuildContext context,
  required OfferDiscoveryRunResult result,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.freshGreen.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  size: 40,
                  color: AppTheme.freshGreen,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Discovery complete',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.discoveredCount > 0
                    ? 'Found ${result.discoveredCount} new suggestion(s) for review.'
                    : 'No new suggestions were added this run.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _ResultStatRow(
                icon: Icons.storefront_outlined,
                label: 'Brands checked',
                value: '${result.checkedBrands}',
              ),
              _ResultStatRow(
                icon: Icons.auto_awesome_outlined,
                label: 'New suggestions',
                value: '${result.discoveredCount}',
                highlight: result.discoveredCount > 0,
              ),
              _ResultStatRow(
                icon: Icons.copy_all_outlined,
                label: 'Duplicates skipped',
                value: '${result.duplicateCount}',
              ),
              _ResultStatRow(
                icon: Icons.error_outline,
                label: 'Source errors',
                value: '${result.errorCount}',
                highlight: result.errorCount > 0,
                highlightColor: AppTheme.coral,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ResultStatRow extends StatelessWidget {
  const _ResultStatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor = AppTheme.freshGreen,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlight ? highlightColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
