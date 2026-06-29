import 'package:flutter/material.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/discovered_offer.dart';
import '../../domain/entities/discovered_offer_status.dart';

class DiscoveredOfferTile extends StatelessWidget {
  const DiscoveredOfferTile({
    required this.offer,
    required this.onCreateOfficialOffer,
    required this.onReject,
    required this.onMarkDuplicate,
    required this.busy,
    super.key,
  });

  final DiscoveredOffer offer;
  final VoidCallback? onCreateOfficialOffer;
  final VoidCallback? onReject;
  final VoidCallback? onMarkDuplicate;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextView.title(
                      offer.suggestedTitle.isEmpty
                          ? 'Untitled suggestion'
                          : offer.suggestedTitle,
                      fontWeight: FontWeight.w900,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    AppTextView.body(
                      offer.brandName,
                      color: AppColors.textMuted(brightness),
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
              AppBadge(
                label: DiscoveredOfferStatuses.label(offer.status),
                color: _statusColor(offer.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetaRow(
            icon: Icons.language_outlined,
            label:
                '${DiscoveredOfferSourceTypes.label(offer.sourceType)} · ${offer.sourceUrl}',
          ),
          if (offer.suggestedDiscountText.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.local_offer_outlined,
              label: offer.suggestedDiscountText,
            ),
          ],
          if (offer.suggestedDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppTextView.body(
              offer.suggestedDescription,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              color: AppColors.textMuted(brightness),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetaChip(
                icon: Icons.category_outlined,
                label: offer.suggestedCategoryCodes.isEmpty
                    ? 'No categories'
                    : offer.suggestedCategoryCodes.join(', '),
              ),
              _MetaChip(
                icon: Icons.location_city_outlined,
                label: offer.suggestedCityCodes.isEmpty
                    ? 'No cities'
                    : offer.suggestedCityCodes.join(', '),
              ),
              _MetaChip(
                icon: Icons.insights_outlined,
                label:
                    'Confidence ${(offer.confidenceScore * 100).toStringAsFixed(0)}%',
              ),
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: offer.createdAt.shortDate,
              ),
            ],
          ),
          if (offer.convertedOfferId.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.link_outlined,
              label: 'Official offer: ${offer.convertedOfferId}',
            ),
          ],
          if (offer.rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.info_outline,
              label: offer.rejectionReason,
            ),
          ],
          if (offer.status == DiscoveredOfferStatuses.pendingReview) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onCreateOfficialOffer,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Official Offer'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onMarkDuplicate,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Mark Duplicate'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      DiscoveredOfferStatuses.pendingReview => Colors.orange.shade800,
      DiscoveredOfferStatuses.converted => Colors.green.shade800,
      DiscoveredOfferStatuses.rejected => Colors.red.shade800,
      DiscoveredOfferStatuses.duplicate => Colors.blueGrey,
      DiscoveredOfferStatuses.sourceError => Colors.deepPurple,
      _ => Colors.black54,
    };
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black54,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
