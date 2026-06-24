import 'package:flutter/material.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/widgets/app_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.errorMessage,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;

    return SizedBox(
      width: 260,
      child: Tooltip(
        message: errorMessage == null
            ? ''
            : ErrorMessages.friendly(errorMessage),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: hasError ? Colors.red : color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: hasError ? Colors.red : null,
                              ),
                        ),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasError) ...[
                const SizedBox(height: 8),
                Text(
                  'Hover for details',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
