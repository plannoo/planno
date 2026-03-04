import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/absence_repository.dart';
import '../repositories/clock_repository.dart';
import '../repositories/shift_repository.dart';
import 'auth_provider.dart';
import 'clock_provider.dart';
import 'absence_provider.dart';
import 'dashboard_provider.dart';

/// Wires all [ChangeNotifierProvider]s to the widget tree.
///
/// Repositories are created once here and injected into providers via
/// [ChangeNotifierProxyProvider] where cross-provider dependencies exist.
/// Swap mock repositories for real ones here without touching any UI file.
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Repositories (plain objects, not ChangeNotifiers) ────────────────
        // Provided as plain values so providers can receive them.
        Provider<ClockRepository>(create: (_) => MockClockRepository()),
        Provider<AbsenceRepository>(create: (_) => MockAbsenceRepository()),
        Provider<ShiftRepository>(create: (_) => MockShiftRepository()),

        // ── Auth ─────────────────────────────────────────────────────────────
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),

        // ── Dashboard ────────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<ShiftRepository, DashboardProvider>(
          create: (ctx) => DashboardProvider(
            shiftRepository: ctx.read<ShiftRepository>(),
          ),
          update: (_, repo, prev) => prev ?? DashboardProvider(shiftRepository: repo),
        ),

        // ── Clock ────────────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<ClockRepository, ClockProvider>(
          create: (ctx) => ClockProvider(
            clockRepository: ctx.read<ClockRepository>(),
          )..initialise(),
          update: (_, repo, prev) => prev ?? (ClockProvider(clockRepository: repo)..initialise()),
        ),

        // ── Absence ──────────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<AbsenceRepository, AbsenceProvider>(
          create: (ctx) => AbsenceProvider(
            absenceRepository: ctx.read<AbsenceRepository>(),
          ),
          update: (_, repo, prev) => prev ?? AbsenceProvider(absenceRepository: repo),
        ),
      ],
      child: child,
    );
  }
}