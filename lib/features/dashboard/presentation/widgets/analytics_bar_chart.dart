import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class AnalyticsBarChart extends StatelessWidget {
  const AnalyticsBarChart({
    required this.title,
    required this.values,
    super.key,
  });

  final String title;
  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.fold<int>(1, (max, value) {
      return value > max ? value : max;
    });

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),
          ...values.entries.map((entry) {
            final factor = entry.value / maxValue;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 92, child: Text(entry.key)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: factor,
                        minHeight: 14,
                        backgroundColor: AppTheme.paper,
                        color: AppTheme.deepGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 36,
                    child: Text(
                      entry.value.toString(),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
