import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

/// Employee clock-in tab. Requires a live backend + a seeded employee account.
///
/// Run with:
///   flutter test test/integration/clock_in_test.dart --dart-define=BACKEND_TESTS=true
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Clock-in (employee)', () {
    testWidgets('employee lands on a shell with the clock-in tab',
        (tester) async {
      await launchLoggedOut(tester);
      await loginViaUi(tester,
          email: seedEmployeeEmail, password: seedPassword);

      final hasShell = find.byType(NavigationBar).evaluate().isNotEmpty ||
          find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      expect(hasShell, isTrue, reason: 'Employee should reach the app shell');

      // The clock-in tab uses the access-time icon.
      final clockTab = find.byIcon(Icons.access_time_outlined);
      expect(clockTab, findsWidgets);

      await tester.tap(clockTab.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Page rendered without throwing — no red error surface.
      expect(tester.takeException(), isNull);
    }, skip: skipUnlessBackend);
  });
}
