import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';

/// Employee-facing "Settings → Scheduling" toggles, fetched once per session
/// from `GET /api/settings/scheduling/me`.
///
/// The backend now genuinely enforces these (a disabled action returns 403), so
/// the app fetches them to hide/disable those actions up front instead of
/// letting the user tap a control that can only fail. Enforcement still lives on
/// the server — this is purely so the UI doesn't offer dead ends.
///
/// Semantics (mirrors the web client's `useSchedulingFlags`):
/// - Managers/admins/owners are never gated (they bypass on the backend too).
/// - An unloaded or unknown flag is treated as **allowed**, so an enabled action
///   is never hidden while the flags are still loading.
class SchedulingFlagsProvider extends ChangeNotifier {
  Map<String, bool> _flags = const {};
  bool _isManager = false;
  bool _loaded = false;
  bool _loading = false;
  // Bumped on every logout/session change. A _load() started under one epoch
  // must not apply its result under a newer one — otherwise a fetch still in
  // flight when the user logs out could restore the previous org's flags.
  int _epoch = 0;

  /// True once a fetch has completed (or was skipped for a manager / logout).
  bool get loaded => _loaded;

  /// Whether an employee-facing action is permitted. Managers bypass; an
  /// unknown/unloaded flag defaults to allowed.
  bool allowed(String flag) {
    if (_isManager) return true;
    return _flags[flag] != false;
  }

  // Convenience getters for the flags the UI gates on today.
  bool get canEnterAvailability   => allowed('allowAvailabilityEntry');
  bool get canEnterUnavailability => allowed('allowUnavailabilityEntry');
  bool get canClaimOpenShifts     => allowed('allowOpenShiftClaims');
  bool get canSwapShifts          => allowed('allowShiftSwaps');
  bool get canRequestShiftChange  => allowed('allowShiftChangeRequests');
  bool get canViewTimeAccount     => allowed('allowTimeAccountView');
  bool get canAttachToShifts      => allowed('allowShiftAttachments');
  bool get canEditOwnShifts       => allowed('allowSelfShiftEditing');

  /// Whether the org actually runs a QR time-station (raw org capability, no
  /// manager bypass). Defaults false until loaded, so the "Scan Terminal QR"
  /// clock-in only appears once we know the org uses stations.
  bool get hasQrStation           => _flags['hasQrStation'] == true;

  /// Called by the proxy provider whenever auth changes. Idempotent: it only
  /// hits the network on the transition into a fresh logged-in employee session.
  Future<void> sync({required bool isLoggedIn, required bool isManager}) async {
    if (!isLoggedIn) {
      // Clear on logout — the next login may be a different org. Bumping the
      // epoch invalidates any fetch still in flight so it can't restore stale
      // flags after this reset.
      _epoch++;
      if (_loaded || _loading || _flags.isNotEmpty) {
        _flags = const {};
        _isManager = false;
        _loaded = false;
        _loading = false;
        notifyListeners();
      }
      return;
    }
    // Already synced (or actively syncing) for this session; nothing to do.
    if ((_loaded || _loading) && _isManager == isManager) return;

    _isManager = isManager;
    if (isManager) {
      // Managers bypass every gate — no need to fetch.
      _loaded = true;
      notifyListeners();
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    final epoch = _epoch;
    _loading = true;
    try {
      final res = await ApiClient.instance.get('/api/settings/scheduling/me');
      // A logout (or another sync) happened while this was in flight — drop the
      // result rather than overwrite the newer session's state.
      if (epoch != _epoch) return;
      final raw = res is Map<String, dynamic> ? res : <String, dynamic>{};
      final data = raw['data'] is Map ? raw['data'] as Map : raw;
      _flags = {
        for (final e in data.entries)
          if (e.value is bool) e.key.toString(): e.value as bool,
      };
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Leave flags empty → everything allowed. The backend still enforces, so a
      // failed fetch degrades to "show the action, let the server decide" rather
      // than hiding controls the user may actually be allowed to use.
    } finally {
      if (epoch == _epoch) _loading = false;
    }
  }
}
