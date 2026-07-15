import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openForgotPassword(WidgetTester tester) async {
    await launchLoggedOut(tester);
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
  }

  group('Forgot password screen', () {
    testWidgets('renders heading, email field and submit button',
        (tester) async {
      await openForgotPassword(tester);

      expect(find.text('Forgot Password'), findsOneWidget);
      // "E-Mail" is both a label and the field hint.
      expect(find.text('E-Mail'), findsNWidgets(2));
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('empty submit stays on the form', (tester) async {
      await openForgotPassword(tester);

      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Guard returns early on empty email — still on the form.
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('submitting an email shows the confirmation view',
        (tester) async {
      await openForgotPassword(tester);

      await tester.enterText(find.byType(TextField).first, 'someone@wrenta.com');
      await tester.pump();

      await tester.tap(find.text('Send Reset Link'));
      // The handler always shows success (even on network error) to avoid
      // leaking which emails exist.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Check your inbox'), findsOneWidget);
    });

    testWidgets('Back to Login returns to the login screen', (tester) async {
      await openForgotPassword(tester);

      await tester.tap(find.text('Back to Login'));
      await tester.pumpAndSettle();

      expect(find.text('Log in'), findsOneWidget);
    });
  });
}
