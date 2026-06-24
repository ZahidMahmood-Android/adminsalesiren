import '../../auth/domain/entities/app_user.dart';
import '../../auth/domain/entities/user_role_utils.dart';
import '../../auth/domain/entities/user_roles.dart';
import 'app_feature_seed_data.dart';

class FeatureAccessUtils {
  const FeatureAccessUtils._();

  static bool grantsAllFeatures(AppUser user) => user.hasRole(UserRoles.owner);

  static List<String> defaultFeatureIdsForRoles(Iterable<String> roles) {
    final ids = <String>{};
    for (final role in roles) {
      final defaults = AppFeatureSeedData.defaultFeaturesByRole[role];
      if (defaults != null) {
        ids.addAll(defaults);
      }
    }
    return ids.toList()..sort();
  }

  static List<String> resolveFeatureIds(AppUser user) {
    if (UserRoleUtils.isMobileUserOnly(user.roles)) {
      return List<String>.from(AppFeatureIds.allMobile);
    }
    if (user.featureIds.isNotEmpty) {
      return List<String>.from(user.featureIds);
    }
    return defaultFeatureIdsForRoles(user.roles);
  }

  static bool hasFeature(AppUser user, String featureId) {
    if (grantsAllFeatures(user)) {
      return true;
    }
    return resolveFeatureIds(user).contains(featureId);
  }

  static bool canAccessAdminRoute(AppUser user, String location) {
    if (grantsAllFeatures(user)) {
      return true;
    }
    final featureId = adminFeatureIdForRoute(location);
    if (featureId == null) {
      return true;
    }
    return hasFeature(user, featureId);
  }

  static String? adminFeatureIdForRoute(String location) {
    if (location == '/dashboard') {
      return AppFeatureIds.adminDashboard;
    }
    if (location == '/profile') {
      return AppFeatureIds.adminProfile;
    }
    if (location == '/reports') {
      return AppFeatureIds.adminReports;
    }
    if (location == '/notifications') {
      return AppFeatureIds.adminNotifications;
    }
    if (location == '/settings') {
      return AppFeatureIds.adminSettings;
    }
    if (location.startsWith('/cities')) {
      return AppFeatureIds.adminCities;
    }
    if (location.startsWith('/categories')) {
      return AppFeatureIds.adminCategories;
    }
    if (location.startsWith('/brands')) {
      return AppFeatureIds.adminBrands;
    }
    if (location.startsWith('/users')) {
      return AppFeatureIds.adminUsers;
    }
    if (location.startsWith('/offers')) {
      return AppFeatureIds.adminOffers;
    }
    if (location.startsWith('/subscriptions/plans')) {
      return AppFeatureIds.adminPricingPlans;
    }
    if (location.startsWith('/subscriptions/brand-subscriptions')) {
      return AppFeatureIds.adminBrandSubscriptions;
    }
    if (location.startsWith('/subscriptions/payments')) {
      return AppFeatureIds.adminPayments;
    }
    if (location == '/subscriptions/usage') {
      return AppFeatureIds.adminUsage;
    }
    if (location == '/subscriptions/requests') {
      return AppFeatureIds.adminPlanRequests;
    }
    if (location == '/subscriptions/my') {
      return AppFeatureIds.adminMySubscription;
    }
    if (location == '/subscriptions/my-usage') {
      return AppFeatureIds.adminMyUsage;
    }
    if (location == '/subscriptions/request') {
      return AppFeatureIds.adminSubscriptionRequest;
    }
    return null;
  }

  static const mobileTabFeatureIds = [
    AppFeatureIds.mobileHome,
    AppFeatureIds.mobileCategories,
    AppFeatureIds.mobileFavorites,
    AppFeatureIds.mobileAlerts,
    AppFeatureIds.mobileSettings,
  ];
}
