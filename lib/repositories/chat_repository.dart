import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/api_exceptions.dart';
import '../models/chat_model.dart';

abstract interface class ChatRepository {
  Future<List<Conversation>> getConversations();
  Future<int> getUnreadCount();
  Future<List<ChatMessage>> getMessages(String conversationId, {String? cursor, int? limit});
  Future<void> sendMessage(String conversationId, String body);
  Future<void> markConversationRead(String conversationId);
}

class ApiChatRepository implements ChatRepository {
  ApiChatRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _client.get(ApiConfig.conversations) as Map<String, dynamic>;
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((j) => _parseConversation(j as Map<String, dynamic>)).toList();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse conversations: $e'); }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _client.get(ApiConfig.conversationsUnread) as Map<String, dynamic>;
      final inner = response['data'] as Map<String, dynamic>?;
      return (inner?['unreadCount'] as num? ?? 0).toInt();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse unread count: $e'); }
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId, {String? cursor, int? limit}) async {
    try {
      final response = await _client.get(
        ApiConfig.conversationMessages(conversationId),
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          if (limit != null) 'limit': limit.toString(),
        },
      ) as Map<String, dynamic>;
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((j) => _parseMessage(j as Map<String, dynamic>)).toList();
    } on ApiException { rethrow; }
    catch (e) { throw ParseException('Failed to parse messages: $e'); }
  }

  @override
  Future<void> sendMessage(String conversationId, String body) async {
    try {
      await _client.post(
        ApiConfig.sendMessage(conversationId),
        data: {'body': body},
      );
    } on ApiException { rethrow; }
    catch (e) { throw UnknownException('Failed to send message: $e'); }
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    try {
      await _client.patch(ApiConfig.conversationRead(conversationId));
    } on ApiException { rethrow; }
    catch (e) { throw UnknownException('Failed to mark conversation read: $e'); }
  }

  Conversation _parseConversation(Map<String, dynamic> j) {
    // participants can be objects {id, firstName, lastName, avatarUrl} or strings
    final rawParticipants = (j['participants'] as List<dynamic>?) ?? [];
    final participantIds = rawParticipants.map((e) {
      if (e is String) return e;
      return ((e as Map<String, dynamic>)['id'] as String?) ?? '';
    }).toList();

    // Extract avatarUrl from first participant object (for DMs)
    String? avatarUrl = j['avatarUrl'] as String?;
    if (avatarUrl == null && rawParticipants.isNotEmpty) {
      final first = rawParticipants.first;
      if (first is Map<String, dynamic>) {
        avatarUrl = first['avatarUrl'] as String?;
      }
    }

    // Backend sends lastMessage as single object, not messages list
    final lastMsgRaw = j['lastMessage'] as Map<String, dynamic>?;
    final messages = <ChatMessage>[];
    if (lastMsgRaw != null) {
      messages.add(ChatMessage(
        id:         lastMsgRaw['id'] as String? ?? '',
        senderId:   lastMsgRaw['senderId'] as String? ?? '',
        senderName: '',
        body:       lastMsgRaw['body'] as String? ?? '',
        sentAt:     DateTime.tryParse(lastMsgRaw['sentAt'] as String? ?? '') ?? DateTime.now(),
        isRead:     true,
      ));
    }

    return Conversation(
      id:           j['id'] as String,
      title:        (j['title'] ?? j['name'] ?? '') as String,
      participants: participantIds,
      messages:     messages,
      isGroup:      (j['isGroup'] as bool?) ?? false,
      avatarUrl:    avatarUrl,
    );
  }

  ChatMessage _parseMessage(Map<String, dynamic> j) {
    final sender = j['sender'] as Map<String, dynamic>?;
    final senderId = sender?['id'] as String? ?? j['senderId'] as String? ?? '';
    final firstName = sender?['firstName'] as String? ?? '';
    final lastName  = sender?['lastName']  as String? ?? '';
    final senderName = j['senderName'] as String?
        ?? (firstName.isNotEmpty || lastName.isNotEmpty ? '$firstName $lastName'.trim() : senderId);
    return ChatMessage(
      id: j['id'] as String,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: sender?['avatarUrl'] as String? ?? j['senderAvatarUrl'] as String?,
      body: j['body'] as String,
      sentAt: DateTime.parse(j['sentAt'] as String),
      isRead: (j['isRead'] as bool?) ?? false,
    );
  }
}
