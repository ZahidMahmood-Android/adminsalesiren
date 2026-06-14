import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../../offers/presentation/providers/offer_providers.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../widgets/metric_card.dart';
import '../widgets/quick_actions_card.dart';
import '../widgets/recent_offers_card.dart';

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
                  MetricCard(
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
                  MetricCard(
                    label: 'Offers',
                    icon: Icons.campaign_outlined,
                    color: AppTheme.coral,
                    value: offers.when(
                      data: (items) => items.length.toString(),
                      loading: () => '-',
                      error: (error, _) => '!',
                    ),
                    errorMessage: offers.when(
                      error: (error, _) => error.toString(),
                      data: (_) => null,
                      loading: () => null,
                    ),
                  ),
                  MetricCard(
                    label: 'Cities',
                    icon: Icons.location_city_outlined,
                    color: AppTheme.freshGreen,
                    value: cities.when(
                      data: (items) => items.length.toString(),
                      loading: () => '-',
                      error: (error, _) => '!',
                    ),
                    errorMessage: cities.when(
                      error: (error, _) => error.toString(),
                      data: (_) => null,
                      loading: () => null,
                    ),
                  ),
                  MetricCard(
                    label: 'Categories',
                    icon: Icons.grid_view_outlined,
                    color: AppTheme.saffron,
                    value: categories.when(
                      data: (items) => items.length.toString(),
                      loading: () => '-',
                      error: (error, _) => '!',
                    ),
                    errorMessage: categories.when(
                      error: (error, _) => error.toString(),
                      data: (_) => null,
                      loading: () => null,
                    ),
                  ),
                  MetricCard(
                    label: 'Reports',
                    icon: Icons.flag_outlined,
                    color: AppTheme.saffron,
                    value: reports.when(
                      data: (items) => items.length.toString(),
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
                        RecentOffersCard(offers: offers),
                        const SizedBox(height: 18),
                        const QuickActionsCard(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 18) * 0.62,
                        child: RecentOffersCard(offers: offers),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: (constraints.maxWidth - 18) * 0.38,
                        child: const QuickActionsCard(),
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
