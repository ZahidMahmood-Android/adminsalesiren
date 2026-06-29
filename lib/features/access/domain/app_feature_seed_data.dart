import '../../auth/domain/entities/user_roles.dart';
import 'entities/app_feature.dart';

class AppFeatureIds {
  const AppFeatureIds._();

  static const adminDashboard = 'admin_dashboard';
  static const adminCities = 'admin_cities';
  static const adminCategories = 'admin_categories';
  static const adminBrands = 'admin_brands';
  static const adminUsers = 'admin_users';
  static const adminReports = 'admin_reports';
  static const adminOffers = 'admin_offers';
  static const adminOfferDiscovery = 'admin_offer_discovery';
  static const adminNotifications = 'admin_notifications';
  static const adminPricingPlans = 'admin_pricing_plans';
  static const adminBrandSubscriptions = 'admin_brand_subscriptions';
  static const adminPayments = 'admin_payments';
  static const adminUsage = 'admin_usage';
  static const adminPlanRequests = 'admin_plan_requests';
  static const adminMySubscription = 'admin_my_subscription';
  static const adminMyUsage = 'admin_my_usage';
  static const adminSubscriptionRequest = 'admin_subscription_request';
  static const adminSettings = 'admin_settings';
  static const adminProfile = 'admin_profile';
  static const adminBugReportSubmit = 'admin_bug_report_submit';
  static const adminBugReports = 'admin_bug_reports';

  static const mobileHome = 'mobile_home';
  static const mobileCategories = 'mobile_categories';
  static const mobileFavorites = 'mobile_favorites';
  static const mobileBrands = 'mobile_brands';
  static const mobileAlerts = 'mobile_alerts';
  static const mobileSettings = 'mobile_settings';
  static const mobileSpotlight = 'mobile_spotlight';
  static const mobileReportOffer = 'mobile_report_offer';
  static const mobileReportBug = 'mobile_report_bug';

  static const allAdmin = [
    adminDashboard,
    adminCities,
    adminCategories,
    adminBrands,
    adminUsers,
    adminReports,
    adminOffers,
    adminOfferDiscovery,
    adminNotifications,
    adminPricingPlans,
    adminBrandSubscriptions,
    adminPayments,
    adminUsage,
    adminPlanRequests,
    adminMySubscription,
    adminMyUsage,
    adminSubscriptionRequest,
    adminSettings,
    adminProfile,
    adminBugReportSubmit,
    adminBugReports,
  ];

  static const allMobile = [
    mobileHome,
    mobileCategories,
    mobileFavorites,
    mobileBrands,
    mobileSettings,
    mobileSpotlight,
    mobileReportOffer,
    mobileReportBug,
  ];
}

class AppFeatureSeedData {
  const AppFeatureSeedData._();

  static final records = [
    _admin(
      AppFeatureIds.adminDashboard,
      'Dashboard',
      '/dashboard',
      1,
      'Overview, analytics, and quick stats.',
    ),
    _admin(
      AppFeatureIds.adminCities,
      'Cities',
      '/cities',
      2,
      'Manage supported cities and launch status.',
    ),
    _admin(
      AppFeatureIds.adminCategories,
      'Categories',
      '/categories',
      3,
      'Manage offer categories and catalog topics.',
    ),
    _admin(
      AppFeatureIds.adminBrands,
      'Brands',
      '/brands',
      4,
      'Manage brand profiles and registrations.',
    ),
    _admin(
      AppFeatureIds.adminUsers,
      'Users',
      '/users',
      5,
      'View and manage user accounts.',
    ),
    _admin(
      AppFeatureIds.adminReports,
      'Reports',
      '/reports',
      6,
      'Review flagged or reported offers.',
    ),
    _admin(
      AppFeatureIds.adminOffers,
      'Offers',
      '/offers',
      7,
      'Create, edit, publish, and verify offers.',
    ),
    _admin(
      AppFeatureIds.adminOfferDiscovery,
      'Offer Discovery',
      '/offer-discovery',
      8,
      'Review discovered offer suggestions from brand source URLs.',
    ),
    _admin(
      AppFeatureIds.adminNotifications,
      'Notification Requests',
      '/notifications',
      9,
      'Review push notification requests.',
    ),
    _admin(
      AppFeatureIds.adminPricingPlans,
      'Pricing Plans',
      '/subscriptions/plans',
      10,
      'Manage subscription pricing plans.',
    ),
    _admin(
      AppFeatureIds.adminBrandSubscriptions,
      'Brand Subscriptions',
      '/subscriptions/brand-subscriptions',
      11,
      'Assign plans to registered brands.',
    ),
    _admin(
      AppFeatureIds.adminPayments,
      'Payments',
      '/subscriptions/payments',
      12,
      'Record and verify brand payments.',
    ),
    _admin(
      AppFeatureIds.adminUsage,
      'Usage',
      '/subscriptions/usage',
      13,
      'Platform-wide subscription usage metrics.',
    ),
    _admin(
      AppFeatureIds.adminPlanRequests,
      'Plan Requests',
      '/subscriptions/requests',
      14,
      'Review brand upgrade and renewal requests.',
    ),
    _admin(
      AppFeatureIds.adminMySubscription,
      'My Subscription',
      '/subscriptions/my',
      15,
      'Brand admin subscription overview and billing.',
    ),
    _admin(
      AppFeatureIds.adminMyUsage,
      'My Usage',
      '/subscriptions/my-usage',
      16,
      'Brand admin usage against plan limits.',
    ),
    _admin(
      AppFeatureIds.adminSubscriptionRequest,
      'Request Upgrade',
      '/subscriptions/request',
      17,
      'Submit a subscription upgrade or renewal request.',
    ),
    _admin(
      AppFeatureIds.adminSettings,
      'Settings',
      '/settings',
      18,
      'Seed master data and platform settings.',
    ),
    _admin(
      AppFeatureIds.adminProfile,
      'My Profile',
      '/profile',
      19,
      'View and edit the signed-in admin profile.',
    ),
    _admin(
      AppFeatureIds.adminBugReportSubmit,
      'Report Bug',
      '/bug-reports/submit',
      20,
      'Submit bugs found in the admin panel.',
    ),
    _admin(
      AppFeatureIds.adminBugReports,
      'Bug Reports',
      '/bug-reports',
      21,
      'Review and resolve bugs reported from admin and mobile.',
    ),
    _mobile(
      AppFeatureIds.mobileHome,
      'Home',
      '/home',
      1,
      'Offer feed, spotlight, and latest deals.',
    ),
    _mobile(
      AppFeatureIds.mobileCategories,
      'Categories',
      '/categories',
      2,
      'Browse offers by category and brand.',
    ),
    _mobile(
      AppFeatureIds.mobileFavorites,
      'Favorites',
      '/home',
      3,
      'Saved offers and wishlist.',
    ),
    _mobile(
      AppFeatureIds.mobileBrands,
      'Brands',
      '/home',
      4,
      'Browse, search, and follow brands.',
    ),
    _mobile(
      AppFeatureIds.mobileSettings,
      'Settings',
      '/settings',
      5,
      'Account, preferences, and app settings.',
    ),
    _mobile(
      AppFeatureIds.mobileSpotlight,
      'Spotlight Offers',
      '/spotlight-offers',
      6,
      'Featured and spotlight offer collections.',
    ),
    _mobile(
      AppFeatureIds.mobileReportOffer,
      'Report Offer',
      '/report',
      7,
      'Report incorrect or expired offers.',
    ),
    _mobile(
      AppFeatureIds.mobileReportBug,
      'Report Bug',
      '/bug-report',
      8,
      'Report app crashes, UI issues, and other bugs.',
    ),
  ];

  static Map<String, List<String>> get defaultFeaturesByRole => {
    UserRoles.owner: AppFeatureIds.allAdmin,
    UserRoles.brandAdmin: [
      AppFeatureIds.adminDashboard,
      AppFeatureIds.adminCities,
      AppFeatureIds.adminCategories,
      AppFeatureIds.adminOffers,
      AppFeatureIds.adminOfferDiscovery,
      AppFeatureIds.adminNotifications,
      AppFeatureIds.adminUsers,
      AppFeatureIds.adminMySubscription,
      AppFeatureIds.adminMyUsage,
      AppFeatureIds.adminPayments,
      AppFeatureIds.adminSubscriptionRequest,
      AppFeatureIds.adminProfile,
      AppFeatureIds.adminBugReportSubmit,
    ],
    UserRoles.manager: [
      AppFeatureIds.adminDashboard,
      AppFeatureIds.adminCities,
      AppFeatureIds.adminCategories,
      AppFeatureIds.adminBrands,
      AppFeatureIds.adminOffers,
      AppFeatureIds.adminOfferDiscovery,
      AppFeatureIds.adminNotifications,
      AppFeatureIds.adminUsers,
      AppFeatureIds.adminProfile,
      AppFeatureIds.adminBugReportSubmit,
    ],
    UserRoles.mobileUser: AppFeatureIds.allMobile,
  };

  static Map<String, Object?> toFirestoreMap(AppFeature feature) => {
    'id': feature.id,
    'slug': feature.id,
    'name': feature.name,
    'description': feature.description,
    'platform': feature.platform,
    'route': feature.route,
    'sortOrder': feature.sortOrder,
    'isActive': feature.isActive,
  };

  static AppFeature _admin(
    String id,
    String name,
    String route,
    int sortOrder,
    String description,
  ) {
    return AppFeature(
      id: id,
      name: name,
      platform: AppFeaturePlatforms.adminPanel,
      route: route,
      sortOrder: sortOrder,
      description: description,
    );
  }

  static AppFeature _mobile(
    String id,
    String name,
    String route,
    int sortOrder,
    String description,
  ) {
    return AppFeature(
      id: id,
      name: name,
      platform: AppFeaturePlatforms.mobileApp,
      route: route,
      sortOrder: sortOrder,
      description: description,
    );
  }
}
