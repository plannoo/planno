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

/// A single in-app notification entry.
class NotificationModel {
  final String               id;
  final String               title;
  final String               body;
  final DateTime             createdAt;
  final NotificationCategory category;
  final bool                 isRead;
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.category,
    this.isRead = false,
    this.data   = const {},
  });

  // Maps backend NotificationType enum to our local category
  static NotificationCategory _categoryFromType(String? type) => switch (type) {
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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id:        json['id'] as String,
      title:     json['title'] as String,
      body:      json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead:    json['readAt'] != null,
      category:  _categoryFromType(
        (json['data'] as Map<String, dynamic>?)?['type'] as String?,
      ),
      data: (json['data'] as Map<String, dynamic>?) ?? {},
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
      category:  _categoryFromType(data['type'] as String?),
      isRead:    false,
      data:      data,
    );
  }

  // ── Display helpers ─────────────────────────────────────────────────────

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
    NotificationCategory.shift   => const Color(0xFF2563EB),
    NotificationCategory.absence => const Color(0xFFF59E0B),
    NotificationCategory.message => const Color(0xFF8B5CF6),
    NotificationCategory.task    => const Color(0xFF22C55E),
    NotificationCategory.announcement => const Color(0xFFEC4899),
    NotificationCategory.system  => const Color(0xFF64748B),
    NotificationCategory.clockIn => const Color(0xFF22C55E),
  };

  Color get iconBackground => switch (category) {
    NotificationCategory.shift   => const Color(0xFFEFF6FF),
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
      );
}
