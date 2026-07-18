import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/announcement_provider.dart';
import '../dashboard/announcements_page.dart';
import '../notification/notification_page.dart';

/// Employee home tab — surfaces Announcements and Open shifts.
/// (Admins/managers get the richer team [DashboardPage] instead.)
class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  List<_OpenShift> _openShifts = [];
  bool _loadingShifts = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadAnnouncements(), _loadOpenShifts()]);
  }

  Future<void> _loadAnnouncements() async {
    final provider = context.read<AnnouncementProvider>();
    if (provider.state == AnnouncementLoadState.initial ||
        provider.state == AnnouncementLoadState.error) {
      await provider.load();
    }
  }

  Future<void> _loadOpenShifts() async {
    if (mounted) setState(() => _loadingShifts = true);
    try {
      final data = await ApiClient.instance.get('/api/shifts/open');
      final raw  = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : (data as List<dynamic>? ?? []);
      final shifts = raw.map((e) => _OpenShift.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) setState(() { _openShifts = shifts; _loadingShifts = false; });
    } catch (_) {
      if (mounted) setState(() { _openShifts = []; _loadingShifts = false; });
    }
  }

  Future<void> _claimShift(_OpenShift s) async {
    try {
      final res = await ApiClient.instance.post('/api/shifts/${s.id}/claim', data: {});
      await _loadOpenShifts();
      if (!mounted) return;
      final data = res is Map ? res['data'] : null;
      final pending = data is Map && data['pending'] == true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pending
            ? 'Claim submitted for manager approval'
            : 'Shift claimed — added to your schedule'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasNotifUnread =
        context.select<AnnouncementProvider, int>((p) => p.unreadCount) > 0;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                color: cs.surface,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePaddingH, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.navHome,
                          style: AppTextStyles.h4.copyWith(
                              fontSize: 28, color: cs.onSurface)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NotificationsPage())),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(Icons.notifications_outlined,
                              size: 26, color: cs.onSurfaceVariant),
                          if (hasNotifUnread)
                            Positioned(
                              top: -2, right: -2,
                              child: Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                    color: AppColors.error, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _announcementsSection(cs, l10n),
              const SizedBox(height: 12),
              _openShiftsSection(cs, l10n),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Announcements ───────────────────────────────────────────────────────────
  Widget _announcementsSection(ColorScheme cs, AppLocalizations l10n) {
    return Consumer<AnnouncementProvider>(
      builder: (context, provider, _) {
        final items = provider.items.take(3).toList();
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                cs,
                icon: Icons.campaign_rounded,
                iconBg: const Color(0xFFEF4444),
                title: l10n.dashboardAnnouncements,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AnnouncementsPage())),
              ),
              if (provider.state == AnnouncementLoadState.loading && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(l10n.homeNoAnnouncements,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                )
              else
                ...items.map((a) => InkWell(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AnnouncementsPage())),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            if (!a.isRead)
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                    color: AppColors.error, shape: BoxShape.circle),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: a.isRead
                                              ? FontWeight.w500 : FontWeight.w700,
                                          color: cs.onSurface)),
                                  const SizedBox(height: 2),
                                  Text(a.message,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13, color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  // ── Open shifts ─────────────────────────────────────────────────────────────
  Widget _openShiftsSection(ColorScheme cs, AppLocalizations l10n) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            cs,
            icon: Icons.grid_view_rounded,
            iconBg: const Color(0xFFEC4899),
            title: l10n.dashboardOpenShifts,
            trailing: _loadingShifts
                ? null
                : Text('${_openShifts.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          if (_loadingShifts)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_openShifts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(l10n.homeNoOpenShifts,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
            )
          else
            ..._openShifts.map((s) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4, height: 38,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: s.roleColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${s.dateLabel} · ${s.timeRange}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text(
                              [s.role, if (s.locationName.isNotEmpty) s.locationName]
                                  .join(' · '),
                              style: TextStyle(
                                  fontSize: 13, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _claimShift(s),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Claim',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _sectionHeader(ColorScheme cs,
      {required IconData icon,
      required Color iconBg,
      required String title,
      Widget? trailing,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ),
            if (trailing != null) trailing,
            if (onTap != null)
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

// ── Open shift model ────────────────────────────────────────────────────────────


class _OpenShift {
  final String id;
  final String role;
  final Color  roleColor;
  final String locationName;
  final String dateLabel;
  final String timeRange;

  const _OpenShift({
    required this.id,
    required this.role,
    required this.roleColor,
    required this.locationName,
    required this.dateLabel,
    required this.timeRange,
  });

  factory _OpenShift.fromJson(Map<String, dynamic> j) {
    final date  = DateTime.tryParse(j['date'] as String? ?? '')?.toLocal();
    final start = DateTime.tryParse(j['startTime'] as String? ?? '')?.toLocal();
    final end   = DateTime.tryParse(j['endTime'] as String? ?? '')?.toLocal();
    final loc   = j['location'] as Map<String, dynamic>?;

    String hhmm(DateTime? d) => d == null
        ? '--:--'
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return _OpenShift(
      id:           j['id'] as String? ?? '',
      role:         j['role'] as String? ?? '',
      roleColor:    _parseColor(j['roleColor'] as String?),
      locationName: loc?['name'] as String? ?? '',
      dateLabel:    date == null ? '' : DateFormat((Intl.defaultLocale ?? 'en').startsWith('de') ? 'd. MMM' : 'MMM d', Intl.defaultLocale ?? 'en').format(date),
      timeRange:    '${hhmm(start)} – ${hhmm(end)}',
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$clean', radix: 16);
    return value == null ? AppColors.primary : Color(value);
  }
}
