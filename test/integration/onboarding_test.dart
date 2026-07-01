import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding flow', () {
    testWidgets('shows onboarding (not login) on a fresh install',
        (tester) async {
      await launchFresh(tester);

      // First onboarding page shows the Skip control and the "Next" button.
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Skip'), findsWidgets);
      expect(find.text('Next'), findsWidgets);
      // We must NOT have short-circuited to the login screen.
      expect(find.widgetWithText(ElevatedButton, 'Log in'), findsNothing);
    });

    testWidgets('can swipe from the first page to the next', (tester) async {
      await launchFresh(tester);

      expect(find.byType(PageView), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Still within onboarding, not yet on login.
      expect(find.widgetWithText(ElevatedButton, 'Log in'), findsNothing);
    });

    testWidgets('Skip exits onboarding to the login screen', (tester) async {
      await launchFresh(tester);

      await tester.tap(find.text('Skip').first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.widgetWithText(ElevatedButton, 'Log in'), findsOneWidget);
    });
  });
}
