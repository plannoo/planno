import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openSignup(WidgetTester tester) async {
    await launchLoggedOut(tester);
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
  }

  group('Signup screen', () {
    testWidgets('renders all organization + account fields', (tester) async {
      await openSignup(tester);

      expect(find.text('Organization Name'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Work Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('password field has a working visibility toggle',
        (tester) async {
      await openSignup(tester);

      // Password is the 5th field; its suffix holds the visibility toggle.
      final passwordField = find.byType(TextField).at(4);
      final toggle = find.descendant(
        of: passwordField,
        matching: find.byType(IconButton),
      );
      expect(toggle, findsOneWidget);

      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('empty submit stays on the signup screen', (tester) async {
      await openSignup(tester);

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Guard clause returns early on empty fields — screen unchanged.
      expect(find.text('Set up your company'), findsOneWidget);
    });

    testWidgets('typing populates the fields', (tester) async {
      await openSignup(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Acme Corp');
      await tester.enterText(find.byType(TextField).at(1), 'John');
      await tester.enterText(find.byType(TextField).at(2), 'Doe');
      await tester.enterText(find.byType(TextField).at(3), 'john@acme.com');
      await tester.pump();

      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('John'), findsOneWidget);
      expect(find.text('john@acme.com'), findsOneWidget);
    });

    testWidgets('Log In link returns to the login screen', (tester) async {
      await openSignup(tester);

      // The link sits at the bottom of a scroll view — bring it on-screen first.
      final logInLink = find.text('Log In');
      await tester.ensureVisible(logInLink);
      await tester.tap(logInLink);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Log in'), findsOneWidget);
    });
  });
}
