import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../models/notification_model.dart';
import '../absence/absence_page.dart';
import '../chat/chat_page.dart';
import '../dashboard/announcements_page.dart';
import '../schedule/myschedule.dart';

/// Full-screen detail view for a single notification.
class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({super.key, required this.notification});

  final NotificationModel notification;

  ({String label, Widget page})? get _related {
    switch (notification.category) {
      case NotificationCategory.absence:
        return (label: 'View absences', page: const AbsencePage());
      case NotificationCategory.announcement:
        return (label: 'View announcement', page: const AnnouncementsPage());
      case NotificationCategory.message:
        return (label: 'Open chat', page: const ChatPage());
      case NotificationCategory.shift:
        return (label: 'View schedule', page: const MySchedulePage());
      case NotificationCategory.clockIn:
      case NotificationCategory.task:
      case NotificationCategory.system:
        return null;
    }
  }

  String _fullTimestamp(DateTime dt) {
    final local   = dt.toLocal();
    final locale  = Intl.defaultLocale ?? 'en';
    final isDE    = locale.startsWith('de');
    final datePart = DateFormat(isDE ? 'd. MMM yyyy' : 'MMM d, yyyy', locale).format(local);
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$datePart, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final related = _related;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Notification'),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: notification.iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(notification.icon,
                      color: notification.iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700,
                            color: cs.onSurface, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fullTimestamp(notification.createdAt),
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Text(
                notification.body,
                style: TextStyle(
                    fontSize: 15, height: 1.55, color: cs.onSurface),
              ),
            ),
            if (related != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => related.page),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(related.label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
