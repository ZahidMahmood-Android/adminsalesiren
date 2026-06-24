import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_providers.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../domain/entities/app_role.dart';

final rolesCatalogProvider = StreamProvider.autoDispose<List<AppRole>>((ref) {
  return ref.watch(firestoreProvider).collection('roles').snapshots().map((
    snapshot,
  ) {
    final roles = snapshot.docs.map(_roleFromSnapshot).where((role) {
      return role.isActive;
    }).toList()..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order == 0 ? a.name.compareTo(b.name) : order;
    });
    return roles;
  });
});

const _fallbackRoles = [
  AppRole(
    id: UserRoles.superAdmin,
    name: 'Super Admin',
    description: 'Full platform access',
    sortOrder: 1,
  ),
  AppRole(
    id: UserRoles.brandAdmin,
    name: 'Brand Admin',
    description: 'Manage a brand and its offers',
    sortOrder: 2,
  ),
  AppRole(
    id: UserRoles.manager,
    name: 'Manager',
    description: 'Operational access without subscriptions',
    sortOrder: 3,
  ),
  AppRole(
    id: UserRoles.mobileUser,
    name: 'Mobile User',
    description: 'Sale Siren mobile app user',
    sortOrder: 4,
  ),
];

final assignableRolesProvider = Provider<List<AppRole>>((ref) {
  final catalog = ref.watch(rolesCatalogProvider).value;
  if (catalog != null && catalog.isNotEmpty) {
    return catalog;
  }
  return _fallbackRoles;
});

AppRole _roleFromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? <String, dynamic>{};
  return AppRole(
    id: data['id'] as String? ?? doc.id,
    name: data['name'] as String? ?? doc.id,
    description: data['description'] as String? ?? '',
    sortOrder: data['sortOrder'] as int? ?? 0,
    isActive: data['isActive'] as bool? ?? true,
  );
}
