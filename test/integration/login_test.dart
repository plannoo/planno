import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login screen', () {
    testWidgets('renders email and password fields', (tester) async {
      await launchLoggedOut(tester);

      // "E-Mail" is both a label and the field hint, so expect two.
      expect(find.text('E-Mail'), findsNWidgets(2));
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Log in'), findsOneWidget);
    });

    testWidgets('shows warning when submitting empty fields', (tester) async {
      await launchLoggedOut(tester);

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your email and password.'),
        findsOneWidget,
      );
    });

    testWidgets('password toggle changes field visibility', (tester) async {
      await launchLoggedOut(tester);

      await tester.enterText(find.byType(TextField).last, 'secret123');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('typing in email field updates the text', (tester) async {
      await launchLoggedOut(tester);

      await tester.enterText(find.byType(TextField).first, 'test@aplano.com');
      await tester.pump();

      expect(find.text('test@aplano.com'), findsOneWidget);
    });

    testWidgets('Sign up button navigates to signup screen', (tester) async {
      await launchLoggedOut(tester);

      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Set up your company'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Forgot Password navigates to reset screen', (tester) async {
      await launchLoggedOut(tester);

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('invalid credentials keep the user on login', (tester) async {
      await launchLoggedOut(tester);

      await tester.enterText(find.byType(TextField).first, 'nobody@aplano.com');
      await tester.enterText(find.byType(TextField).last, 'wrongpassword');
      await tester.pump();

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Without valid credentials the request fails; either way we stay on login.
      expect(find.text('Log in'), findsOneWidget);
    });
  });
}
