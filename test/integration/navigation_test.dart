import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

/// Post-login navigation. Requires a live backend to issue real tokens.
/// Run with:
///   flutter test test/integration/navigation_test.dart --dart-define=BACKEND_TESTS=true
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App navigation', () {
    testWidgets('logs in and reaches the dashboard shell', (tester) async {
      await launchLoggedOut(tester);
      await loginViaUi(tester, email: seedEmail, password: seedPassword);

      final hasShell = find.byType(NavigationBar).evaluate().isNotEmpty ||
          find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      expect(hasShell, isTrue,
          reason: 'NavigationShell should be visible after login');
    }, skip: skipUnlessBackend);

    testWidgets('all bottom-nav tabs are tappable', (tester) async {
      await launchLoggedOut(tester);
      await loginViaUi(tester, email: seedEmail, password: seedPassword);

      const navIcons = [
        Icons.grid_view_rounded,
        Icons.calendar_month_outlined,
        Icons.access_time_outlined,
        Icons.chat_bubble_outline,
        Icons.menu,
      ];

      for (final icon in navIcons) {
        final iconFinder = find.byIcon(icon);
        if (iconFinder.evaluate().isNotEmpty) {
          await tester.tap(iconFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }
    }, skip: skipUnlessBackend);
  });
}
