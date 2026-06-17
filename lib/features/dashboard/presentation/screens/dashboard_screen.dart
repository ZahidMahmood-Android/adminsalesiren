import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/presentation/providers/offer_providers.dart';
import '../providers/dashboard_analytics_providers.dart';
import '../widgets/analytics_bar_chart.dart';
import '../widgets/metric_card.dart';
import '../widgets/recent_offers_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final currentUser = ref.watch(currentUserProvider);
    final brands = ref.watch(brandsProvider);
    final offers = isSuperAdmin
        ? const AsyncValue<List<Offer>>.data(<Offer>[])
        : ref.watch(offersProvider);
    final currentUserOffers = offers.whenData(
      (items) => items
          .where(
            (offer) =>
                offer.createdByUserId == currentUser?.id ||
                offer.createdBy == currentUser?.id,
          )
          .toList(),
    );
    final cities = ref.watch(visibleCitiesProvider);
    final categories = ref.watch(visibleCategoriesProvider);
    final analytics = isSuperAdmin
        ? ref.watch(dashboardAnalyticsProvider)
        : null;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: screenPadding(context),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  if (analytics != null)
                    MetricCard(
                      label: 'Users',
                      icon: Icons.people_outline,
                      color: AppTheme.deepGreen,
                      value: analytics.when(
                        data: (data) => data.totalUsers.toString(),
                        loading: () => '-',
                        error: (error, _) => '!',
                      ),
                      errorMessage: analytics.when(
                        error: (error, _) => error.toString(),
                        data: (_) => null,
                        loading: () => null,
                      ),
                    ),
                  if (isSuperAdmin)
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
                  if (!isSuperAdmin)
                    MetricCard(
                      label: 'Offers',
                      icon: Icons.campaign_outlined,
                      color: AppTheme.coral,
                      value: currentUserOffers.when(
                        data: (items) => items.length.toString(),
                        loading: () => '-',
                        error: (error, _) => '!',
                      ),
                      errorMessage: currentUserOffers.when(
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
                ],
              ),
              const SizedBox(height: 24),
              if (analytics != null) ...[
                analytics.when(
                  data: (data) => LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 860;
                      final platform = AnalyticsBarChart(
                        title: 'Platform analytics',
                        values: data.platformCounts,
                      );
                      return wide
                          ? Row(children: [Expanded(child: platform)])
                          : platform;
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
              ],
              if (!isSuperAdmin) RecentOffersCard(offers: currentUserOffers),
            ]),
          ),
        ),
      ],
    );
  }
}
