import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../offers/domain/entities/offer.dart';

class RecentOffersCard extends StatelessWidget {
  const RecentOffersCard({required this.offers, super.key});

  final AsyncValue<List<Offer>> offers;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Recent offers',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          offers.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No offers yet.')),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: items.take(6).map((offer) {
                  return AppListTileMaterial(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.paper,
                        child: Icon(
                          offer.isPublished
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                          color: offer.isPublished
                              ? AppTheme.deepGreen
                              : AppTheme.saffron,
                        ),
                      ),
                      title: Text(
                        offer.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${offer.brandName} · ${offer.discountText}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Open offer',
                        onPressed: () => context.go('/offers/${offer.id}'),
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () =>
                const SizedBox(height: 180, child: AppListShimmer(itemCount: 4)),
            error: (error, _) => AppErrorView(error: error),
          ),
        ],
      ),
    );
  }
}
