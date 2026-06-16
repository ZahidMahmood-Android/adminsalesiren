import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_providers.dart';

class DashboardAnalytics {
  const DashboardAnalytics({
    required this.totalUsers,
    required this.totalBrands,
    required this.totalOffers,
    required this.publishedOffers,
    required this.pendingOffers,
    required this.rejectedOffers,
  });

  final int totalUsers;
  final int totalBrands;
  final int totalOffers;
  final int publishedOffers;
  final int pendingOffers;
  final int rejectedOffers;

  Map<String, int> get offerStatusCounts => {
        'Published': publishedOffers,
        'Pending': pendingOffers,
        'Rejected': rejectedOffers,
      };

  Map<String, int> get platformCounts => {
        'Users': totalUsers,
        'Brands': totalBrands,
        'Offers': totalOffers,
      };
}

final dashboardAnalyticsProvider = StreamProvider.autoDispose<DashboardAnalytics>(
  (ref) {
    final firestore = ref.watch(firestoreProvider);
    return firestore.collection('offers').snapshots().asyncMap((offers) async {
      final users = await _count(firestore.collection('users'));
      final brands = await _count(firestore.collection('brands'));
      final items = offers.docs.map((doc) => doc.data()).toList();
      return DashboardAnalytics(
        totalUsers: users,
        totalBrands: brands,
        totalOffers: items.length,
        publishedOffers: items
            .where((item) => item['isPublished'] == true || item['status'] == 'published')
            .length,
        pendingOffers: items
            .where(
              (item) =>
                  item['approvalStatus'] == 'pending' ||
                  item['status'] == 'pending_review',
            )
            .length,
        rejectedOffers: items
            .where(
              (item) =>
                  item['approvalStatus'] == 'rejected' ||
                  item['status'] == 'rejected',
            )
            .length,
      );
    });
  },
);

Future<int> _count(CollectionReference<Map<String, dynamic>> collection) async {
  final snapshot = await collection.count().get();
  return snapshot.count ?? 0;
}
