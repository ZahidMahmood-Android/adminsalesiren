import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/notification_providers.dart';

class NotificationRequestsScreen extends ConsumerWidget {
  const NotificationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(notificationRequestsProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final isBrandAdmin = ref.watch(isBrandAdminProvider);
    final actionState = ref.watch(notificationRequestActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      header: const ScreenHeader(title: 'Notification Requests'),
      child: AnimatedContent(
        child: requests.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                key: ValueKey('notif-empty'),
                icon: Icons.notifications_none_outlined,
                title: 'No notification requests',
                message: 'Requests appear when a brand submits an offer.',
              );
            }
            return AppCard(
              key: const ValueKey('notif-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final request = items[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      title: Text(request.title),
                      subtitle: Text(
                        '${request.body}\nBrand: ${request.brandId} · Offer: ${request.offerId}',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppBadge(
                            label: request.status,
                            color: request.status == 'approved'
                                ? Colors.green
                                : request.status == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                          ),
                          if (request.offerId.isNotEmpty)
                            IconButton(
                              tooltip: 'Preview offer',
                              onPressed: () =>
                                  context.go('/offers/${request.offerId}'),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                          if (isBrandAdmin &&
                              request.status == 'pending' &&
                              request.offerId.isNotEmpty)
                            IconButton(
                              tooltip: 'Publish offer',
                              onPressed: actionState.isLoading
                                  ? null
                                  : () async {
                                      final confirmed =
                                          await showSweetConfirmationDialog(
                                            context: context,
                                            title: 'Publish offer?',
                                            message:
                                                'This will publish the offer and approve its notification request.',
                                            confirmLabel: 'Publish',
                                            icon: Icons.campaign_outlined,
                                          );
                                      if (!confirmed || !context.mounted) {
                                        return;
                                      }
                                      await ref
                                          .read(
                                            notificationRequestActionsProvider
                                                .notifier,
                                          )
                                          .publishRequest(
                                            requestId: request.id,
                                            offerId: request.offerId,
                                          );
                                    },
                              icon: const Icon(Icons.publish_outlined),
                            ),
                          if (isSuperAdmin && request.status == 'pending') ...[
                            IconButton(
                              tooltip: 'Approve',
                              onPressed: () => ref
                                  .read(
                                    notificationRequestActionsProvider.notifier,
                                  )
                                  .updateStatus(request.id, 'approved'),
                              icon: const Icon(Icons.check_circle_outline),
                            ),
                            IconButton(
                              tooltip: 'Reject',
                              onPressed: () => ref
                                  .read(
                                    notificationRequestActionsProvider.notifier,
                                  )
                                  .updateStatus(request.id, 'rejected'),
                              icon: const Icon(Icons.cancel_outlined),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () =>
              const AppLoadingView(label: 'Loading notification requests'),
          error: (error, _) => AppErrorView(message: error.toString()),
        ),
      ),
    );
  }
}
