import 'package:intl/intl.dart';

/// A single chat message.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.sentAt,
    this.senderAvatarUrl,
    this.isRead = false,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String body;
  final DateTime sentAt;
  final bool isRead;

  String get initials {
    final parts = senderName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
  }

  String get timeLabel {
    final now  = DateTime.now();
    final diff = now.difference(sentAt);
    if (diff.inMinutes < 1)  return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours   < 24) return DateFormat.jm(Intl.defaultLocale).format(sentAt);
    return DateFormat('EEE', Intl.defaultLocale ?? 'en').format(sentAt).replaceAll('.', '');
  }

  ChatMessage copyWith({bool? isRead}) => ChatMessage(
    id: id, senderId: senderId, senderName: senderName,
    senderAvatarUrl: senderAvatarUrl, body: body, sentAt: sentAt,
    isRead: isRead ?? this.isRead,
  );
}

/// A chat conversation (1-to-1 or group).
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.participants,
    required this.messages,
    this.isGroup = false,
    this.avatarUrl,
  });

  final String id;
  final String title;
  final List<String> participants;
  final List<ChatMessage> messages;
  final bool isGroup;
  final String? avatarUrl;

  ChatMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;

  int get unreadCount =>
      messages.where((m) => !m.isRead && m.senderId != 'me').length;

  String get initials {
    final parts = title.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return title.isNotEmpty ? title[0].toUpperCase() : '?';
  }
}