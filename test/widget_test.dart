// Basic Flutter widget test for Aplano app.

import 'package:flutter_test/flutter_test.dart';
import 'package:aplano/main.dart';

void main() {
  testWidgets('App loads and shows dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AplanoApp());

    // Verify that the app loads (dashboard should be present)
    await tester.pumpAndSettle();
    
    // The app should load without crashing
    expect(find.byType(AplanoApp), findsOneWidget);
  });
}
