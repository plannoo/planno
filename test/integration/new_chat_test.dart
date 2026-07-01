import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

/// Exercises the "New chat" DM creation flow end-to-end. This is the flow that
/// previously failed with "Validation failed" (the client sent `userId` while
/// the API expects `otherUserId`). Requires a live backend + seeded users.
///
/// Run with:
///   flutter test test/integration/new_chat_test.dart --dart-define=BACKEND_TESTS=true
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('New chat / direct message', () {
    testWidgets('creating a DM does not raise a validation error',
        (tester) async {
      await launchLoggedOut(tester);
      await loginViaUi(tester, email: seedEmail, password: seedPassword);

      // Open the Messages tab.
      await tester.tap(find.byIcon(Icons.chat_bubble_outline).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open the New chat composer.
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Search and pick a seeded employee.
      await tester.enterText(find.byType(TextField).first, 'weber');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final member = find.text('Sarah Weber');
      if (member.evaluate().isEmpty) {
        markTestSkipped('Seeded user "Sarah Weber" not found — check seed data');
        return;
      }
      await tester.tap(member.first);
      await tester.pump();

      // Create the conversation.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The bug produced a red "Validation failed" snackbar. Assert it's gone.
      expect(find.text('Validation failed'), findsNothing);
    }, skip: skipUnlessBackend);
  });
}
