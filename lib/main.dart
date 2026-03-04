import 'package:aplano/pages/auth/login_page.dart';
import 'package:aplano/pages/navigation_shell.dart';
import 'package:aplano/pages/onboarding/onboarding.dart';
import 'package:aplano/pages/auth/signup_page.dart';
import 'package:aplano/providers/app_provider.dart';
import 'package:aplano/core/services/prefs_service.dart';
import 'package:aplano/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialRoute = await _resolveInitialRoute();
  runApp(AplanoApp(initialRoute: initialRoute));
}

/// Determines the first screen to show based on saved preferences.
///
/// Priority:
///   1. Never seen onboarding → show onboarding
///   2. Seen onboarding, still logged in → go straight to app
///   3. Seen onboarding, not logged in → show login
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
    return AppProviders(child:MaterialApp(
      title: 'Aplano',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login':      (_) => const LoginPage(),
        '/signup':     (_) => const CreateAccountScreen(),
        '/home':       (_) => const NavigationShell(),
      },
    )
    ); 
    
  }
}