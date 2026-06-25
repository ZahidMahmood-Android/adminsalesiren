import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'core/routing/app_router.dart';
import 'core/services/app_logger.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupAppLogging();

  final log = AppLogger.get('Bootstrap');
  FlutterError.onError = (details) {
    _presentFlutterError(details, log);
    log.severe('Flutter framework error', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log.severe('Uncaught platform error', error, stack);
    return true;
  };

  log.info('Initializing Firebase');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log.info('Firebase initialized');
  await _activateFirebaseAppCheck(log);

  runApp(const ProviderScope(child: SaleSirenAdminApp()));
}

void _presentFlutterError(FlutterErrorDetails details, Logger log) {
  try {
    FlutterError.presentError(details);
  } catch (error, stack) {
    log.warning('Flutter error presenter failed', error, stack);
  }
}

Future<void> _activateFirebaseAppCheck(Logger log) async {
  const webRecaptchaSiteKey = String.fromEnvironment(
    'FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY',
    defaultValue: '6LeGTS8tAAAAAOVWlIP-QsfEtQG9Ye-ktpdj8Aw0',
  );
  const webProviderKind = String.fromEnvironment(
    'FIREBASE_APPCHECK_WEB_PROVIDER',
    defaultValue: 'v3',
  );
  const debugToken = String.fromEnvironment('FIREBASE_APPCHECK_DEBUG_TOKEN');
  try {
    if (kIsWeb && !kDebugMode && webRecaptchaSiteKey.isEmpty) {
      log.warning(
        'Firebase App Check skipped on web: pass '
        'FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY at build time',
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      providerWeb: kDebugMode
          ? WebDebugProvider(debugToken: debugToken.isEmpty ? null : debugToken)
          : _webReleaseAppCheckProvider(webRecaptchaSiteKey, webProviderKind),
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(
              debugToken: debugToken.isEmpty ? null : debugToken,
            )
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider(
              debugToken: debugToken.isEmpty ? null : debugToken,
            )
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    log.info(
      'Firebase App Check activated (web provider: '
      '${kDebugMode ? 'debug' : webProviderKind})',
    );

    if (kIsWeb && !kDebugMode) {
      await _verifyWebAppCheckToken(log, webRecaptchaSiteKey, webProviderKind);
    }
  } catch (error, stack) {
    log.warning('Firebase App Check activation failed', error, stack);
  }
}

WebProvider _webReleaseAppCheckProvider(String siteKey, String providerKind) {
  return switch (providerKind) {
    'enterprise' => ReCaptchaEnterpriseProvider(siteKey),
    'v3' => ReCaptchaV3Provider(siteKey),
    _ => throw ArgumentError(
      'Unsupported FIREBASE_APPCHECK_WEB_PROVIDER: $providerKind '
      '(use v3 or enterprise)',
    ),
  };
}

Future<void> _verifyWebAppCheckToken(
  Logger log,
  String siteKey,
  String providerKind,
) async {
  final host = Uri.base.host;
  try {
    final token = await FirebaseAppCheck.instance.getToken();
    if (token == null || token.isEmpty) {
      log.warning(
        'App Check returned an empty token on $host. Add $host to allowed '
        'domains for reCAPTCHA site key $siteKey at '
        'https://www.google.com/recaptcha/admin (or Cloud reCAPTCHA Enterprise '
        'for enterprise keys). Provider: $providerKind.',
      );
    }
  } catch (error, stack) {
    log.warning(
      'App Check token failed on $host (appCheck/recaptcha-error). '
      '1) Add $host to reCAPTCHA allowed domains. '
      '2) Confirm the key is score-based v3 (not v2 checkbox). '
      '3) Match FIREBASE_APPCHECK_WEB_PROVIDER ($providerKind) to Firebase '
      'Console → App Check → Web app provider (v3 vs Enterprise). '
      '4) Use the site key shown in Firebase App Check, not an unrelated key.',
      error,
      stack,
    );
  }
}

class SaleSirenAdminApp extends ConsumerWidget {
  const SaleSirenAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Sale Siren',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
