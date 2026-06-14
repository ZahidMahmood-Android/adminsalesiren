import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_card.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quick actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/offers/new'),
            icon: const Icon(Icons.add),
            label: const Text('Create offer'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/brands/new'),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Add brand'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go('/reports'),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Review reports'),
          ),
        ],
      ),
    );
  }
}
