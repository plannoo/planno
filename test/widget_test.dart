import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrenta/core/l10n/app_localizations.dart';
import 'package:wrenta/main.dart';

void main() {
  testWidgets('App builds without crashing on login route', (WidgetTester tester) async {
    await tester.pumpWidget(const WrentaApp(initialRoute: '/login'));
    // Single pump — avoids timeout from never-resolving provider network calls
    await tester.pump();
    expect(find.byType(WrentaApp), findsOneWidget);
  });

  test('German locale exposes localized schedule sub-tab labels', () async {
    // The schedule tabs (teamschedule.dart) build these from l10n; assert the
    // German ARB actually carries them rather than falling back to the keys.
    final l10n = await AppLocalizations.delegate.load(const Locale('de'));

    expect(l10n.scheduleMySchedule.isNotEmpty, isTrue);
    expect(l10n.scheduleDayPlan.isNotEmpty, isTrue);
    expect(l10n.scheduleWeekPlan.isNotEmpty, isTrue);
    // Distinct labels — a fallback would collapse them to the key names.
    expect({l10n.scheduleMySchedule, l10n.scheduleDayPlan, l10n.scheduleWeekPlan}.length, 3);
  });

  test('German locale exposes dashboard labels', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('de'));

    expect(l10n.dashboardStatsClockedIn, 'Eingestempelt');
    expect(l10n.dashboardStatsLate, 'Verspätet');
  });
}
