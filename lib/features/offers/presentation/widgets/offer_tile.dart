import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../domain/entities/offer.dart';
import '../providers/offer_providers.dart';

class OfferTile extends ConsumerWidget {
  const OfferTile({required this.offer, super.key});

  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(offerActionsProvider);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 58,
          height: 58,
          child: offer.imageUrl.isEmpty
              ? ColoredBox(
                  color: AppTheme.paper,
                  child: Icon(
                    Icons.local_offer_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Image.network(offer.imageUrl, fit: BoxFit.cover),
        ),
      ),
      title: Text(
        offer.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(offer.brandName),
            Text(offer.discountText),
            Text('${offer.startDate.shortDate} - ${offer.endDate.shortDate}'),
          ],
        ),
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppBadge(
            label: offer.isPublished ? 'Published' : 'Draft',
            color: offer.isPublished ? AppTheme.deepGreen : Colors.black45,
          ),
          AppBadge(
            label: offer.isVerified ? 'Verified' : 'Unverified',
            color: offer.isVerified ? AppTheme.freshGreen : AppTheme.saffron,
          ),
          IconButton(
            tooltip: offer.isPublished ? 'Unpublish' : 'Publish',
            onPressed: actionState.isLoading
                ? null
                : () => ref
                      .read(offerActionsProvider.notifier)
                      .publish(offer.id, !offer.isPublished),
            icon: Icon(
              offer.isPublished
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Delete offer',
            onPressed: actionState.isLoading
                ? null
                : () async {
                    final confirmed = await showSweetConfirmationDialog(
                      context: context,
                      title: 'Delete offer?',
                      message:
                          'This will remove ${offer.title} permanently.',
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
