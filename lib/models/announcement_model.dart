class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.author,
    required this.isRead,
    this.attachmentId,
  });

  final String  id;
  final String  title;
  final String  message;
  final String  createdAt;
  final String  author;
  final bool    isRead;
  final String? attachmentId;

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? message,
    String? createdAt,
    String? author,
    bool? isRead,
    String? attachmentId,
  }) =>
      AnnouncementModel(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        author: author ?? this.author,
        isRead: isRead ?? this.isRead,
        attachmentId: attachmentId ?? this.attachmentId,
      );

  factory AnnouncementModel.fromJson(Map<String, dynamic> j) =>
      AnnouncementModel(
        id:           j['id']           as String,
        title:        j['title']        as String,
        message:      j['message']      as String,
        createdAt:    j['createdAt']    as String,
        author:       j['author']       as String,
        isRead:       j['isRead']       as bool? ?? false,
        attachmentId: j['attachmentId'] as String?,
      );
}

class AnnouncementListResult {
  const AnnouncementListResult({
    required this.items,
    required this.unreadCount,
    this.nextCursor,
  });
  final List<AnnouncementModel> items;
  final int                     unreadCount;
  final String?                 nextCursor;
}
