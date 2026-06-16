import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/brand_usage.dart';
import '../providers/subscription_providers.dart';

class MySubscriptionScreen extends ConsumerWidget {
  const MySubscriptionScreen({super.key});

  BrandUsage? _currentUsage(List<BrandUsage> items, String? brandId) {
    if (brandId == null || brandId.isEmpty) return null;
    final now = DateTime.now();
    for (final row in items) {
      if (row.brandId == brandId &&
          row.year == now.year &&
          row.month == now.month) {
        return row;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(activeBrandSubscriptionProvider);
    final usage = ref.watch(brandUsageProvider);
    final user = ref.watch(currentUserProvider);

    return ScreenScaffold(
      header: ScreenHeader(
        title: 'My Subscription',
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/subscriptions/request'),
            icon: const Icon(Icons.upgrade),
            label: const Text('Upgrade / Renew'),
          ),
        ],
      ),
      child: AnimatedContent(
        child: subscription.when(
          data: (sub) {
            if (sub == null) {
              return AppCard(
                key: const ValueKey('no-sub'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No active subscription.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go('/subscriptions/request'),
                      child: const Text('Request a plan'),
                    ),
                  ],
                ),
              );
            }
            final currentUsage = usage.maybeWhen(
              data: (items) => _currentUsage(items, user?.brandId),
              orElse: () => null,
            );
            return ListView(
              key: const ValueKey('sub-detail'),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            sub.planName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          AppBadge(
                            label: sub.status,
                            color: sub.isUsable ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sub.discountPercent > 0
                            ? '${sub.currency} ${sub.effectivePrice.toStringAsFixed(0)}/${sub.billingCycle} '
                                  '(${sub.discountPercent}% discount applied)'
                            : '${sub.currency} ${sub.monthlyPrice}/${sub.billingCycle}',
                      ),
                      Text('Payment: ${sub.paymentStatus}'),
                      if (sub.endDate != null)
                        Text(
                          'Ends: ${sub.endDate!.toLocal().toString().split(' ').first}',
                        ),
                      const Divider(),
                      Text(
                        'Limits: ${sub.offerLimitPerMonth} offers/mo · '
                        '${sub.activeOfferLimit} active · '
                        '${sub.pushNotificationLimitPerMonth} push · '
                        '${sub.featuredOfferLimitPerMonth} featured',
                      ),
                      Text('Analytics: ${sub.analyticsLevel}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This month usage',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (currentUsage == null)
                        const Text('No usage recorded yet this month.')
                      else ...[
                        _UsageRow(
                          label: 'Offers created',
                          used: currentUsage.offersCreated,
                          limit: sub.offerLimitPerMonth,
                        ),
                        const SizedBox(height: 6),
                        _UsageRow(
                          label: 'Push requests',
                          used: currentUsage.pushNotificationsRequested,
                          limit: sub.pushNotificationLimitPerMonth,
                        ),
                        const SizedBox(height: 6),
                        _UsageRow(
                          label: 'Featured used',
                          used: currentUsage.featuredOffersUsed,
                          limit: sub.featuredOfferLimitPerMonth,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go('/subscriptions/payments'),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Payment history'),
                ),
              ],
            );
          },
          loading: () => const AppLoadingView(label: 'Loading subscription'),
          error: (error, _) => AppErrorView(message: error.toString()),
        ),
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.label,
    required this.used,
    required this.limit,
  });

  final String label;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final pct = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final color = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
        ? Colors.orange
        : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '$used / $limit',
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            color: color,
            backgroundColor: color.withAlpha(40),
          ),
        ),
      ],
    );
  }
}
