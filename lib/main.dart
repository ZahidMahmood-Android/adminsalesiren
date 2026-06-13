import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/services/app_logger.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupAppLogging();

  final log = AppLogger.get('Bootstrap');
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log.severe('Flutter framework error', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log.severe('Uncaught platform error', error, stack);
    return true;
  };

  log.info('Initializing Firebase');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log.info('Firebase initialized');

  runApp(const ProviderScope(child: SalesirenAdminApp()));
}

class SalesirenAdminApp extends ConsumerWidget {
  const SalesirenAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Salesiren Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
