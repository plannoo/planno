import 'package:firebase_core/firebase_core.dart';
import 'package:aplano/firebase_options.dart';
import 'package:aplano/pages/auth/login_page.dart';
import 'package:aplano/pages/navigation_shell.dart';
import 'package:aplano/pages/onboarding/onboarding.dart';
import 'package:aplano/pages/absence/absence_page.dart';
import 'package:aplano/pages/auth/signup_page.dart';
import 'package:aplano/pages/notification/notification_page.dart';
import 'package:aplano/providers/app_provider.dart';
import 'package:aplano/core/services/prefs_service.dart';
import 'package:aplano/core/l10n/app_localizations.dart';
import 'package:aplano/core/theme/app_theme.dart';
import 'package:aplano/providers/locale_provider.dart';
import 'package:aplano/providers/theme_provider.dart';
import 'package:aplano/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is only available on Android, iOS, and Web.
  // On desktop it gracefully degrades — notifications are skipped.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    debugPrint('[main] Firebase not available — push notifications disabled');
  }

  final initialRoute = await _resolveInitialRoute();
  runApp(AplanoApp(initialRoute: initialRoute));
}

Future<String> _resolveInitialRoute() async {
  final seenOnboarding = await PrefsService.hasSeenOnboarding();
  if (!seenOnboarding) return '/onboarding';
  final loggedIn = await PrefsService.isLoggedIn();
  return loggedIn ? '/home' : '/login';
}

class AplanoApp extends StatelessWidget {
  final String initialRoute;
  const AplanoApp({super.key, required this.initialRoute});

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
          title: 'Aplano',
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