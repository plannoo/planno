// Shared setup helpers for integration tests.
//
// UI-only tests (login, signup, onboarding, forgot-password) run headless
// under `flutter test` because the app persists everything through
// SharedPreferences, which we mock here — no emulator or backend required.
//
// Tests that hit real endpoints are gated behind [backendTests]; they are
// reported as skipped unless you run:
//   flutter test --dart-define=BACKEND_TESTS=true
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aplano/main.dart' as app;

/// True only when the caller opted into backend-dependent tests.
const bool backendTests =
    bool.fromEnvironment('BACKEND_TESTS', defaultValue: false);

/// `true` to skip backend-dependent tests (the default). Opt in by running:
///   flutter test --dart-define=BACKEND_TESTS=true
bool get skipUnlessBackend => !backendTests;

const seedEmail    = String.fromEnvironment('APLANO_TEST_EMAIL',    defaultValue: 'ralf@aplano.com');
const seedPassword = String.fromEnvironment('APLANO_TEST_PASSWORD', defaultValue: 'password123');
const seedEmployeeEmail = String.fromEnvironment('APLANO_EMPLOYEE_EMAIL', defaultValue: 'sarah@aplano.com');

/// Launches the app already past onboarding and logged out, so it lands
/// directly on the login screen.
Future<void> launchLoggedOut(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'has_seen_onboarding': true,
    'is_logged_in': false,
    'language_code': 'en', // deterministic English strings in assertions
  });
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Launches the app as a fresh install — onboarding not yet seen.
Future<void> launchFresh(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'language_code': 'en'});
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Drives the login form and waits for navigation. Requires a live backend.
Future<void> loginViaUi(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.first, email);
  await tester.enterText(fields.last, password);
  await tester.pump();
  await tester.tap(find.text('Log in'));
  await tester.pumpAndSettle(const Duration(seconds: 10));
}
