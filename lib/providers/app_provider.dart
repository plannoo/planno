import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/absence_repository.dart';
import '../../repositories/clock_repository.dart';
import '../../repositories/shift_repository.dart';
import '../../repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clock_provider.dart';
import '../../providers/absence_provider.dart';
import '../../providers/dashboard_provider.dart';

/// Wires all [ChangeNotifierProvider]s to the widget tree.
///
/// To swap mock for real implementations, change the create: line for that
/// repository — no UI file needs to change.
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Repositories ─────────────────────────────────────────────────────
        Provider<ClockRepository>(create: (_) => MockClockRepository()),
        Provider<AbsenceRepository>(create: (_) => MockAbsenceRepository()),
        Provider<ShiftRepository>(create: (_) => MockShiftRepository()),
        // Swap ApiUserRepository() ↔ StubUserRepository() while the API is down.
        Provider<UserRepository>(create: (_) => ApiUserRepository()),

        // ── Auth ─────────────────────────────────────────────────────────────
        // AuthProvider receives UserRepository so it can fetch the user profile
        // immediately after login without a second provider lookup.
        ChangeNotifierProxyProvider<UserRepository, AuthProvider>(
          create: (ctx) => AuthProvider(
            userRepository: ctx.read<UserRepository>(),
          ),
          update: (_, repo, prev) =>
              prev ?? AuthProvider(userRepository: repo),
        ),

        // ── Dashboard ────────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<ShiftRepository, DashboardProvider>(
          create: (ctx) => DashboardProvider(
            shiftRepository: ctx.read<ShiftRepository>(),
          ),
          update: (_, repo, prev) =>
              prev ?? DashboardProvider(shiftRepository: repo),
        ),

        // ── Clock ────────────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<ClockRepository, ClockProvider>(
          create: (ctx) =>
              ClockProvider(clockRepository: ctx.read<ClockRepository>())
                ..initialise(),
          update: (_, repo, prev) =>
              prev ?? (ClockProvider(clockRepository: repo)..initialise()),
        ),

        // ── Absence ──────────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<AbsenceRepository, AbsenceProvider>(
          create: (ctx) => AbsenceProvider(
            absenceRepository: ctx.read<AbsenceRepository>(),
          ),
          update: (_, repo, prev) =>
              prev ?? AbsenceProvider(absenceRepository: repo),
        ),
      ],
      child: child,
    );
  }
}