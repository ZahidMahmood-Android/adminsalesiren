import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/presentation/providers/offer_providers.dart';
import '../../../reports/presentation/providers/report_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(brandsProvider);
    final offers = ref.watch(offersProvider);
    final cities = ref.watch(citiesProvider);
    final categories = ref.watch(categoriesProvider);
    // Only watch reports if we need them - skip for now if permission denied
    final reports = ref.watch(reportsProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _MetricCard(
                    label: 'Brands',
                    icon: Icons.storefront_outlined,
                    color: AppTheme.deepGreen,
                    value: brands.when(
                      data: (items) => items.length.toString(),
                      loading: () => '-',
                      error: (error, _) => '!',
                    ),
                    errorMessage: brands.when(
                      error: (error, _) => error.toString(),
                      data: (_) => null,
                      loading: () => null,
                    ),
                  ),
                  _MetricCard(
                    label: 'Published offers',
                    icon: Icons.campaign_outlined,
                    color: AppTheme.coral,
                    value: offers.when(
                      data: (items) => items
                          .where((offer) => offer.isPublished)
                          .length
                          .toString(),
                      loading: () => '-',
                      error: (error, _) => '!',
                    ),
                    errorMessage: offers.when(
                      error: (error, _) => error.toString(),
                      data: (_) => null,
                      loading: () => null,
                    ),
                  ),
                  _MetricCard(
                    label: 'Pending reports',
                    icon: Icons.flag_outlined,
                    color: AppTheme.saffron,
                    value: reports.when(
                      data: (items) => items
                          .where((report) => report.status == 'pending')
                          .length
                          .toString(),
                      loading: () => '-',
                      error: (error, _) => '!',
                    ),
                    errorMessage: reports.when(
                      error: (error, _) {
                        final errorStr = error.toString();
                        if (errorStr.contains('permission')) {
                          return 'Permission denied - verify admin document exists at admins/{your-uid}. See admin setup screen for details.';
                        }
                        return errorStr;
                      },
                      data: (_) => null,
                      loading: () => null,
                    ),
                  ),
                  _MetricCard(
                    label: 'Cities / Categories',
                    icon: Icons.grid_view_outlined,
                    color: AppTheme.freshGreen,
                    value: cities.when(
                      data: (citiesList) => categories.when(
                        data: (categoriesList) =>
                            '${citiesList.length} / ${categoriesList.length}',
                        loading: () => '-',
                        error: (_, _) => '!',
                      ),
                      loading: () => '-',
                      error: (_, _) => '!',
                    ),
                    errorMessage: cities.when(
                      error: (error, _) => error.toString(),
                      data: (_) => categories.when(
                        error: (error, _) => error.toString(),
                        data: (_) => null,
                        loading: () => null,
                      ),
                      loading: () => null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 980;
                  if (!wide) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RecentOffersCard(offers: offers),
                        const SizedBox(height: 18),
                        const _QuickActionsCard(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 18) * 0.62,
                        child: _RecentOffersCard(offers: offers),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: (constraints.maxWidth - 18) * 0.38,
                        child: const _QuickActionsCard(),
                      ),
                    ],
                  );
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.errorMessage,
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
        message: errorMessage ?? '',
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
                  '⚠️ Hover for details',
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

class _RecentOffersCard extends StatelessWidget {
  const _RecentOffersCard({required this.offers});

  final AsyncValue<List<Offer>> offers;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Recent offers',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          offers.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No offers yet.')),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: items.take(6).map((offer) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.paper,
                      child: Icon(
                        offer.isPublished
                            ? Icons.check_circle_outline
                            : Icons.schedule_outlined,
                        color: offer.isPublished
                            ? AppTheme.deepGreen
                            : AppTheme.saffron,
                      ),
                    ),
                    title: Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${offer.brandName} · ${offer.discountText}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Open offer',
                      onPressed: () => context.go('/offers/${offer.id}'),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 180,
              child: AppLoadingView(label: 'Loading offers'),
            ),
            error: (error, _) => AppErrorView(message: error.toString()),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

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
