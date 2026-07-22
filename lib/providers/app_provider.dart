import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/services/notification_service.dart';
import '../repositories/absence_repository.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/availability_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/clock_repository.dart';
import '../repositories/device_token_repository.dart';
import '../repositories/document_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/shift_repository.dart';
import '../repositories/timesheet_repository.dart';
import '../repositories/user_repository.dart';
import '../providers/absence_provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/clock_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/scheduling_flags_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/schedule_provider.dart';

/// Wires all [ChangeNotifierProvider]s to the widget tree.
///
/// To swap mock for real implementations, change the create: line for that
/// repository — no UI file needs to change.
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Created once and shared between NotificationService.init and the provider
    final deviceTokenRepo =
        DeviceTokenRepositoryImpl(apiClient: ApiClient.instance);

    return FutureBuilder<_AppInit>(
      future: () async {
        final results = await Future.wait([
          LocaleProvider.create(),
          ThemeProvider.create(),
          NotificationService.instance.init(tokenRepo: deviceTokenRepo),
        ]);
        return _AppInit(
          locale: results[0] as LocaleProvider,
          theme:  results[1] as ThemeProvider,
        );
      }(),
      builder: (context, snapshot) {
        // Show loading while initializing
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
    return MultiProvider(
      providers: [
        
        // ── Repositories (API implementations) ───────────────────────────────
        Provider<ClockRepository>(create: (_) => ApiClockRepository()),
        Provider<AbsenceRepository>(create: (_) => ApiAbsenceRepository()),
        Provider<ShiftRepository>(create: (_) => ApiShiftRepository()),
        Provider<UserRepository>(create: (_) => ApiUserRepository()),
        Provider<ScheduleRepository>(create: (_) => ApiScheduleRepository()),
        Provider<AnnouncementRepository>(
            create: (_) => ApiAnnouncementRepository()),
        Provider<AvailabilityRepository>(
            create: (_) => ApiAvailabilityRepository()),
        Provider<TimesheetRepository>(
            create: (_) => ApiTimesheetRepository()),
        Provider<DocumentRepository>(
            create: (_) => ApiDocumentRepository()),
        Provider<ChatRepository>(
            create: (_) => ApiChatRepository()),
        Provider<DeviceTokenRepository>.value(value: deviceTokenRepo),
        // ── Auth ─────────────────────────────────────────────────────────────
        // AuthProvider receives UserRepository so it can fetch the user profile
        // immediately after login without a second provider lookup.
        ChangeNotifierProxyProvider2<UserRepository, DeviceTokenRepository,
            AuthProvider>(
          create: (ctx) {
            final auth = AuthProvider(
              userRepository:  ctx.read<UserRepository>(),
              tokenRepository: ctx.read<DeviceTokenRepository>(),
            );
            // Restore a stored session on startup so the user profile (name,
            // role) is loaded — without this, a restart shows "Wrenta User"
            // and treats admins as employees.
            auth.tryRestoreSession();
            return auth;
          },
          update: (_, repo, tokenRepo, prev) => prev ??
              AuthProvider(
                userRepository:  repo,
                tokenRepository: tokenRepo,
              ),
        ),
        // ── Scheduling flags (tied to auth) ──────────────────────────────────
        // Fetches the employee-facing Scheduling toggles on login so the UI can
        // hide actions the org has disabled instead of offering a control that
        // can only 403. Managers bypass (no fetch); cleared on logout.
        ChangeNotifierProxyProvider<AuthProvider, SchedulingFlagsProvider>(
          create: (_) => SchedulingFlagsProvider(),
          update: (_, auth, prev) {
            final p = prev ?? SchedulingFlagsProvider();
            p.sync(isLoggedIn: auth.isLoggedIn, isManager: auth.isAdmin);
            return p;
          },
        ),
        ChangeNotifierProvider<LocaleProvider>.value(
              value: snapshot.data!.locale,
            ),
            ChangeNotifierProvider<ThemeProvider>.value(
              value: snapshot.data!.theme,
            ),

        // ── Notifications (tied to auth) ──────────────────────────────────────
        // Uses no-op repo when logged out to avoid 401 on background FCM init;
        // switches to the real repo once authenticated.
        ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>(
          create: (_) => NotificationsProvider(repo: NoOpNotificationRepo()),
          update: (_, auth, prev) => auth.isLoggedIn
              ? NotificationsProvider(
                  repo: NotificationRepositoryImpl(
                      apiClient: ApiClient.instance),
                )
              : prev!,
        ),

        // ── Chat ──────────────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<ChatRepository, ChatProvider>(
          create: (ctx) => ChatProvider(
            repository: ctx.read<ChatRepository>(),
          ),
          update: (_, repo, prev) =>
              prev ?? ChatProvider(repository: repo),
        ),

        // ── Schedule ──────────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<ScheduleRepository, ScheduleProvider>(
          create: (ctx) => ScheduleProvider(
            repository: ctx.read<ScheduleRepository>(),
          ),
          update: (_, repo, prev) =>
              prev ?? ScheduleProvider(repository: repo),
        ),

        // ── Dashboard ────────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<ShiftRepository, DashboardProvider>(
          create: (ctx) => DashboardProvider(
            shiftRepository:     ctx.read<ShiftRepository>(),
            timesheetRepository: ctx.read<TimesheetRepository>(),
          ),
          update: (ctx, repo, prev) =>
              prev ?? DashboardProvider(
                shiftRepository:     repo,
                timesheetRepository: ctx.read<TimesheetRepository>(),
              ),
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

        // ── Announcements ────────────────────────────────────────────────────
        ChangeNotifierProxyProvider<AnnouncementRepository, AnnouncementProvider>(
          create: (ctx) => AnnouncementProvider(
            repository: ctx.read<AnnouncementRepository>(),
          ),
          update: (_, repo, prev) =>
              prev ?? AnnouncementProvider(repository: repo),
        ),
      ],
      child: child,
     );
      },
    );
  }
}

class _AppInit {
  final LocaleProvider locale;
  final ThemeProvider theme;
  const _AppInit({required this.locale, required this.theme});
}