import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:wrenta/firebase_options.dart';
import 'package:wrenta/pages/auth/login_page.dart';
import 'package:wrenta/pages/navigation_shell.dart';
import 'package:wrenta/pages/onboarding/onboarding.dart';
import 'package:wrenta/pages/absence/absence_page.dart';
import 'package:wrenta/pages/auth/signup_page.dart';
import 'package:wrenta/pages/notification/notification_page.dart';
import 'package:wrenta/pages/legal/privacy_policy_page.dart';
import 'package:wrenta/pages/legal/terms_of_service_page.dart';
import 'package:wrenta/providers/app_provider.dart';
import 'package:wrenta/providers/auth_provider.dart';
import 'package:wrenta/core/services/prefs_service.dart';
import 'package:wrenta/core/l10n/app_localizations.dart';
import 'package:wrenta/core/theme/app_theme.dart';
import 'package:wrenta/providers/locale_provider.dart';
import 'package:wrenta/providers/theme_provider.dart';
import 'package:wrenta/core/services/notification_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ── DEV BYPASS ───────────────────────────────────────────────────────────────
// Set to true to skip login and load the employee shell directly.
// Flip back to false before building a release APK.
const bool _kBypassAuth = false;
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_kBypassAuth) AuthProvider.bypassForTesting = true;

  // Firebase is only available on Android, iOS, and Web.
  // On desktop it gracefully degrades — notifications are skipped.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Crashlytics doesn't support Flutter Web — mobile only. Also skip
    // collection in debug builds so local dev crashes don't pollute the
    // dashboard.
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(kReleaseMode);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (_) {
    debugPrint('[main] Firebase not available — push notifications disabled');
  }

  final initialRoute = await _resolveInitialRoute();
  runApp(WrentaApp(initialRoute: initialRoute));
}

Future<String> _resolveInitialRoute() async {
  if (_kBypassAuth) return '/home';
  final seenOnboarding = await PrefsService.hasSeenOnboarding();
  if (!seenOnboarding) return '/onboarding';
  final loggedIn = await PrefsService.isLoggedIn();
  return loggedIn ? '/home' : '/login';
}

class WrentaApp extends StatelessWidget {
  final String initialRoute;
  const WrentaApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return AppProviders(
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) => MaterialApp(
          // Cap text scaling at 1.3× so layouts hold with system Large-text a11y setting
          builder: (ctx, child) {
            final mq = MediaQuery.of(ctx);
            final capped = mq.textScaler.clamp(
                minScaleFactor: 1.0, maxScaleFactor: 1.3);
            return MediaQuery(
              data: mq.copyWith(textScaler: capped),
              child: child!,
            );
          },
          title: 'Wrenta',
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,

          navigatorKey: NotificationService.navigatorKey,
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,

          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,

          routes: {
            '/onboarding':     (_) => const OnboardingScreen(),
            '/login':          (_) => const LoginPage(),
            '/signup':         (_) => const CreateAccountScreen(),
            '/home':           (_) => const NavigationShell(),
            '/shifts':         (_) => const NavigationShell(),
            '/absences':       (_) => const AbsencePage(),
            '/notifications':  (_) => NotificationsPage(),
            '/privacy-policy':    (_) => const PrivacyPolicyPage(),
            '/terms-of-service':  (_) => const TermsOfServicePage(),
          },
          onGenerateRoute: (settings) {
            // Notification deep-links land on the shell; the shell selects the
            // relevant tab. (Chat/announcement/task all live inside the shell.)
            const shellRoutes = {'/announcements', '/tasks', '/chat'};
            if (shellRoutes.contains(settings.name)) {
              return MaterialPageRoute(
                builder: (_) => const NavigationShell(),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}