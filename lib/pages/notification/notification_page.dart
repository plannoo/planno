import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/notification_model.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/layouts/notification_tile.dart';
import 'notification_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  Set<NotificationCategory> _hiddenCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load();
    });
  }

  Future<void> _loadCategoryPrefs() async {
    final results = await Future.wait([
      PrefsService.getViewBool('notif_new_shift_app',  fallback: true),
      PrefsService.getViewBool('notif_shift_change',   fallback: true),
      PrefsService.getViewBool('notif_shift_handover', fallback: true),
      PrefsService.getViewBool('notif_absence_req',    fallback: true),
      PrefsService.getViewBool('notif_employee_late',  fallback: true),
      PrefsService.getViewBool('notif_reminder_clock', fallback: true),
    ]);
    if (!mounted) return;
    setState(() {
      _hiddenCategories = {
        if (!(results[0] || results[1] || results[2])) NotificationCategory.shift,
        if (!results[3]) NotificationCategory.absence,
        if (!(results[4] || results[5])) NotificationCategory.clockIn,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _NotificationsAppBar(onTypesChanged: _loadCategoryPrefs),
      body: Consumer<NotificationsProvider>(
        builder: (_, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.state == NotificationsLoadState.error) {
            return _ErrorState(onRetry: provider.load);
          }
          final visible = provider.items
              .where((n) => !_hiddenCategories.contains(n.category))
              .toList();
          if (visible.isEmpty) {
            return const _EmptyState();
          }
          return _NotificationsList(provider: provider, visibleItems: visible);
        },
      ),
    );
  }
}

// â”€â”€ App bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NotificationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _NotificationsAppBar({required this.onTypesChanged});
  final VoidCallback onTypesChanged;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n     = AppLocalizations.of(context);
    final provider = context.watch<NotificationsProvider>();

    return AppBar(
      backgroundColor:  AppColors.primary,
      foregroundColor:  Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
      centerTitle:      false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.notificationsTitle,
              style: AppTextStyles.h5.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          if (provider.unreadCount > 0)
            Text(
              l10n.notificationsUnreadCount(provider.unreadCount),
              style: AppTextStyles.caption.copyWith(
                  color: Colors.white70, fontSize: 11),
            ),
        ],
      ),
      actions: [
        if (provider.hasUnread)
          TextButton(
            onPressed: provider.markAllRead,
            child: Text(
              l10n.notificationsMarkAllRead,
              style: AppTextStyles.labelSmall
                  .copyWith(color: Colors.white),
            ),
          ),
        Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
          onPressed: () => showModalBottomSheet(
            context: ctx,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _NotificationTypesSheet(),
          ).then((_) => onTypesChanged()),
        )),
        const SizedBox(width: 4),
      ],
    );
  }
}

// â”€â”€ Notification types sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NotificationTypesSheet extends StatefulWidget {
  const _NotificationTypesSheet();

  @override
  State<_NotificationTypesSheet> createState() => _NotificationTypesSheetState();
}

class _NotificationTypesSheetState extends State<_NotificationTypesSheet> {
  bool _newShiftApp     = true;
  bool _shiftChange     = true;
  bool _shiftHandover   = true;
  bool _absenceReq      = true;
  bool _employeeLate    = true;
  bool _reminderClockIn = true;
  bool _saving          = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final results = await Future.wait([
      PrefsService.getViewBool('notif_new_shift_app',  fallback: true),
      PrefsService.getViewBool('notif_shift_change',   fallback: true),
      PrefsService.getViewBool('notif_shift_handover', fallback: true),
      PrefsService.getViewBool('notif_absence_req',    fallback: true),
      PrefsService.getViewBool('notif_employee_late',  fallback: true),
      PrefsService.getViewBool('notif_reminder_clock', fallback: true),
    ]);
    if (!mounted) return;
    setState(() {
      _newShiftApp     = results[0];
      _shiftChange     = results[1];
      _shiftHandover   = results[2];
      _absenceReq      = results[3];
      _employeeLate    = results[4];
      _reminderClockIn = results[5];
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.wait([
      PrefsService.setViewBool('notif_new_shift_app',  _newShiftApp),
      PrefsService.setViewBool('notif_shift_change',   _shiftChange),
      PrefsService.setViewBool('notif_shift_handover', _shiftHandover),
      PrefsService.setViewBool('notif_absence_req',    _absenceReq),
      PrefsService.setViewBool('notif_employee_late',  _employeeLate),
      PrefsService.setViewBool('notif_reminder_clock', _reminderClockIn),
    ]);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget row(String label, bool val, ValueChanged<bool> cb) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(label, style: TextStyle(fontSize: 15, color: cs.onSurface)),
          value: val,
          onChanged: cb,
          activeColor: AppColors.primary,
        ),
      ],
    );

    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // â”€â”€ Handle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // â”€â”€ Title row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Notification types',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          // â”€â”€ Scrollable toggles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  row('New shift application',               _newShiftApp,     (v) => setState(() => _newShiftApp     = v)),
                  row('Shift change requests',               _shiftChange,     (v) => setState(() => _shiftChange     = v)),
                  row('Shift handover requested',            _shiftHandover,   (v) => setState(() => _shiftHandover   = v)),
                  row('Absence requested',                   _absenceReq,      (v) => setState(() => _absenceReq      = v)),
                  row('Employee is late',                    _employeeLate,    (v) => setState(() => _employeeLate    = v)),
                  row('Reminder to clock in at shift start', _reminderClockIn, (v) => setState(() => _reminderClockIn = v)),
                ],
              ),
            ),
          ),
          // â”€â”€ Save button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Grouped list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// Flat list item types for lazy ListView.builder
class _NHeader { const _NHeader(this.label); final String label; }
class _NSpacer { const _NSpacer(this.h); final double h; }

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.provider, required this.visibleItems});
  final NotificationsProvider provider;
  final List<NotificationModel> visibleItems;

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context);
    final now     = DateTime.now();

    final todayItems   = visibleItems
        .where((n) => _isToday(n.createdAt, now))
        .toList();
    final earlierItems = visibleItems
        .where((n) => !_isToday(n.createdAt, now))
        .toList();

    // Build a flat typed list so ListView.builder can be fully lazy
    final rows = <Object>[];
    if (todayItems.isNotEmpty) {
      rows.add(_NHeader(l10n.today));
      rows.addAll(todayItems);
      rows.add(const _NSpacer(8));
    }
    if (earlierItems.isNotEmpty) {
      rows.add(_NHeader(l10n.earlier));
      rows.addAll(earlierItems);
    }
    rows.add(const _NSpacer(32));

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final row = rows[i];
        if (row is _NHeader) return _GroupHeader(row.label);
        if (row is _NSpacer) return SizedBox(height: row.h);
        final n = row as NotificationModel;
        return NotificationTile(
          notification: n,
          onTap: () {
            provider.markRead(n.id);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => NotificationDetailPage(notification: n),
            ));
          },
          onDismiss: () => provider.dismiss(n.id),
        );
      },
    );
  }

  bool _isToday(DateTime dt, DateTime now) =>
      dt.year == now.year &&
      dt.month == now.month &&
      dt.day == now.day;
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          label,
          style: AppTextStyles.overline.copyWith(
              color: AppColors.slate400, fontSize: 11),
        ),
      );
}

// â”€â”€ Empty / error states â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: AppColors.slate100, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_outlined,
                size: 40, color: AppColors.slate400),
          ),
          const SizedBox(height: 16),
          Text(l10n.notificationsAllCaughtUp, style: AppTextStyles.h5),
          const SizedBox(height: 6),
          Text(l10n.notificationsNoneNew,
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 40, color: AppColors.error),
          const SizedBox(height: 12),
          Text(l10n.notificationsFailedToLoad,
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          TextButton(
              onPressed: onRetry,
              child: Text(l10n.retry)),
        ],
      ),
    );
  }
}