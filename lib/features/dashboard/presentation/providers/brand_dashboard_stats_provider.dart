import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/presentation/providers/offer_providers.dart';

class BrandDashboardStats {
  const BrandDashboardStats({
    required this.totalOffers,
    required this.publishedOffers,
    required this.pendingOffers,
    required this.verifiedOffers,
    required this.featuredOffers,
    required this.expiredOffers,
  });

  final int totalOffers;
  final int publishedOffers;
  final int pendingOffers;
  final int verifiedOffers;
  final int featuredOffers;
  final int expiredOffers;

  factory BrandDashboardStats.fromOffers(List<Offer> offers) {
    return BrandDashboardStats(
      totalOffers: offers.length,
      publishedOffers: offers.where((offer) => offer.isPublished).length,
      pendingOffers: offers
          .where(
            (offer) =>
                offer.status == 'pending_review' || offer.status == 'pending',
          )
          .length,
      verifiedOffers: offers.where((offer) => offer.isVerified).length,
      featuredOffers: offers.where((offer) => offer.isFeatured).length,
      expiredOffers: offers.where((offer) => offer.isExpired).length,
    );
  }
}

final brandDashboardStatsProvider =
    Provider.autoDispose<AsyncValue<BrandDashboardStats>>((ref) {
      final offers = ref.watch(offersStreamProvider);
      final user = ref.watch(currentUserProvider);
      return offers.whenData((items) {
        final mine = items
            .where(
              (offer) =>
                  offer.createdByUserId == user?.id ||
                  offer.createdBy == user?.id,
            )
            .toList();
        return BrandDashboardStats.fromOffers(mine);
      });
    });
