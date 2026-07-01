import 'package:flutter_test/flutter_test.dart';
import 'package:aplano/models/notification_model.dart';

void main() {
  group('NotificationModel.fromJson', () {
    Map<String, dynamic> base(String? type) => {
      'id': 'n-1',
      'title': 'Shift assigned',
      'body': 'You have a new shift on Monday',
      'createdAt': '2026-06-28T08:00:00.000Z',
      'readAt': null,
      'data': type == null ? <String, dynamic>{} : {'type': type},
    };

    test('parses core fields and unread state', () {
      final n = NotificationModel.fromJson(base('SHIFT_ASSIGNED'));
      expect(n.id, 'n-1');
      expect(n.title, 'Shift assigned');
      expect(n.isRead, isFalse);
      expect(n.category, NotificationCategory.shift);
    });

    test('readAt non-null marks as read', () {
      final json = base('SHIFT_ASSIGNED')..['readAt'] = '2026-06-28T09:00:00.000Z';
      expect(NotificationModel.fromJson(json).isRead, isTrue);
    });

    test('maps backend types to categories', () {
      final cases = {
        'SHIFT_ASSIGNED':   NotificationCategory.shift,
        'SHIFT_UPDATED':    NotificationCategory.shift,
        'ABSENCE_APPROVED': NotificationCategory.absence,
        'ABSENCE_REJECTED': NotificationCategory.absence,
        'TASK_ASSIGNED':    NotificationCategory.task,
        'ANNOUNCEMENT':     NotificationCategory.announcement,
        'CHAT_MESSAGE':     NotificationCategory.message,
        'SOMETHING_ELSE':   NotificationCategory.system,
      };
      cases.forEach((type, category) {
        expect(NotificationModel.fromJson(base(type)).category, category,
            reason: '$type should map to $category');
      });
    });

    test('missing type defaults to system category', () {
      expect(NotificationModel.fromJson(base(null)).category,
          NotificationCategory.system);
    });

    test('copyWith toggles read flag without losing fields', () {
      final n = NotificationModel.fromJson(base('ANNOUNCEMENT'));
      final read = n.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.id, n.id);
      expect(read.title, n.title);
      expect(read.category, n.category);
    });
  });
}
