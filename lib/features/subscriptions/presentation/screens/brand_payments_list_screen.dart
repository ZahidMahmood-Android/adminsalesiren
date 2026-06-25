import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/display_label_utils.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/subscription_providers.dart';

class BrandPaymentsListScreen extends ConsumerWidget {
  const BrandPaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(brandPaymentsProvider);
    final isOwner = ref.watch(isOwnerProvider);
    final isBrandAdmin = ref.watch(isBrandAdminProvider);
    final isManager = ref.watch(isManagerProvider);
    final actionState = ref.watch(subscriptionActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      title: isOwner ? 'Manual Payments' : 'Payment History',
      actions: [
        if (isBrandAdmin && !isManager)
          FilledButton.icon(
            onPressed: () => context.go('/subscriptions/payments/new'),
            icon: const Icon(Icons.add),
            label: const Text('Submit Payment'),
          ),
      ],
      child: AnimatedContent(
        child: payments.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const ValueKey('payments-empty'),
                icon: Icons.receipt_long_outlined,
                title: 'No payments',
                message: isBrandAdmin && !isManager
                    ? 'Tap "Submit Payment" to record your first payment.'
                    : 'Manual payment records will appear here.',
              );
            }
            return AppCard(
              key: const ValueKey('payments-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final payment = items[index];
                  final brightness = Theme.of(context).colorScheme.brightness;

                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: AppListTileMaterial(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        title: AppTextView.title(
                          'PKR ${payment.amount}',
                          fontWeight: FontWeight.w800,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextView.body(
                              '${_methodLabel(payment.paymentMethod)}'
                              '${payment.transactionReference.isNotEmpty ? ' · ${payment.transactionReference}' : ''}',
                            ),
                            AppTextView.label(
                              '${payment.brandId} · ${_dateLabel(payment.paidAt ?? payment.createdAt)}',
                              color: AppColors.textMuted(brightness),
                            ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppStatusChip(status: payment.paymentStatus),
                            IconButton(
                              tooltip: 'View details',
                              onPressed: () => context.go(
                                '/subscriptions/payments/${payment.id}',
                              ),
                              icon: const Icon(Icons.open_in_new_outlined),
                            ),
                          ],
                        ),
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

  String _methodLabel(String method) => DisplayLabelUtils.slug(method);

  String _dateLabel(DateTime dt) {
    return dt.toLocal().toString().split(' ').first;
  }
}
