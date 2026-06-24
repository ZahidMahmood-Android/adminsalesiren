import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_providers.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/app_feature_seed_data.dart';
import '../../domain/entities/app_feature.dart';
import '../../domain/feature_access_utils.dart';

final appFeaturesCatalogProvider = StreamProvider.autoDispose<List<AppFeature>>(
  (ref) {
    return ref
        .watch(firestoreProvider)
        .collection('app_features')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return List<AppFeature>.from(AppFeatureSeedData.records)
              ..sort((a, b) {
                final platform = a.platform.compareTo(b.platform);
                if (platform != 0) {
                  return platform;
                }
                final order = a.sortOrder.compareTo(b.sortOrder);
                return order == 0 ? a.name.compareTo(b.name) : order;
              });
          }

          final features =
              snapshot.docs.map(_featureFromSnapshot).where((feature) {
                return feature.isActive;
              }).toList()..sort((a, b) {
                final platform = a.platform.compareTo(b.platform);
                if (platform != 0) {
                  return platform;
                }
                final order = a.sortOrder.compareTo(b.sortOrder);
                return order == 0 ? a.name.compareTo(b.name) : order;
              });
          return features;
        });
  },
);

final currentUserFeatureIdsProvider = Provider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const {};
  }
  return FeatureAccessUtils.resolveFeatureIds(user).toSet();
});

final canAccessAdminRouteProvider = Provider.family<bool, String>((
  ref,
  location,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return false;
  }
  return FeatureAccessUtils.canAccessAdminRoute(user, location);
});

AppFeature _featureFromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? <String, dynamic>{};
  return AppFeature(
    id: data['id'] as String? ?? doc.id,
    name: data['name'] as String? ?? doc.id,
    platform: data['platform'] as String? ?? AppFeaturePlatforms.adminPanel,
    description: data['description'] as String? ?? '',
    route: data['route'] as String? ?? '',
    sortOrder: data['sortOrder'] as int? ?? 0,
    isActive: data['isActive'] as bool? ?? true,
  );
}

List<String> readFeatureIds(Map<String, dynamic> data) {
  final raw = data['featureIds'];
  if (raw is! Iterable) {
    return const [];
  }
  return raw.whereType<String>().where((value) => value.isNotEmpty).toList();
}

void applyDefaultFeaturesForRoles({
  required Set<String> selectedRoleIds,
  required void Function(Set<String> featureIds) apply,
}) {
  apply(defaultFeatureIdsForRoles(selectedRoleIds).toSet());
}

Set<String> defaultFeatureIdsForRoles(Set<String> roleIds) {
  return FeatureAccessUtils.defaultFeatureIdsForRoles(roleIds).toSet();
}

bool userHasFeature(AppUser? user, String featureId) {
  if (user == null) {
    return false;
  }
  return FeatureAccessUtils.hasFeature(user, featureId);
}
