import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clock_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/shift_model.dart';
import '../../widgets/clockIn/clock_face_card.dart';
import '../../widgets/clockIn/location_card.dart';
import '../../widgets/clockIn/location_status_widget.dart';
import '../../widgets/clockIn/recent_activity.dart';
import '../../widgets/clockIn/today_shift_card.dart';
import '../../../models/activity_model.dart';
import '../../../models/work_location_model.dart';
import 'qr_scan_page.dart';

class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  @override
  void initState() {
    super.initState();
    // The clock screen reads today's shift from DashboardProvider, but the
    // employee shell never opens the admin dashboard that loads it â€” so fetch
    // it here. Otherwise the card always reads "No shift today".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().load();
    });
  }

  // â”€â”€ Shift detail sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showShiftDetails(BuildContext context, ShiftModel shift) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(shift.role,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(shift.timeRange,
                  style: TextStyle(fontSize: 15, color: cs.onSurface)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(shift.location,
                  style: TextStyle(fontSize: 15, color: cs.onSurface))),
            ]),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Action handlers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _handleClockIn(BuildContext context) async {
    final l10n  = AppLocalizations.of(context);
    final clock = context.read<ClockProvider>();

    // Gate 1 â€” require an active shift today (also enforced server-side).
    var dashboard = context.read<DashboardProvider>();
    if (dashboard.todayShift == null) {
      // The shift fetch may have failed due to a token race (load() was
      // fire-and-forget while a concurrent 401 was being resolved). Retry
      // silently before concluding there's no shift.
      await dashboard.refresh();
      if (!context.mounted) return;
      dashboard = context.read<DashboardProvider>();
    }
    if (dashboard.todayShift == null) {
      if (dashboard.lastErrorWasAuth) {
        _handleSessionExpired(context);
        return;
      }
      _snack(context,
          'You have no shift scheduled for today, so you cannot clock in.',
          AppColors.error);
      return;
    }

    // Gate 2 â€” biometric (mobile only). Skipped on web/desktop where local_auth
    // has no implementation (calling it throws MissingPluginException). Any
    // failure to probe biometrics is treated as "not available" so it proceeds.
    if (!kIsWeb) {
      try {
        final localAuth = LocalAuthentication();
        final canBiometric = await localAuth.canCheckBiometrics &&
            await localAuth.isDeviceSupported();
        if (canBiometric) {
          final authenticated = await localAuth.authenticate(
            localizedReason: l10n.clockBiometricReason,
          );
          if (!context.mounted) return;
          if (!authenticated) {
            _snack(context, l10n.clockBiometricFailed, AppColors.error);
            return;
          }
        }
      } on MissingPluginException {
        // No biometric plugin on this platform â€” proceed without it.
      } on PlatformException {
        // Biometrics unavailable/not enrolled â€” proceed without it.
      }
    }

    // Gate 3 â€” require the employee's clock PIN.
    final pinOk = await _verifyClockPin(context);
    if (!context.mounted || !pinOk) return;

    // _verifyClockPin's dialog now uses a zero-duration transition, so its
    // element tree is already gone by the time we get here â€” no settle delay
    // needed before calling clockIn(), which fires notifyListeners().

    // Pass the shift ID so the server knows which shift to clock into.
    // Without it the server returns 400 "No active shift right now".
    final shiftId = context.read<DashboardProvider>().todayShift?.id;
    final error = await clock.clockIn(shiftId: shiftId);
    if (!context.mounted) return;

    if (error != null) {
      if (error.contains('Unauthorized') || error.contains('session')) {
        _handleSessionExpired(context);
      } else if (error.contains('work zone')) {
        _showLocationDialog(context);
      } else {
        _snack(context, error, AppColors.error);
      }
    } else {
      HapticFeedback.heavyImpact();
      _snack(context, l10n.clockInSuccess, AppColors.success);
    }
  }

  /// Fetches the employee's clock PIN and prompts for it. Returns true only
  /// when the entered PIN matches. Used as a clock-in security gate.
  Future<bool> _verifyClockPin(BuildContext context) async {
    String? pin;
    try {
      final res = await ApiClient.instance.get(ApiConfig.clockPin);
      final raw = res is Map<String, dynamic> ? res : <String, dynamic>{};
      final data = raw['data'] is Map ? raw['data'] as Map : raw;
      pin = data['pin']?.toString();
    } catch (_) {
      // If the PIN can't be loaded, don't hard-block clock-in.
      return true;
    }
    if (pin == null || pin.isEmpty) return true; // no PIN configured
    if (!context.mounted) return false;

    final controller = TextEditingController();
    // showGeneralDialog with a zero transition duration (instead of
    // showDialog's default ~150ms animated exit) so the dialog's element
    // subtree is fully unmounted by the time this await resolves. With an
    // animated exit, Navigator.pop() resolves before the transition finishes,
    // so code right after this call (clockIn(), which fires notifyListeners())
    // could run while the dialog is still mid-unmount, tripping a
    // "_dependents.isEmpty" assertion in Selectors watching ClockProvider.
    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (dctx, _, _) {
        final cs = Theme.of(dctx).colorScheme;
        return AlertDialog(
          title: const Text('Enter clock PIN'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            style: TextStyle(color: cs.onSurface, letterSpacing: 4),
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'â€¢â€¢â€¢â€¢',
            ),
            onSubmitted: (v) => Navigator.pop(dctx, v.trim() == pin),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dctx, controller.text.trim() == pin),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (ok != true) {
      if (context.mounted) {
        _snack(context, 'Incorrect PIN', AppColors.error);
      }
      return false;
    }
    return true;
  }

  Future<void> _handleClockOut(BuildContext context) async {
    final l10n   = AppLocalizations.of(context);
    final clock  = context.read<ClockProvider>();
    final session = clock.formattedSession;

    final error = await clock.clockOut();
    if (!context.mounted) return;

    if (error != null) {
      _snack(context, error, AppColors.error);
    } else {
      HapticFeedback.heavyImpact();
      _snack(context, l10n.clockOutSuccess(session), AppColors.slate700);
    }
  }

  Future<void> _handleBreak(BuildContext context) async {
    final clock = context.read<ClockProvider>();
    final error = clock.isOnBreak
        ? await clock.endBreak()
        : await clock.startBreak();

    if (!context.mounted) return;
    if (error != null) {
      _snack(context, error, AppColors.error);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(
            content:         Text(msg),
            backgroundColor: color,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
  }

  // â”€â”€ Dialogs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _handleSessionExpired(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(l10n.sessionExpired),
        content: const Text('Please log in again to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Clock-in is geofenced and server-enforced â€” there is no override path.
    // The user must be physically within the work zone to clock in.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   Text(l10n.clockOutsideWorkZoneTitle),
        content: Text(l10n.clockOutsideWorkZoneBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:     Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScanQr(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (!context.mounted || result == null) return;
    _snack(context, result, const Color(0xFF43A047));
    context.read<ClockProvider>().initialise();
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: cs.surface,
            padding: EdgeInsets.only(
              top:    AppDimensions.pagePaddingH,
              left:   AppDimensions.pagePaddingH,
              right:  AppDimensions.pagePaddingH,
              bottom: AppDimensions.spacingXl,
            ),
            child: const _PageHeader(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: Theme.of(context).platform == TargetPlatform.iOS
                    ? const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics())
                    : const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                  vertical:   AppDimensions.spacingXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Selector<DashboardProvider, ShiftModel?>(
                      selector: (_, p) => p.todayShift,
                      builder: (ctx, todayShift, _) => TodayShiftCard(
                        shift: todayShift,
                        onViewDetails: todayShift == null ? null : () =>
                            _showShiftDetails(ctx, todayShift),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),

                    // Clock face â€” rebuilds every second via sessionTime
                    Selector<ClockProvider,
                        ({ClockStatus status, Duration session, Duration breakTime, bool onBreak})>(
                      selector: (_, c) => (
                        status:    c.clockStatus,
                        session:   c.sessionTime,
                        breakTime: c.breakTime,
                        onBreak:   c.isOnBreak,
                      ),
                      builder: (_, data, _) => ClockFaceCard(
                        clockStatus: data.status,
                        sessionTime: data.session,
                        breakTime:   data.breakTime,
                        isOnBreak:   data.onBreak,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),

                    // Location â€” only rebuilds when location state changes
                    Selector<ClockProvider,
                        ({WorkLocationModel? workplace, bool isWithin, bool isLoading, String? dist, String? err, bool workplaceLoading})>(
                      selector: (_, c) => (
                        workplace:       c.workplace,
                        isWithin:        c.isWithinWorkZone,
                        isLoading:       c.isLoadingLocation,
                        dist:            c.formattedDistance,
                        err:             c.locationError,
                        workplaceLoading: c.isLoadingWorkplace,
                      ),
                      builder: (ctx, data, _) {
                        if (data.workplaceLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (data.workplace == null) {
                          return _WorkplaceError(
                            message: ctx.watch<ClockProvider>().workplaceError,
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LocationCard(
                              workplace:        data.workplace!,
                              isWithinWorkZone: data.isWithin,
                              distanceText:     data.dist,
                            ),
                            const SizedBox(height: AppDimensions.spacingXs),
                            LocationStatusWidget(
                              isLoading:        data.isLoading,
                              isWithinWorkZone: data.isWithin,
                              errorMessage:     data.err,
                              distanceText:     data.dist,
                              onRefresh: () =>
                                  ctx.read<ClockProvider>().fetchCurrentLocation(),
                            ),
                            const SizedBox(height: AppDimensions.spaceLg),
                          ],
                        );
                      },
                    ),

                    // Action buttons â€” rebuilds on status / loading / location changes
                    Selector<ClockProvider,
                        ({ClockStatus status, bool isActionLoading, bool isLocationLoading, bool isWithin})>(
                      selector: (_, c) => (
                        status:            c.clockStatus,
                        isActionLoading:   c.isActionLoading,
                        isLocationLoading: c.isLoadingLocation,
                        isWithin:          c.isWithinWorkZone,
                      ),
                      builder: (ctx, data, _) => _ActionButtons(
                        clockStatus:       data.status,
                        isActionLoading:   data.isActionLoading,
                        isLoadingLocation: data.isLocationLoading,
                        isWithinWorkZone:  data.isWithin,
                        onClockIn:   () => _handleClockIn(ctx),
                        onClockOut:  () => _handleClockOut(ctx),
                        onBreak:     () => _handleBreak(ctx),
                        onScanQr:    () => _handleScanQr(ctx),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl),

                    Selector<ClockProvider, List<ActivityModel>>(
                      selector: (_, c) => c.activities,
                      builder:  (_, acts, _) =>
                          RecentActivityList(activities: acts),
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Workplace error fallback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WorkplaceError extends StatelessWidget {
  const _WorkplaceError({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border:       Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? 'Could not load work location. Please try again.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Page header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final now       = DateTime.now();
    final dateLabel = '${months[now.month - 1]} ${now.day}';

    // No back button â€” the clock-in screen is a root navigation tab.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateLabel,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.slate500, fontSize: 12)),
        const SizedBox(height: 1),
        Text(l10n.clockTitle, style: AppTextStyles.h5),
      ],
    );
  }
}

// â”€â”€ Action buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.clockStatus,
    required this.isActionLoading,
    required this.isLoadingLocation,
    required this.isWithinWorkZone,
    required this.onClockIn,
    required this.onClockOut,
    required this.onBreak,
    required this.onScanQr,
  });

  final ClockStatus  clockStatus;
  final bool         isActionLoading;
  final bool         isLoadingLocation;
  final bool         isWithinWorkZone;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final VoidCallback onBreak;
  final VoidCallback onScanQr;

  bool get _isIdle    => clockStatus == ClockStatus.idle;
  bool get _isOnBreak => clockStatus == ClockStatus.onBreak;

  // Disable all buttons while any action or location fetch is in progress
  bool get _buttonsDisabled => isActionLoading || isLoadingLocation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _isIdle
            ? _buildIdleButtons(context)
            : _buildActiveButtons(context),

        // Overlay spinner while API call is in flight
        if (isActionLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color:        Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildIdleButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightLg,
          child: ElevatedButton.icon(
            // Disable if loading OR if location isn't ready yet
            onPressed: _buttonsDisabled ? null : onClockIn,
            icon:  const Icon(Icons.fingerprint, size: 22),
            label: Text(l10n.clockIn),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd)),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        // QR scan button â€” always visible on idle screen
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightMd,
          child: OutlinedButton.icon(
            onPressed: _buttonsDisabled ? null : onScanQr,
            icon:  const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Scan Terminal QR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            ),
          ),
        ),
        // Outside the geofence: inform the user instead of offering a bypass.
        // Clock-in is geofenced (and re-checked server-side), so there is no
        // override â€” the employee must be physically within the work zone.
        if (!isWithinWorkZone && !isLoadingLocation) ...[
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.clockOutsideWorkZoneTitle,
                  style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActiveButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppDimensions.buttonHeightMd,
            child: OutlinedButton.icon(
              // Can't start/end break while another action is loading
              onPressed: _buttonsDisabled ? null : onBreak,
              icon: Icon(
                _isOnBreak
                    ? Icons.play_arrow_rounded
                    : Icons.free_breakfast_outlined,
                size: 18,
              ),
              label: Text(_isOnBreak
                  ? l10n.clockEndBreakLabel
                  : l10n.clockBreakLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: _isOnBreak
                    ? AppColors.success
                    : AppColors.slate700,
                side: BorderSide(
                    color: _isOnBreak
                        ? AppColors.success
                        : AppColors.slate200),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd)),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: AppDimensions.buttonHeightMd,
            child: ElevatedButton.icon(
              // Disable clock-out while on break OR while action is loading
              onPressed: (_isOnBreak || _buttonsDisabled) ? null : onClockOut,
              icon:  const Icon(Icons.logout_rounded, size: 18),
              label: Text(l10n.clockOut),
              style: ElevatedButton.styleFrom(
                backgroundColor:         AppColors.error,
                foregroundColor:         Colors.white,
                disabledBackgroundColor: AppColors.slate200,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
