import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/subscription_providers.dart';

class SubscriptionRequestsListScreen extends ConsumerWidget {
  const SubscriptionRequestsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(subscriptionRequestsProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final actions = ref.watch(subscriptionActionsProvider);

    return ScreenScaffold(
      loading: actions.isLoading,
      header: const ScreenHeader(title: 'Subscription Requests'),
      child: AnimatedContent(
        child: requests.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                key: ValueKey('sub-reqs-empty'),
                icon: Icons.upgrade_outlined,
                title: 'No requests',
                message: 'Upgrade and renewal requests appear here.',
              );
            }
            return AppCard(
              key: const ValueKey('sub-reqs-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final request = items[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: ListTile(
                      title: AppTextView.title(
                        '${request.type} · ${request.requestedPlanId}',
                        fontWeight: FontWeight.w700,
                      ),
                      subtitle: AppTextView.body(
                        'Brand: ${request.brandId}'
                        '${request.message.isNotEmpty ? '\n${request.message}' : ''}',
                      ),
                      isThreeLine: request.message.isNotEmpty,
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          AppStatusChip(status: request.status),
                          if (isSuperAdmin && request.status == 'pending')
                            IconButton(
                              tooltip: 'Approve & assign plan',
                              onPressed: actions.isLoading
                                  ? null
                                  : () => ref
                                        .read(
                                          subscriptionActionsProvider.notifier,
                                        )
                                        .approveSubscriptionRequest(request),
                              icon: const Icon(Icons.check_circle_outlined),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const AppLoadingView(label: 'Loading requests'),
          error: (error, _) => AppErrorView(message: error.toString()),
        ),
      ),
    );
  }
}
