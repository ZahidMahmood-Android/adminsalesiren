import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/access/domain/feature_access_utils.dart';
import '../../features/auth/domain/entities/user_roles.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/brands/presentation/screens/brand_form_screen.dart';
import '../../features/brands/presentation/screens/brands_list_screen.dart';
import '../../features/brands/presentation/screens/register_brand_screen.dart';
import '../../features/categories/presentation/screens/categories_list_screen.dart';
import '../../features/categories/presentation/screens/category_form_screen.dart';
import '../../features/cities/presentation/screens/cities_list_screen.dart';
import '../../features/cities/presentation/screens/city_form_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/offers/presentation/screens/offer_details_screen.dart';
import '../../features/offers/presentation/screens/offer_form_screen.dart';
import '../../features/offers/presentation/screens/offers_list_screen.dart';
import '../../features/offer_discovery/presentation/screens/offer_discovery_screen.dart';
import '../../features/notifications/presentation/screens/notification_requests_screen.dart';
import '../../features/bug_reports/presentation/screens/bug_reports_dashboard_screen.dart';
import '../../features/bug_reports/presentation/screens/submit_bug_report_screen.dart';
import '../../features/reports/presentation/screens/reports_list_screen.dart';
import '../../features/settings/presentation/screens/settings_seed_screen.dart';
import '../../features/settings/presentation/screens/alert_settings_screen.dart';
import '../../features/subscriptions/presentation/screens/brand_payment_form_screen.dart';
import '../../features/subscriptions/presentation/screens/brand_payment_verify_screen.dart';
import '../../features/subscriptions/presentation/screens/brand_payments_list_screen.dart';
import '../../features/subscriptions/presentation/screens/brand_subscription_form_screen.dart';
import '../../features/subscriptions/presentation/screens/brand_subscriptions_list_screen.dart';
import '../../features/subscriptions/presentation/screens/brand_usage_list_screen.dart';
import '../../features/subscriptions/presentation/screens/my_subscription_screen.dart';
import '../../features/subscriptions/presentation/screens/my_usage_screen.dart';
import '../../features/subscriptions/presentation/screens/pricing_plan_form_screen.dart';
import '../../features/subscriptions/presentation/screens/pricing_plans_list_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_request_form_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_requests_list_screen.dart';
import '../../features/users/presentation/screens/user_edit_screen.dart';
import '../../features/users/presentation/screens/user_registration_screen.dart';
import '../../features/users/presentation/screens/users_list_screen.dart';
import '../services/firebase_providers.dart';
import '../widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final routerRefresh = ref.watch(_routerRefreshListenableProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(auth.authStateChanges()),
      routerRefresh,
    ]),
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';
      final profile = ref.read(currentUserProfileProvider).value;

      if (!signedIn) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) {
        return '/dashboard';
      }
      if (profile != null && !profile.hasRole(UserRoles.owner)) {
        final location = state.matchedLocation;
        if (location.startsWith('/settings/alerts')) {
          return '/settings';
        }
        if (!FeatureAccessUtils.canAccessAdminRoute(profile, location)) {
          return '/dashboard';
        }
      }
      if (!(profile?.hasRole(UserRoles.owner) ?? false) &&
          profile != null &&
          (profile.hasRole(UserRoles.brandAdmin) ||
              profile.hasRole(UserRoles.manager))) {
        final location = state.matchedLocation;
        final isManager = profile.hasRole(UserRoles.manager);

        if (location == '/brands/register') {
          return '/dashboard';
        }
        if (location == '/brands/new' && !isManager) {
          return '/dashboard';
        }
        if (isManager && location.startsWith('/subscriptions/')) {
          return '/dashboard';
        }
        if (!isManager && location.startsWith('/cities/')) {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _fadePage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/brands',
            pageBuilder: (context, state) =>
                _fadePage(state, const BrandsListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fadePage(state, const BrandFormScreen()),
              ),
              GoRoute(
                path: 'register',
                pageBuilder: (context, state) =>
                    _fadePage(state, const RegisterBrandScreen()),
              ),
              GoRoute(
                path: ':brandId',
                pageBuilder: (context, state) => _fadePage(
                  state,
                  BrandFormScreen(brandId: state.pathParameters['brandId']),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/cities',
            pageBuilder: (context, state) =>
                _fadePage(state, const CitiesListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fadePage(state, const CityFormScreen()),
              ),
              GoRoute(
                path: ':cityId',
                pageBuilder: (context, state) => _fadePage(
                  state,
                  CityFormScreen(cityId: state.pathParameters['cityId']),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) =>
                _fadePage(state, const CategoriesListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fadePage(state, const CategoryFormScreen()),
              ),
              GoRoute(
                path: ':categoryId',
                pageBuilder: (context, state) => _fadePage(
                  state,
                  CategoryFormScreen(
                    categoryId: state.pathParameters['categoryId'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/offers',
            pageBuilder: (context, state) =>
                _fadePage(state, const OffersListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fadePage(state, const OfferFormScreen()),
              ),
              GoRoute(
                path: ':offerId',
                pageBuilder: (context, state) => _fadePage(
                  state,
                  OfferDetailsScreen(
                    offerId: state.pathParameters['offerId'] ?? '',
                  ),
                ),
              ),
              GoRoute(
                path: ':offerId/edit',
                pageBuilder: (context, state) => _fadePage(
                  state,
                  OfferFormScreen(offerId: state.pathParameters['offerId']),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/offer-discovery',
            pageBuilder: (context, state) =>
                _fadePage(state, const OfferDiscoveryScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                _fadePage(state, const ReportsListScreen()),
          ),
          GoRoute(
            path: '/bug-reports',
            pageBuilder: (context, state) =>
                _fadePage(state, const BugReportsDashboardScreen()),
            routes: [
              GoRoute(
                path: 'submit',
                pageBuilder: (context, state) =>
                    _fadePage(state, const SubmitBugReportScreen()),
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) =>
                _fadePage(state, const UsersListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fadePage(state, const UserRegistrationScreen()),
              ),
              GoRoute(
                path: ':userId',
                pageBuilder: (context, state) => _fadePage(
                  state,
                  UserEditScreen(userId: state.pathParameters['userId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                _fadePage(state, const NotificationRequestsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _fadePage(state, const SettingsSeedScreen()),
            routes: [
              GoRoute(
                path: 'alerts',
                pageBuilder: (context, state) =>
                    _fadePage(state, const AlertSettingsScreen()),
              ),
            ],
          ),
          GoRoute(
            path: '/subscriptions/plans',
            pageBuilder: (context, state) =>
                _fadePage(state, const PricingPlansListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fadePage(state, const PricingPlanFormScreen()),
              ),
              GoRoute(
                path: ':planId',
                pageBuilder: (context, state) => _fadePage(
                  state,
                  PricingPlanFormScreen(planId: state.pathParameters['planId']),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/subscriptions/brand-subscriptions',
            pageBuilder: (context, state) =>
                _fadePage(state, const BrandSubscriptionsListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fadePage(state, const BrandSubscriptionFormScreen()),
              ),
            ],
          ),
          GoRoute(
            path: '/subscriptions/payments',
            pageBuilder: (context, state) =>
                _fadePage(state, const BrandPaymentsListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fadePage(state, const BrandPaymentFormScreen()),
              ),
              GoRoute(
                path: ':paymentId',
                pageBuilder: (context, state) => _fadePage(
                  state,
                  BrandPaymentVerifyScreen(
                    paymentId: state.pathParameters['paymentId'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/subscriptions/usage',
            pageBuilder: (context, state) =>
                _fadePage(state, const BrandUsageListScreen()),
          ),
          GoRoute(
            path: '/subscriptions/requests',
            pageBuilder: (context, state) =>
                _fadePage(state, const SubscriptionRequestsListScreen()),
          ),
          GoRoute(
            path: '/subscriptions/my',
            pageBuilder: (context, state) =>
                _fadePage(state, const MySubscriptionScreen()),
          ),
          GoRoute(
            path: '/subscriptions/my-usage',
            pageBuilder: (context, state) =>
                _fadePage(state, const MyUsageScreen()),
          ),
          GoRoute(
            path: '/subscriptions/request',
            pageBuilder: (context, state) =>
                _fadePage(state, const SubscriptionRequestFormScreen()),
          ),
        ],
      ),
    ],
  );
});

final _routerRefreshListenableProvider = Provider<Listenable>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  ref.listen(currentUserProfileProvider, (_, _) => notifier.refresh());
  return notifier;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<User?> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
