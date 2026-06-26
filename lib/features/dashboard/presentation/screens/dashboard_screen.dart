import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/brand_dashboard_stats_provider.dart';
import '../providers/dashboard_analytics_providers.dart';
import '../widgets/analytics_stat_chart.dart';
import '../widgets/animated_metric_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isOwnerProvider);
    final analytics = isOwner ? ref.watch(dashboardAnalyticsProvider) : null;
    final brandStats = isOwner ? null : ref.watch(brandDashboardStatsProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: screenPadding(context),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Live statistics and offer performance at a glance.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 22),
              if (isOwner && analytics != null)
                _OwnerDashboard(analytics: analytics)
              else if (brandStats != null)
                _BrandDashboard(stats: brandStats),
            ]),
          ),
        ),
      ],
    );
  }
}

class _OwnerDashboard extends StatelessWidget {
  const _OwnerDashboard({required this.analytics});

  final AsyncValue<DashboardAnalytics> analytics;

  @override
  Widget build(BuildContext context) {
    return analytics.when(
      loading: () => const AppFormShimmer(),
      error: (error, _) => AppErrorView(error: error),
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricGrid(
              children: [
                AnimatedMetricCard(
                  label: 'Users',
                  value: data.totalUsers,
                  icon: Icons.people_outline,
                  color: AppTheme.deepGreen,
                  subtitle: 'Registered accounts',
                ),
                AnimatedMetricCard(
                  label: 'Brands',
                  value: data.totalBrands,
                  icon: Icons.storefront_outlined,
                  color: AppTheme.freshGreen,
                  subtitle: 'Active brand profiles',
                ),
                AnimatedMetricCard(
                  label: 'Offers',
                  value: data.totalOffers,
                  icon: Icons.local_offer_outlined,
                  color: AppTheme.coral,
                  subtitle: 'Total offers in system',
                ),
                AnimatedMetricCard(
                  label: 'Published',
                  value: data.publishedOffers,
                  icon: Icons.campaign_outlined,
                  color: Colors.green.shade700,
                  subtitle: 'Live on mobile',
                ),
                AnimatedMetricCard(
                  label: 'Pending review',
                  value: data.pendingOffers,
                  icon: Icons.hourglass_top_outlined,
                  color: AppTheme.saffron,
                  subtitle: 'Awaiting approval',
                ),
                AnimatedMetricCard(
                  label: 'Verified',
                  value: data.verifiedOffers,
                  icon: Icons.verified_outlined,
                  color: Colors.teal.shade700,
                  subtitle: 'Verified offers',
                ),
              ],
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 920;
                final offerChart = AnalyticsStatChart(
                  title: 'Offer status mix',
                  subtitle: 'Published, pending, and rejected offers',
                  segments: [
                    ChartSegment(
                      label: 'Published',
                      value: data.publishedOffers,
                      color: Colors.green.shade600,
                    ),
                    ChartSegment(
                      label: 'Pending',
                      value: data.pendingOffers,
                      color: AppTheme.saffron,
                    ),
                    ChartSegment(
                      label: 'Rejected',
                      value: data.rejectedOffers,
                      color: Colors.red.shade400,
                    ),
                  ],
                );
                final platformChart = AnalyticsStatChart(
                  title: 'Platform footprint',
                  subtitle: 'Core catalog and audience size',
                  segments: [
                    ChartSegment(
                      label: 'Users',
                      value: data.totalUsers,
                      color: AppTheme.deepGreen,
                    ),
                    ChartSegment(
                      label: 'Brands',
                      value: data.totalBrands,
                      color: AppTheme.freshGreen,
                    ),
                    ChartSegment(
                      label: 'Offers',
                      value: data.totalOffers,
                      color: AppTheme.coral,
                    ),
                  ],
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: offerChart),
                      const SizedBox(width: 18),
                      Expanded(child: platformChart),
                    ],
                  );
                }
                return Column(
                  children: [
                    offerChart,
                    const SizedBox(height: 18),
                    platformChart,
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _BrandDashboard extends StatelessWidget {
  const _BrandDashboard({required this.stats});

  final AsyncValue<BrandDashboardStats> stats;

  @override
  Widget build(BuildContext context) {
    return stats.when(
      loading: () => const AppFormShimmer(),
      error: (error, _) => AppErrorView(error: error),
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricGrid(
              children: [
                AnimatedMetricCard(
                  label: 'Your offers',
                  value: data.totalOffers,
                  icon: Icons.local_offer_outlined,
                  color: AppTheme.coral,
                  subtitle: 'Created by your account',
                ),
                AnimatedMetricCard(
                  label: 'Published',
                  value: data.publishedOffers,
                  icon: Icons.campaign_outlined,
                  color: Colors.green.shade700,
                  subtitle: 'Visible to shoppers',
                ),
                AnimatedMetricCard(
                  label: 'Pending review',
                  value: data.pendingOffers,
                  icon: Icons.hourglass_top_outlined,
                  color: AppTheme.saffron,
                  subtitle: 'Waiting for approval',
                ),
                AnimatedMetricCard(
                  label: 'Verified',
                  value: data.verifiedOffers,
                  icon: Icons.verified_outlined,
                  color: Colors.teal.shade700,
                  subtitle: 'Quality-checked offers',
                ),
                AnimatedMetricCard(
                  label: 'Featured',
                  value: data.featuredOffers,
                  icon: Icons.star_outline,
                  color: AppTheme.deepGreen,
                  subtitle: 'Highlighted placements',
                ),
                AnimatedMetricCard(
                  label: 'Expired',
                  value: data.expiredOffers,
                  icon: Icons.event_busy_outlined,
                  color: Colors.blueGrey,
                  subtitle: 'No longer active',
                ),
              ],
            ),
            const SizedBox(height: 22),
            AnalyticsStatChart(
              title: 'Your offer breakdown',
              subtitle: 'How your offers are distributed right now',
              segments: [
                ChartSegment(
                  label: 'Published',
                  value: data.publishedOffers,
                  color: Colors.green.shade600,
                ),
                ChartSegment(
                  label: 'Pending',
                  value: data.pendingOffers,
                  color: AppTheme.saffron,
                ),
                ChartSegment(
                  label: 'Featured',
                  value: data.featuredOffers,
                  color: AppTheme.deepGreen,
                ),
                ChartSegment(
                  label: 'Expired',
                  value: data.expiredOffers,
                  color: Colors.blueGrey,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 3
            : width >= 760
            ? 2
            : 1;
        const spacing = 14.0;
        final itemWidth = columns == 1
            ? width
            : (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}
