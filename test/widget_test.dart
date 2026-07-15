import 'package:flutter_test/flutter_test.dart';
import 'package:wrenta/main.dart';

void main() {
  testWidgets('App builds without crashing on login route', (WidgetTester tester) async {
    await tester.pumpWidget(const WrentaApp(initialRoute: '/login'));
    // Single pump — avoids timeout from never-resolving provider network calls
    await tester.pump();
    expect(find.byType(WrentaApp), findsOneWidget);
  });
}
