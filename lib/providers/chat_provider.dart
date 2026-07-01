import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';

enum ChatLoadState { initial, loading, loaded, error }

class ChatProvider extends ChangeNotifier {
  ChatProvider({required ChatRepository repository})
      : _repository = repository;

  final ChatRepository _repository;
  Timer? _convPollTimer;
  Timer? _msgPollTimer;

  List<Conversation> _conversations        = [];
  ChatLoadState      _state                = ChatLoadState.initial;
  String?            _activeConversationId;
  String?            _errorMessage;

  // Per-conversation pagination state
  final Map<String, String?> _oldestCursors  = {};
  final Map<String, bool>    _hasMoreOlder   = {};
  final Map<String, bool>    _loadingOlder   = {};

  List<Conversation> get conversations    => _conversations;
  ChatLoadState      get state            => _state;
  bool               get isLoading        => _state == ChatLoadState.loading;
  String?            get errorMessage     => _errorMessage;

  Conversation? get activeConversation => _activeConversationId == null
      ? null
      : _conversations.cast<Conversation?>()
            .firstWhere((c) => c?.id == _activeConversationId, orElse: () => null);

  int get totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  bool hasMoreOlderMessages(String id)  => _hasMoreOlder[id]  ?? false;
  bool isLoadingOlderMessages(String id) => _loadingOlder[id] ?? false;

  // ── Initial load ───────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_state == ChatLoadState.loading) return;
    _state = ChatLoadState.loading;
    notifyListeners();
    try {
      _conversations = await _repository.getConversations();
      _state = ChatLoadState.loaded;
      _startConvPolling();
    } catch (e) {
      _errorMessage = e.toString();
      _state = ChatLoadState.error;
    }
    notifyListeners();
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startConvPolling() {
    _convPollTimer?.cancel();
    _convPollTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _refreshConversations());
  }

  Future<void> _refreshConversations() async {
    try {
      final updated = await _repository.getConversations();
      _conversations = updated;
      notifyListeners();
    } catch (_) {}
  }

  void _startMsgPolling(String conversationId) {
    _msgPollTimer?.cancel();
    // Immediate fetch on open — loads latest 50 messages
    _fetchLatestMessages(conversationId, initial: true);
    _msgPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_activeConversationId != conversationId) return;
      _fetchLatestMessages(conversationId, initial: false);
    });
  }

  Future<void> _fetchLatestMessages(
    String conversationId, {
    required bool initial,
  }) async {
    try {
      final messages =
          await _repository.getMessages(conversationId, limit: 50);
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx == -1) return;
      final conv = _conversations[idx];

      if (initial && messages.isNotEmpty) {
        _oldestCursors[conversationId] = messages.first.id;
        _hasMoreOlder[conversationId] = messages.length >= 50;
      }

      // Only rebuild if messages actually changed
      if (messages.length != conv.messages.length ||
          (messages.isNotEmpty &&
              messages.last.id != conv.messages.lastOrNull?.id)) {
        _conversations[idx] = Conversation(
          id:           conv.id,
          title:        conv.title,
          participants: conv.participants,
          messages:     messages,
          isGroup:      conv.isGroup,
          avatarUrl:    conv.avatarUrl,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Load older messages (cursor-based pagination) ──────────────────────────

  Future<void> loadOlderMessages(String conversationId) async {
    if (_loadingOlder[conversationId] == true) return;
    if (_hasMoreOlder[conversationId] != true) return;

    _loadingOlder[conversationId] = true;
    notifyListeners();

    try {
      final cursor = _oldestCursors[conversationId];
      final older =
          await _repository.getMessages(conversationId, cursor: cursor, limit: 50);

      if (older.isEmpty) {
        _hasMoreOlder[conversationId] = false;
      } else {
        _oldestCursors[conversationId] = older.first.id;
        if (older.length < 50) _hasMoreOlder[conversationId] = false;

        final idx = _conversations.indexWhere((c) => c.id == conversationId);
        if (idx != -1) {
          final conv = _conversations[idx];
          _conversations[idx] = Conversation(
            id:           conv.id,
            title:        conv.title,
            participants: conv.participants,
            messages:     [...older, ...conv.messages],
            isGroup:      conv.isGroup,
            avatarUrl:    conv.avatarUrl,
          );
        }
      }
    } catch (_) {
      // Silent fail — user can retry by tapping the button again
    } finally {
      _loadingOlder[conversationId] = false;
      notifyListeners();
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void openConversation(String id) {
    _activeConversationId = id;
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final conv = _conversations[idx];
      _conversations[idx] = Conversation(
        id:           conv.id,
        title:        conv.title,
        participants: conv.participants,
        messages:     conv.messages,
        isGroup:      conv.isGroup,
        avatarUrl:    conv.avatarUrl,
      );
    }
    _repository.markConversationRead(id).catchError((_) {});
    _startMsgPolling(id);
    notifyListeners();
  }

  void closeConversation() {
    _activeConversationId = null;
    _msgPollTimer?.cancel();
    notifyListeners();
  }

  Future<void> sendMessage(
    String conversationId,
    String body, {
    String? currentUserId,
  }) async {
    if (body.trim().isEmpty) return;

    try {
      await _repository.sendMessage(conversationId, body.trim());
    } catch (_) {}

    // Optimistic update — stamp the real sender id so the message renders on the
    // right immediately and doesn't flip sides when the server copy is polled.
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final conv = _conversations[idx];
    final msg  = ChatMessage(
      id:         DateTime.now().millisecondsSinceEpoch.toString(),
      senderId:   currentUserId ?? 'me',
      senderName: 'You',
      body:       body.trim(),
      sentAt:     DateTime.now(),
      isRead:     true,
    );
    _conversations[idx] = Conversation(
      id:           conv.id,
      title:        conv.title,
      participants: conv.participants,
      messages:     [...conv.messages, msg],
      isGroup:      conv.isGroup,
      avatarUrl:    conv.avatarUrl,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _convPollTimer?.cancel();
    _msgPollTimer?.cancel();
    super.dispose();
  }
}
