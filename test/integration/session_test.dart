import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:aplano/main.dart' as app;

import 'helpers.dart';

/// Session persistence: after a successful login the stored token should keep
/// the user authenticated across an app relaunch. Requires a live backend.
///
/// Run with:
///   flutter test test/integration/session_test.dart --dart-define=BACKEND_TESTS=true
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Session persistence', () {
    testWidgets('stays logged in after relaunch', (tester) async {
      await launchLoggedOut(tester);
      await loginViaUi(tester, email: seedEmail, password: seedPassword);

      // Confirm we actually reached the shell first.
      final loggedIn = find.byType(NavigationBar).evaluate().isNotEmpty ||
          find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      expect(loggedIn, isTrue, reason: 'Login should reach the shell');

      // Relaunch the app without clearing prefs — the saved session persists.
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final stillLoggedIn = find.byType(NavigationBar).evaluate().isNotEmpty ||
          find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      expect(stillLoggedIn, isTrue,
          reason: 'A persisted token should skip the login screen on relaunch');
      expect(find.text('Log in'), findsNothing);
    }, skip: skipUnlessBackend);
  });
}
