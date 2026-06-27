import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/delete_action_utils.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/display_label_utils.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../domain/entities/offer.dart';
import '../providers/offer_providers.dart';
import '../../../notifications/presentation/widgets/offer_publish_notification_flow.dart';
import '../../../settings/presentation/providers/alert_settings_ui.dart';
import 'offer_lines_editor.dart';

class OfferTile extends ConsumerWidget {
  const OfferTile({required this.offer, super.key});

  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(offerActionsProvider);
    final cities = ref.watch(visibleCitiesProvider);
    final isOwner = ref.watch(isOwnerProvider);
    final isManager = ref.watch(isManagerProvider);
    final canDeleteOffer = isOwner || isManager || !offer.isPublished;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 92,
              height: 74,
              child: AppNetworkImage(
                imageUrl: offer.imageUrl,
                fit: BoxFit.cover,
                icon: Icons.local_offer_outlined,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.title(
                  offer.title,
                  fontWeight: FontWeight.w900,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppTextView.body(offer.discountText),
                    AppTextView.label(
                      offerCitiesDisplayLabel(offer, allCities: cities.value),
                      color: AppColors.textMuted(
                        Theme.of(context).colorScheme.brightness,
                      ),
                    ),
                    AppTextView.label(
                      '${offer.startDate.shortDate} - ${offer.scheduleEndLabel}',
                      color: AppColors.textMuted(
                        Theme.of(context).colorScheme.brightness,
                      ),
                    ),
                    if (offer.isGroupOffer)
                      AppBadge(
                        label: '${offer.resolvedLines.length} lines',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AppBadge(
                      label: _statusPillLabel(offer),
                      color: _statusPillColor(offer),
                    ),
                    AppBadge(
                      label: offer.isVerified ? 'Verified' : 'Unverified',
                      color: offer.isVerified ? Colors.green : Colors.orange,
                    ),
                    if (offer.isFeatured)
                      const AppBadge(label: 'Featured', color: AppColors.coral),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isOwner && !offer.isPublished)
                IconButton(
                  tooltip: 'Publish',
                  onPressed: actionState.isLoading
                      ? null
                      : () async {
                          final alertOptions = readAlertNotificationOptions(
                            ref,
                          );
                          final drafts = await confirmOfferNotificationDrafts(
                            context,
                            offer,
                            enabledSlugs: alertOptions.enabledSlugs,
                            alertTypeLabels: alertOptions.alertTypeLabels,
                          );
                          if (drafts == null || !context.mounted) {
                            return;
                          }
                          await ref
                              .read(offerActionsProvider.notifier)
                              .publish(
                                offer.id,
                                true,
                                notificationDrafts: drafts,
                              );
                        },
                  icon: const Icon(Icons.visibility_outlined),
                ),
              if (canDeleteOffer)
                IconButton(
                  tooltip: 'Delete offer',
                  onPressed: actionState.isLoading
                      ? null
                      : () async {
                          final confirmed = await showSweetConfirmationDialog(
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
                              .read(offerActionsProvider.notifier)
                              .delete(offer.id);
                          if (!context.mounted) {
                            return;
                          }
                          await completeDeleteAction(
                            context,
                            ref.read(offerActionsProvider),
                            errorTitle: 'Could Not Delete Offer',
                          );
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
              if (offer.isPublished && !offer.isExpired)
                IconButton(
                  tooltip: 'Expire offer',
                  onPressed: actionState.isLoading
                      ? null
                      : () async {
                          final confirmed = await showSweetConfirmationDialog(
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
                              .read(offerActionsProvider.notifier)
                              .expire(offer.id);
                        },
                  icon: const Icon(Icons.event_busy_outlined),
                ),
              IconButton(
                tooltip: 'Duplicate offer',
                onPressed: actionState.isLoading
                    ? null
                    : () async {
                        final confirmed = await showSweetConfirmationDialog(
                          context: context,
                          title: 'Duplicate offer?',
                          message:
                              'This will create an editable copy of ${offer.title}.',
                          confirmLabel: 'Duplicate',
                          icon: Icons.copy_all_outlined,
                        );
                        if (!confirmed || !context.mounted) {
                          return;
                        }
                        final duplicateId = await ref
                            .read(offerActionsProvider.notifier)
                            .duplicate(offer.id);
                        if (duplicateId == null || !context.mounted) {
                          return;
                        }
                        context.go('/offers/$duplicateId/edit');
                      },
                icon: const Icon(Icons.copy_all_outlined),
              ),
              if (!offer.isExpired)
                IconButton(
                  tooltip: 'Edit offer',
                  onPressed: () => context.go('/offers/${offer.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              IconButton(
                tooltip: 'Open offer',
                onPressed: () => context.go('/offers/${offer.id}'),
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _statusPillLabel(Offer offer) {
  if (offer.isExpired) return 'Expired';
  if (offer.status == 'published' || offer.isPublished) return 'Published';
  if (offer.status == 'pending_review' || offer.status == 'pending') {
    return 'Pending Review';
  }
  if (offer.status == 'rejected') return 'Rejected';
  if (offer.status == 'draft') return 'Draft';
  return DisplayLabelUtils.slug(offer.status, fallback: 'Pending Review');
}

Color _statusPillColor(Offer offer) {
  if (offer.isExpired) return AppColors.inkMuted;
  if (offer.status == 'published' || offer.isPublished) return Colors.green;
  if (offer.status == 'pending_review' || offer.status == 'pending') {
    return AppColors.pendingReview;
  }
  if (offer.status == 'rejected') return Colors.red;
  if (offer.status == 'draft') return AppColors.inkMuted;
  return AppColors.pendingReview;
}
