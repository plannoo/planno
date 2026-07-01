import 'package:flutter_test/flutter_test.dart';
import 'package:aplano/main.dart';

void main() {
  testWidgets('App builds without crashing on login route', (WidgetTester tester) async {
    await tester.pumpWidget(const AplanoApp(initialRoute: '/login'));
    // Single pump — avoids timeout from never-resolving provider network calls
    await tester.pump();
    expect(find.byType(AplanoApp), findsOneWidget);
  });
}
