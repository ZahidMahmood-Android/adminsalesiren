import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/display_label_utils.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/offer.dart';
import '../providers/offer_providers.dart';
import '../../../notifications/presentation/widgets/offer_publish_notification_flow.dart';
import '../../../settings/presentation/providers/alert_settings_ui.dart';
import '../widgets/info_grid.dart';
import '../../../../core/widgets/screen_layout.dart';

class OfferDetailsScreen extends ConsumerWidget {
  const OfferDetailsScreen({required this.offerId, super.key});

  final String offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerAsync = ref.watch(offerProvider(offerId));
    final actionState = ref.watch(offerActionsProvider);
    final isBusy = actionState.isLoading;
    final isOwner = ref.watch(isOwnerProvider);
    final isManager = ref.watch(isManagerProvider);

    return offerAsync.when(
      data: (offer) {
        if (offer == null) {
          return const AppErrorView(message: 'Offer not found.');
        }

        final canDeleteOffer = isOwner || isManager || !offer.isPublished;

        return AppLoadingOverlay(
          isLoading: isBusy,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: screenPadding(context),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  offer.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              // Expired offers are retired and should not be edited.
                              if (!offer.isExpired)
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      context.go('/offers/$offerId/edit'),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                ),
                              if (!offer.isExpired) const SizedBox(width: 10),
                              if (offer.isPublished && !offer.isExpired) ...[
                                OutlinedButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : () async {
                                          final confirmed =
                                              await showSweetConfirmationDialog(
                                                context: context,
                                                title: 'Expire offer?',
                                                message:
                                                    'This will retire ${offer.title} so you can create a replacement offer.',
                                                confirmLabel: 'Expire',
                                                icon: Icons.event_busy_outlined,
                                              );
                                          if (!confirmed || !context.mounted) {
                                            return;
                                          }
                                          await ref
                                              .read(
                                                offerActionsProvider.notifier,
                                              )
                                              .expire(offer.id);
                                        },
                                  icon: const Icon(Icons.event_busy_outlined),
                                  label: const Text('Expire'),
                                ),
                                const SizedBox(width: 10),
                              ],
                              if (canDeleteOffer)
                                IconButton(
                                  tooltip: 'Delete offer',
                                  onPressed: isBusy
                                      ? null
                                      : () async {
                                          final confirmed =
                                              await showSweetConfirmationDialog(
                                                context: context,
                                                title: 'Delete offer?',
                                                message:
                                                    'This will remove ${offer.title} and its images permanently.',
                                                confirmLabel: 'Delete',
                                              );
                                          if (!confirmed || !context.mounted) {
                                            return;
                                          }
                                          await ref
                                              .read(
                                                offerActionsProvider.notifier,
                                              )
                                              .delete(offer.id);
                                          if (context.mounted &&
                                              !ref
                                                  .read(offerActionsProvider)
                                                  .hasError) {
                                            context.go('/offers');
                                          }
                                        },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (offer.imageUrls.isNotEmpty ||
                                    offer.imageUrl.isNotEmpty)
                                  _OfferImagePreview(offer: offer),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          AppBadge(
                                            label: _statusLabel(offer),
                                            color: _statusColor(offer),
                                          ),
                                          AppBadge(
                                            label: offer.isVerified
                                                ? 'Verified'
                                                : 'Unverified',
                                            color: offer.isVerified
                                                ? AppTheme.freshGreen
                                                : AppTheme.saffron,
                                          ),
                                          if (offer.isFeatured)
                                            const AppBadge(
                                              label: 'Featured',
                                              color: AppTheme.coral,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      InfoGrid(
                                        entries: {
                                          'Brand': offer.brandName,
                                          'Category': offer.categoryName,
                                          'Cities': offer.cityNames.isEmpty
                                              ? offer.cityName
                                              : offer.cityNames.join(', '),
                                          'Discount': offer.discountText,
                                          'Dates':
                                              '${offer.startDate.shortDate} - ${offer.scheduleEndLabel}',
                                          'Created':
                                              offer.createdAt.compactDateTime,
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        offer.description.isEmpty
                                            ? 'No description provided.'
                                            : offer.description,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 22),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          if (isOwner) ...[
                                            if (offer.approvalStatus ==
                                                    'pending' ||
                                                offer.status ==
                                                    'pending_review') ...[
                                              FilledButton.icon(
                                                onPressed: isBusy
                                                    ? null
                                                    : () => ref
                                                          .read(
                                                            offerActionsProvider
                                                                .notifier,
                                                          )
                                                          .approve(offer.id),
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                ),
                                                label: const Text('Approve'),
                                              ),
                                              OutlinedButton.icon(
                                                onPressed: isBusy
                                                    ? null
                                                    : () async {
                                                        final notes =
                                                            await _rejectionNotes(
                                                              context,
                                                            );
                                                        if (notes == null) {
                                                          return;
                                                        }
                                                        await ref
                                                            .read(
                                                              offerActionsProvider
                                                                  .notifier,
                                                            )
                                                            .reject(
                                                              offer.id,
                                                              notes,
                                                            );
                                                      },
                                                icon: const Icon(
                                                  Icons.cancel_outlined,
                                                ),
                                                label: const Text('Reject'),
                                              ),
                                            ],
                                            if (!offer.isPublished)
                                              FilledButton.icon(
                                                onPressed: isBusy
                                                    ? null
                                                    : () async {
                                                        final alertOptions =
                                                            readAlertNotificationOptions(
                                                          ref,
                                                        );
                                                        final drafts =
                                                            await confirmOfferNotificationDrafts(
                                                              context,
                                                              offer,
                                                              enabledSlugs: alertOptions
                                                                  .enabledSlugs,
                                                              selectableAlertTypes:
                                                                  alertOptions
                                                                      .selectableAlertTypes,
                                                              alertTypeLabels:
                                                                  alertOptions
                                                                      .alertTypeLabels,
                                                            );
                                                        if (drafts == null ||
                                                            !context.mounted) {
                                                          return;
                                                        }
                                                        await ref
                                                            .read(
                                                              offerActionsProvider
                                                                  .notifier,
                                                            )
                                                            .publish(
                                                              offer.id,
                                                              true,
                                                              notificationDrafts:
                                                                  drafts,
                                                            );
                                                      },
                                                icon: const Icon(
                                                  Icons.visibility_outlined,
                                                ),
                                                label: const Text('Publish'),
                                              ),
                                            SizedBox(
                                              width: 220,
                                              child: DropdownButtonFormField<bool>(
                                                initialValue: offer.isVerified,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Verification',
                                                      prefixIcon: Icon(
                                                        Icons.verified_outlined,
                                                      ),
                                                    ),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: true,
                                                    child: Text('Verified'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: false,
                                                    child: Text('Unverified'),
                                                  ),
                                                ],
                                                onChanged:
                                                    isBusy ||
                                                        offer.isExpired ||
                                                        offer.isPublished
                                                    ? null
                                                    : (value) {
                                                        if (value == null ||
                                                            value ==
                                                                offer
                                                                    .isVerified) {
                                                          return;
                                                        }
                                                        ref
                                                            .read(
                                                              offerActionsProvider
                                                                  .notifier,
                                                            )
                                                            .verify(
                                                              offer.id,
                                                              value,
                                                            );
                                                      },
                                              ),
                                            ),
                                            if (!offer.isPublished)
                                              OutlinedButton.icon(
                                                onPressed:
                                                    isBusy ||
                                                        (!offer.isVerified &&
                                                            !offer.isFeatured)
                                                    ? null
                                                    : () => ref
                                                          .read(
                                                            offerActionsProvider
                                                                .notifier,
                                                          )
                                                          .feature(
                                                            offer.id,
                                                            !offer.isFeatured,
                                                          ),
                                                icon: const Icon(
                                                  Icons.star_outline,
                                                ),
                                                label: Text(
                                                  offer.isFeatured
                                                      ? 'Remove featured'
                                                      : 'Feature',
                                                ),
                                              ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const AppLoader(),
      error: (error, _) => AppErrorView(error: error),
    );
  }
}

class _OfferImagePreview extends StatelessWidget {
  const _OfferImagePreview({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final urls = offer.imageUrls.isEmpty
        ? [offer.imageUrl].where((url) => url.isNotEmpty).toList()
        : offer.imageUrls;
    if (offer.imageDisplayMode == 'grid') {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: urls.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 16 / 10,
          ),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AppNetworkImage(imageUrl: urls[index]),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: SizedBox(
        height: 230,
        child: PageView.builder(
          itemCount: urls.length,
          itemBuilder: (context, index) =>
              AppNetworkImage(imageUrl: urls[index]),
        ),
      ),
    );
  }
}

String _statusLabel(dynamic offer) {
  if (offer.isExpired) {
    return 'Expired';
  }
  if (offer.status == 'published' || offer.isPublished) {
    return 'Published';
  }
  if (offer.status == 'pending_review' || offer.status == 'pending') {
    return 'Pending Review';
  }
  if (offer.status == 'rejected') {
    return 'Rejected';
  }
  if (offer.status == 'draft') {
    return 'Draft';
  }
  return DisplayLabelUtils.slug(offer.status, fallback: 'Pending Review');
}

Color _statusColor(dynamic offer) {
  if (offer.isExpired) {
    return AppColors.inkMuted;
  }
  if (offer.status == 'published' || offer.isPublished) {
    return AppTheme.deepGreen;
  }
  if (offer.status == 'pending_review' || offer.status == 'pending') {
    return AppColors.pendingReview;
  }
  if (offer.status == 'rejected') {
    return Colors.red;
  }
  if (offer.status == 'draft') {
    return AppColors.inkMuted;
  }
  return AppColors.pendingReview;
}

Future<String?> _rejectionNotes(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reject offer'),
      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 4,
        decoration: const InputDecoration(labelText: 'Approval notes'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    ),
  );
}
