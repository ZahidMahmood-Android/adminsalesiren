import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/utils/display_label_utils.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/subscription_providers.dart';

class PricingPlansListScreen extends ConsumerWidget {
  const PricingPlansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(pricingPlansProvider);
    final actions = ref.watch(subscriptionActionsProvider);
    final isOwner = ref.watch(isOwnerProvider);

    return ScreenScaffold(
      loading: actions.isLoading,
      title: 'Pricing Plans',
      actions: isOwner
          ? [
              OutlinedButton.icon(
                onPressed: actions.isLoading
                    ? null
                    : () async {
                        final count = await ref
                            .read(subscriptionActionsProvider.notifier)
                            .seedPricingPlans();
                        if (context.mounted) {
                          showAppSuccess(context, 'Seeded $count plans.');
                        }
                      },
                icon: const Icon(Icons.grass_outlined),
                label: const Text('Seed plans'),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/subscriptions/plans/new'),
                icon: const Icon(Icons.add),
                label: const Text('New plan'),
              ),
            ]
          : [],
      child: AnimatedContent(
        child: plans.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const ValueKey('plans-empty'),
                icon: Icons.payments_outlined,
                title: 'No pricing plans',
                message: 'Seed default plans or create a new plan.',
                action: FilledButton.icon(
                  onPressed: () => context.go('/subscriptions/plans/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New plan'),
                ),
              );
            }
            return AppCard(
              key: const ValueKey('plans-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final plan = items[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: AppListTileMaterial(
                      child: ListTile(
                        title: Text(
                          plan.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${plan.currency} ${plan.monthlyPrice}/mo · '
                          '${plan.offerLimitPerMonth} offers · '
                          '${plan.activeOfferLimit} active',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            if (!plan.isPublic)
                              const AppBadge(
                                label: 'Private',
                                color: Colors.grey,
                              ),
                            if (!plan.isActive)
                              const AppBadge(
                                label: 'Inactive',
                                color: Colors.red,
                              ),
                            AppBadge(
                              label: DisplayLabelUtils.slug(
                                plan.analyticsLevel,
                              ),
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        onTap: () =>
                            context.go('/subscriptions/plans/${plan.id}'),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const AppLoader(),
          error: (error, _) => AppErrorView(error: error),
        ),
      ),
    );
  }
}
