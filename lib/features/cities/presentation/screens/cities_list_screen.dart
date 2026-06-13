import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/city_providers.dart';

class CitiesListScreen extends ConsumerWidget {
  const CitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(citiesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cities',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: cities.when(
              skipLoadingOnRefresh: true,
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.location_city_outlined,
                    title: 'No cities yet',
                    message: 'Cities will appear here once they are available.',
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final city = items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.paper,
                          child: Icon(Icons.location_city_outlined),
                        ),
                        title: Text(
                          city.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text('${city.id} · ${city.country}'),
                        trailing: Wrap(
                          spacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppBadge(
                              label: city.isActive ? 'Active' : 'Inactive',
                              color: city.isActive
                                  ? AppTheme.deepGreen
                                  : Colors.black45,
                            ),
                            IconButton(
                              tooltip: 'Edit city',
                              onPressed: () => context.go('/cities/${city.id}'),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const AppLoadingView(label: 'Loading cities'),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(citiesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
