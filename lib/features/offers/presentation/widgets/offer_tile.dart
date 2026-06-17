import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/offer.dart';
import '../providers/offer_providers.dart';

class OfferTile extends ConsumerWidget {
  const OfferTile({required this.offer, super.key});

  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(offerActionsProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 58,
          height: 58,
          child: offer.imageUrl.isEmpty
              ? ColoredBox(
                  color: AppColors.background(
                    Theme.of(context).colorScheme.brightness,
                  ),
                  child: Icon(
                    Icons.local_offer_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Image.network(offer.imageUrl, fit: BoxFit.cover),
        ),
      ),
      title: AppTextView.title(
        offer.title,
        fontWeight: FontWeight.w800,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppTextView.body(offer.brandName),
            AppTextView.body(
              offer.cityNames.isEmpty
                  ? offer.cityName
                  : offer.cityNames.join(', '),
            ),
            AppTextView.body(offer.discountText),
            AppTextView.label(
              '${offer.startDate.shortDate} – ${offer.endDate.shortDate}',
              color: AppColors.textMuted(
                Theme.of(context).colorScheme.brightness,
              ),
            ),
          ],
        ),
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppBadge(
            label: _statusPillLabel(offer),
            color: _statusPillColor(offer),
          ),
          AppBadge(
            label: offer.isVerified ? 'Verified' : 'Unverified',
            color: offer.isVerified ? Colors.green : Colors.orange,
          ),
          if (isSuperAdmin && !offer.isPublished)
            IconButton(
              tooltip: 'Publish',
              onPressed: actionState.isLoading
                  ? null
                  : () => ref
                        .read(offerActionsProvider.notifier)
                        .publish(offer.id, true),
              icon: const Icon(Icons.visibility_outlined),
            ),
          if (!offer.isPublished)
            IconButton(
              tooltip: 'Delete offer',
              onPressed: actionState.isLoading
                  ? null
                  : () async {
                      final confirmed = await showSweetConfirmationDialog(
                        context: context,
                        title: 'Delete offer?',
                        message: 'This will remove ${offer.title} permanently.',
                        confirmLabel: 'Delete',
                      );
                      if (!confirmed || !context.mounted) {
                        return;
                      }
                      await ref
                          .read(offerActionsProvider.notifier)
                          .delete(offer.id);
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
            tooltip: 'Open offer',
            onPressed: () => context.go('/offers/${offer.id}'),
            icon: const Icon(Icons.arrow_forward),
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
  return offer.status.isEmpty ? 'Pending Review' : offer.status;
}

Color _statusPillColor(Offer offer) {
  if (offer.isExpired) return Colors.black45;
  if (offer.status == 'published' || offer.isPublished) return Colors.green;
  if (offer.status == 'rejected') return Colors.red;
  return Colors.orange;
}
