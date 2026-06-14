import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class InfoGrid extends StatelessWidget {
  const InfoGrid({required this.entries, super.key});

  final Map<String, String> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: entries.entries.map((entry) {
        return SizedBox(
          width: 240,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
