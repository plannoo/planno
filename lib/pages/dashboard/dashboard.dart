import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../notification/notification_page.dart';
import '../schedule/teamschedule.dart';
import 'announcements_page.dart';
import 'birth_dates_page.dart';
import 'time_trackings_page.dart';

// â”€â”€ Models â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DashStats {
  final int clockedIn;
  final int late;
  final int openShifts;
  final int timeTrackings;
  final int birthdays;

  const _DashStats({
    required this.clockedIn,
    required this.late,
    required this.openShifts,
    required this.timeTrackings,
    this.birthdays = 0,
  });
}

class _ClockedInEmployee {
  final String name;
  final String shiftStart;
  final String clockedInAt;

  const _ClockedInEmployee({
    required this.name,
    required this.shiftStart,
    required this.clockedInAt,
  });
}

class _LateEmployee {
  final String name;
  final String shiftStart;

  const _LateEmployee({required this.name, required this.shiftStart});
}

// â”€â”€ Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  _DashStats? _stats;
  List<_ClockedInEmployee> _clockedInList = [];
  List<_LateEmployee> _lateList = [];
  bool _loadingStats = false;
  bool _hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    setState(() { _loadingStats = true; _hasNetworkError = false; });
    try {
      await Future.wait([
        _fetchStats(),
        _loadAnnouncements(),
        _loadNotifications(),
      ]);
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _fetchStats() async {
    try {
      final client = ApiClient.instance;
      // Fetch stats
      final statsData = await client.get('/api/dashboard/stats') as Map<String, dynamic>;
      final s = statsData['data'] as Map<String, dynamic>? ?? statsData;

      // Fetch panel for clocked-in list
      final panelData = await client.get('/api/dashboard/panel') as Map<String, dynamic>;
      final panel = panelData['data'] as Map<String, dynamic>? ?? panelData;
      final rawList = (panel['clockedInUsers'] as List<dynamic>?) ?? [];
      final rawLate = (panel['lateUsers'] as List<dynamic>?) ?? [];

      if (!mounted) return;
      setState(() {
        _stats = _DashStats(
          clockedIn:     (s['clockedIn']    as num? ?? 0).toInt(),
          late:          (s['late']         as num? ?? 0).toInt(),
          openShifts:    (s['openShifts']   as num? ?? 0).toInt(),
          timeTrackings: rawList.length,
          birthdays:     ((s['birthdays'] ?? s['birthDates'] ?? s['birthdayCount']) as num? ?? 0).toInt(),
        );
        _clockedInList = rawList.map((e) {
          final emp = e as Map<String, dynamic>;
          final at  = emp['clockedInAt'] as String? ?? '';
          return _ClockedInEmployee(
            name:        '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'.trim(),
            shiftStart:  '07:00', // shift start would need join with shifts
            clockedInAt: _fmtTime(at),
          );
        }).toList();
        _lateList = rawLate.map((e) {
          final emp = e as Map<String, dynamic>;
          return _LateEmployee(
            name:       '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'.trim(),
            shiftStart: _fmtTime(emp['shiftStart'] as String? ?? ''),
          );
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _hasNetworkError = true);
      }
    }
  }

  String _fmtTime(String iso) {
    if (iso.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h  = dt.hour.toString().padLeft(2, '0');
      final m  = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) { return '--:--'; }
  }

  Future<void> _loadAnnouncements() async {
    final provider = context.read<AnnouncementProvider>();
    if (provider.state == AnnouncementLoadState.initial ||
        provider.state == AnnouncementLoadState.error) {
      await provider.load();
    }
  }

  Future<void> _loadNotifications() async {
    final notifs = context.read<NotificationsProvider>();
    if (notifs.state == NotificationsLoadState.initial ||
        notifs.state == NotificationsLoadState.error) {
      notifs.init();
    }
  }

  void _showClockedInSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClockedInSheet(employees: _clockedInList),
    );
  }

  void _showLateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LateSheet(employees: _lateList),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<AnnouncementProvider, int>((p) => p.unreadCount);
    final hasNotifUnread = context.select<NotificationsProvider, bool>((p) => p.hasUnread);
    // ignore auth here â€” dashboard is a standalone page

    final cs = Theme.of(context).colorScheme;
    final cardBg = cs.surface;
    final divColor = cs.outline.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // â”€â”€ App bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: Container(
                  color: cardBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePaddingH,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dashboard',
                          style: AppTextStyles.h4.copyWith(fontSize: 28, color: cs.onSurface),
                        ),
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
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // â”€â”€ Offline error banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (_hasNetworkError && !_loadingStats)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.pagePaddingH, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_outlined,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Could not load data. Check your connection.',
                            style: TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadAll,
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4)),
                          child: const Text('Retry',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),

              // â”€â”€ Stats card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _loadingStats && _stats == null
                      ? const SizedBox(
                          height: 90,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                      : Row(
                          children: [
                            Expanded(
                              child: _StatCell(
                                value:     _stats?.clockedIn ?? 0,
                                label:     'Clocked In',
                                color:     AppColors.primary,
                                onTap:     _showClockedInSheet,
                              ),
                            ),
                            Container(width: 1, height: 70, color: divColor),
                            Expanded(
                              child: _StatCell(
                                value: _stats?.late ?? 0,
                                label: 'Late',
                                color: AppColors.error,
                                onTap:     _showLateSheet,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // â”€â”€ List rows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _DashRow(
                        icon: Icons.campaign_rounded,
                        iconBg: const Color(0xFFEF4444),
                        label: 'Announcements',
                        trailing: unreadCount > 0
                            ? Text(
                                '$unreadCount',
                                style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
                              )
                            : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AnnouncementsPage()),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _DashRow(
                        icon: Icons.access_time_filled_rounded,
                        iconBg: AppColors.primary,
                        label: 'Time trackings',
                        trailing: _stats != null
                            ? Text(
                                '${_stats!.timeTrackings}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              )
                            : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TimeTrackingsPage()),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _DashRow(
                        icon: Icons.grid_view_rounded,
                        iconBg: const Color(0xFFEC4899),
                        label: 'Open shifts',
                        trailing: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TeamSchedulePage()),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEC4899),
                            side: const BorderSide(color: Color(0xFFEC4899)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('View', style: TextStyle(fontSize: 13)),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TeamSchedulePage()),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _DashRow(
                        icon: Icons.cake_rounded,
                        iconBg: const Color(0xFFF97316),
                        label: 'Birth dates',
                        trailing: Text(
                          '${_stats?.birthdays ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BirthDatesPage()),
                        ),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Stat cell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final int    value;
  final String label;
  final Color  color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Dashboard row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DashRow extends StatelessWidget {
  const _DashRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    this.trailing,
    this.onTap,
    this.isLast = false,
  });

  final IconData   icon;
  final Color      iconBg;
  final String     label;
  final Widget?    trailing;
  final VoidCallback? onTap;
  final bool       isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Clocked-In bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ClockedInSheet extends StatelessWidget {
  const _ClockedInSheet({required this.employees});
  final List<_ClockedInEmployee> employees;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                Expanded(
                  child: Text(
                    'Clocked In',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Shift start',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Clocked In',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Employee list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: employees.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No employees clocked in',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: employees.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                    itemBuilder: (_, i) {
                      final e = employees[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.name,
                                style: TextStyle(fontSize: 14, color: cs.onSurface),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                e.shiftStart,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                e.clockedInAt,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// â”€â”€ Late bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LateSheet extends StatelessWidget {
  const _LateSheet({required this.employees});
  final List<_LateEmployee> employees;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                Expanded(
                  child: Text(
                    'Late',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 90,
                  child: Text(
                    'Shift start',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: employees.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Nobody is late',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: employees.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                    itemBuilder: (_, i) {
                      final e = employees[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.name,
                                style: TextStyle(fontSize: 14, color: cs.onSurface),
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                e.shiftStart,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
