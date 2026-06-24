import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../providers/subscription_providers.dart';

class BrandSubscriptionsListScreen extends ConsumerWidget {
  const BrandSubscriptionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(brandSubscriptionsProvider);
    final actionState = ref.watch(subscriptionActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      title: 'Brand Subscriptions',
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/subscriptions/brand-subscriptions/new'),
          icon: const Icon(Icons.add),
          label: const Text('Assign plan'),
        ),
      ],
      child: AnimatedContent(
        child: subscriptions.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                key: ValueKey('subs-empty'),
                icon: Icons.card_membership_outlined,
                title: 'No subscriptions',
                message: 'Assign a pricing plan to a brand.',
              );
            }
            return AppCard(
              key: const ValueKey('subs-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final sub = items[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: AppListTileMaterial(
                      child: ListTile(
                      title: AppTextView.title(
                        '${sub.planName} · ${sub.brandId}',
                        fontWeight: FontWeight.w700,
                      ),
                      subtitle: AppTextView.body(
                        sub.discountPercent > 0
                            ? '${sub.currency} ${sub.discountedPrice?.toStringAsFixed(0) ?? sub.monthlyPrice}/mo '
                                  '(${sub.discountPercent}% off) · '
                                  'Payment: ${sub.paymentStatus}'
                            : '${sub.currency} ${sub.monthlyPrice}/mo · '
                                  'Payment: ${sub.paymentStatus}',
                      ),
                      trailing: AppStatusChip(status: sub.status),
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
