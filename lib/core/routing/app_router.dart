import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/brands/presentation/screens/brand_form_screen.dart';
import '../../features/brands/presentation/screens/brands_list_screen.dart';
import '../../features/categories/presentation/screens/categories_list_screen.dart';
import '../../features/categories/presentation/screens/category_form_screen.dart';
import '../../features/cities/presentation/screens/cities_list_screen.dart';
import '../../features/cities/presentation/screens/city_form_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/offers/presentation/screens/offer_details_screen.dart';
import '../../features/offers/presentation/screens/offer_form_screen.dart';
import '../../features/offers/presentation/screens/offers_list_screen.dart';
import '../../features/reports/presentation/screens/reports_list_screen.dart';
import '../services/firebase_providers.dart';
import '../widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!signedIn) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/brands',
            builder: (context, state) => const BrandsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const BrandFormScreen(),
              ),
              GoRoute(
                path: ':brandId',
                builder: (context, state) =>
                    BrandFormScreen(brandId: state.pathParameters['brandId']),
              ),
            ],
          ),
          GoRoute(
            path: '/cities',
            builder: (context, state) => const CitiesListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CityFormScreen(),
              ),
              GoRoute(
                path: ':cityId',
                builder: (context, state) =>
                    CityFormScreen(cityId: state.pathParameters['cityId']),
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CategoryFormScreen(),
              ),
              GoRoute(
                path: ':categoryId',
                builder: (context, state) => CategoryFormScreen(
                  categoryId: state.pathParameters['categoryId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/offers',
            builder: (context, state) => const OffersListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const OfferFormScreen(),
              ),
              GoRoute(
                path: ':offerId',
                builder: (context, state) => OfferDetailsScreen(
                  offerId: state.pathParameters['offerId'] ?? '',
                ),
              ),
              GoRoute(
                path: ':offerId/edit',
                builder: (context, state) =>
                    OfferFormScreen(offerId: state.pathParameters['offerId']),
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsListScreen(),
          ),
        ],
      ),
    ],
  );
});

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
