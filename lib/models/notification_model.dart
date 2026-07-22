import 'package:flutter/material.dart';

enum NotificationCategory {
  shift,
  absence,
  message,
  clockIn,
  task,
  announcement,
  system,
}

/// The notification-settings toggle that governs whether a notification is
/// shown. Distinct from [NotificationCategory] (which only drives icons and
/// colours): the settings sheet is finer-grained than the display categories,
/// so each notification maps to exactly one toggle here. `other` covers
/// notifications with no dedicated toggle (chat, announcements, tasks, …), which
/// are always shown.
enum NotificationFilterKind {
  newShift,
  shiftChange,
  absence,
  clockReminder,
  lateAlert,
  other,
}

/// A single in-app notification entry.
class NotificationModel {
  final String               id;
  final String               title;
  final String               body;
  final DateTime             createdAt;
  final NotificationCategory category;
  final bool                 isRead;
  final Map<String, dynamic> data;
  /// Raw backend `NotificationType` (or the FCM `data.type`). Kept so the
  /// settings filter can distinguish e.g. SHIFT_ASSIGNED from SHIFT_UPDATED,
  /// which collapse to the same display [category].
  final String?              type;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.category,
    this.isRead = false,
    this.data   = const {},
    this.type,
  });

  /// Which settings toggle governs this notification (see [NotificationFilterKind]).
  NotificationFilterKind get filterKind {
    if (data.containsKey('clockInReminderShiftId')) {
      return NotificationFilterKind.clockReminder;
    }
    if (data.containsKey('lateAlertShiftId')) {
      return NotificationFilterKind.lateAlert;
    }
    return switch (type) {
      'SHIFT_ASSIGNED'   => NotificationFilterKind.newShift,
      'SHIFT_UPDATED' ||
      'SHIFT_CANCELLED'  => NotificationFilterKind.shiftChange,
      'ABSENCE_APPROVED' ||
      'ABSENCE_REJECTED' => NotificationFilterKind.absence,
      _                  => NotificationFilterKind.other,
    };
  }

  /// Maps a notification to our local category.
  ///
  /// [type] is the backend `NotificationType`. The backend has no dedicated
  /// clock-reminder type — it sends "time to clock in" / "employee is late" as
  /// SHIFT_UPDATED and tags them in [data] instead, so those are detected by
  /// their data markers first; otherwise they'd be lumped in with shift changes
  /// and the clock-in notification toggles would do nothing.
  static NotificationCategory _category(String? type, Map<String, dynamic> data) {
    if (data.containsKey('clockInReminderShiftId') ||
        data.containsKey('lateAlertShiftId')) {
      return NotificationCategory.clockIn;
    }
    return switch (type) {
      'SHIFT_ASSIGNED'  ||
      'SHIFT_UPDATED'   ||
      'SHIFT_CANCELLED' => NotificationCategory.shift,
      'ABSENCE_APPROVED'||
      'ABSENCE_REJECTED'=> NotificationCategory.absence,
      'TASK_ASSIGNED'   => NotificationCategory.task,
      'ANNOUNCEMENT'    => NotificationCategory.announcement,
      'CHAT_MESSAGE'    => NotificationCategory.message,
      _                 => NotificationCategory.system,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? {};
    // The list endpoint returns `type` as a top-level field; older/FCM shapes
    // nest it under `data`. Read the top level first — reading only data.type
    // made every notification fall through to "system", so no category toggle
    // ever matched and the settings appeared to do nothing.
    final type = (json['type'] ?? data['type']) as String?;
    return NotificationModel(
      id:        json['id'] as String,
      title:     json['title'] as String,
      body:      json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead:    json['readAt'] != null,
      category:  _category(type, data),
      type:      type,
      data:      data,
    );
  }

  /// Also accepts a RemoteMessage data map directly (for FCM foreground messages)
  factory NotificationModel.fromFcmData({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    return NotificationModel(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      title:     title,
      body:      body,
      createdAt: DateTime.now(),
      category:  _category(data['type'] as String?, data),
      type:      data['type'] as String?,
      isRead:    false,
      data:      data,
    );
  }

  // â”€â”€ Display helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  IconData get icon => switch (category) {
    NotificationCategory.shift    => Icons.calendar_today_outlined,
    NotificationCategory.absence  => Icons.event_busy_outlined,
    NotificationCategory.message  => Icons.chat_bubble_outline_rounded,
    NotificationCategory.task     => Icons.checklist_outlined,
    NotificationCategory.announcement => Icons.campaign_outlined,
    NotificationCategory.system   => Icons.notifications_outlined,
    NotificationCategory.clockIn  => Icons.access_time_outlined,
  };

  Color get iconColor => switch (category) {
    NotificationCategory.shift   => const Color(0xFFF43F5E),
    NotificationCategory.absence => const Color(0xFFF59E0B),
    NotificationCategory.message => const Color(0xFF8B5CF6),
    NotificationCategory.task    => const Color(0xFF22C55E),
    NotificationCategory.announcement => const Color(0xFFEC4899),
    NotificationCategory.system  => const Color(0xFF64748B),
    NotificationCategory.clockIn => const Color(0xFF22C55E),
  };

  Color get iconBackground => switch (category) {
    NotificationCategory.shift   => const Color(0xFFFFF1F2),
    NotificationCategory.absence => const Color(0xFFFEF3C7),
    NotificationCategory.message => const Color(0xFFEDE9FE),
    NotificationCategory.task    => const Color(0xFFDCFCE7),
    NotificationCategory.announcement => const Color(0xFFFCE7F3),
    NotificationCategory.system  => const Color(0xFFF1F5F9),
    NotificationCategory.clockIn => const Color(0xFFDCFCE7),
  };

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)   return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id:        id,
        title:     title,
        body:      body,
        createdAt: createdAt,
        category:  category,
        isRead:    isRead ?? this.isRead,
        data:      data,
        // Must carry `type` — filterKind reads it, so dropping it here would
        // reclassify the item as "other" (always shown) after mark-read.
        type:      type,
      );
}
