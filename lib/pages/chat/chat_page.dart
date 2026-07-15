import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/user_search.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ChatAppBar(),
      body: Consumer<ChatProvider>(
        builder: (_, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.conversations.isEmpty) {
            return const _EmptyState();
          }
          return _ConversationList(conversations: provider.conversations);
        },
      ),
    );
  }
}

// â”€â”€ App bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final unread = context.select<ChatProvider, int>((p) => p.totalUnread);
    return AppBar(
      backgroundColor:   AppColors.primary,
      foregroundColor:   Colors.white,
      surfaceTintColor:  Colors.transparent,
      elevation:         0,
      centerTitle:       false,
      title: Row(
        children: [
          Text(l10n.chatTitle,
              style: AppTextStyles.h5.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99)),
              child: Text('$unread',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      actions: [
        Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.edit_outlined,
              size: 22, color: Colors.white),
          onPressed: () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const _NewChatPage())),
          tooltip: l10n.chatNewMessage,
        )),
        const SizedBox(width: 4),
      ],
    );
  }
}

// â”€â”€ Conversation list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.conversations});
  final List<Conversation> conversations;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount:        conversations.length,
      separatorBuilder: (_, _) => const Divider(
          height: 1, indent: 78, color: AppColors.slate100),
      itemBuilder: (context, i) => _ConversationTile(
        conversation: conversations[i],
        onTap: () {
          context.read<ChatProvider>().openConversation(conversations[i].id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _ThreadPage(conversationId: conversations[i].id),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile(
      {required this.conversation, required this.onTap});
  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context);
    final cs        = Theme.of(context).colorScheme;
    final myId      = context.select<AuthProvider, String?>((a) => a.user?.id);
    final last      = conversation.lastMessage;
    final unread    = conversation.unreadCount;
    final hasUnread = unread > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _ConversationAvatar(conversation: conversation),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 15,
                      color: hasUnread
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  if (last != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      (myId != null && last.senderId == myId)
                          ? '${l10n.chatYouPrefix}${last.body}'
                          : last.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 13,
                        color:      hasUnread
                            ? cs.onSurface.withValues(alpha: 0.85)
                            : cs.onSurfaceVariant,
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      maxLines:  1,
                      overflow:  TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (last != null)
                  Text(
                    last.timeLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: hasUnread
                          ? AppColors.primary
                          : cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                if (hasUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$unread',
                          style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    if (conversation.isGroup) {
      return Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.group_outlined,
            color: AppColors.primary, size: 22),
      );
    }
    return CircleAvatar(
      radius: 25,
      backgroundColor: AppColors.slate200,
      backgroundImage: conversation.avatarUrl != null
          ? NetworkImage(conversation.avatarUrl!)
          : null,
      child: conversation.avatarUrl == null
          ? Text(conversation.initials,
              style: const TextStyle(
                  color:      AppColors.slate600,
                  fontWeight: FontWeight.w700,
                  fontSize:   14))
          : null,
    );
  }
}

// â”€â”€ Thread page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ThreadPage extends StatefulWidget {
  const _ThreadPage({required this.conversationId});
  final String conversationId;

  @override
  State<_ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<_ThreadPage> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool  _isSending  = false;

  /// The signed-in user's id — used to right-align their own messages.
  String? get _myId => context.read<AuthProvider>().user?.id;

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    _controller.clear();
    setState(() => _isSending = true);
    await context
        .read<ChatProvider>()
        .sendMessage(widget.conversationId, body, currentUserId: _myId);
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final conv = context.select<ChatProvider, Conversation?>(
      (p) => p.conversations.cast<Conversation?>().firstWhere(
            (c) => c?.id == widget.conversationId,
            orElse: () => null,
          ),
    );
    if (conv == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor:  AppColors.primary,
        foregroundColor:  Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        titleSpacing:     0,
        iconTheme:        const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Flexible(
              child: Text(conv.title,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 17, color: Colors.white)),
            ),
            if (conv.isGroup) ...[
              const SizedBox(width: 6),
              Text(
                l10n.chatMemberCount(conv.participants.length),
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                size: 22, color: Colors.white),
            onPressed: () => _showThreadSettings(context, conv.id),
          ),
        ],
      ),
      body: Selector<ChatProvider,
          ({bool hasMore, bool isLoadingOlder})>(
        selector: (_, p) => (
          hasMore:        p.hasMoreOlderMessages(widget.conversationId),
          isLoadingOlder: p.isLoadingOlderMessages(widget.conversationId),
        ),
        builder: (ctx, paging, _) => Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: conv.messages.length + (paging.hasMore || paging.isLoadingOlder ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == 0 && (paging.hasMore || paging.isLoadingOlder)) {
                  return _LoadOlderButton(
                    isLoading: paging.isLoadingOlder,
                    onTap: () => ctx.read<ChatProvider>()
                        .loadOlderMessages(widget.conversationId),
                  );
                }
                final msgIdx = i - (paging.hasMore || paging.isLoadingOlder ? 1 : 0);
                return _MessageBubble(
                  currentUserId: _myId,
                  message:    conv.messages[msgIdx],
                  showAvatar: msgIdx == 0 ||
                      conv.messages[msgIdx].senderId !=
                          conv.messages[msgIdx - 1].senderId,
                );
              },
            ),
          ),
          _InputBar(
            controller: _controller,
            isSending:  _isSending,
            onSend:     _send,
            hint:       l10n.chatMessageHint,
          ),
        ],
      ),
      ),
    );
  }
}

// â”€â”€ Load older messages button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LoadOlderButton extends StatelessWidget {
  const _LoadOlderButton({required this.isLoading, required this.onTap});
  final bool         isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.expand_less, size: 18),
                  label: const Text('Load older messages'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.slate500,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
        ),
      );
}

// â”€â”€ Message bubble â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(
      {required this.message, required this.showAvatar, required this.currentUserId});
  final ChatMessage message;
  final bool        showAvatar;
  final String?     currentUserId;

  // A message is "mine" when its sender matches the signed-in user. The
  // optimistic-send path also stamps the real id, so it renders right-aligned
  // immediately and stays there once the server copy arrives.
  bool get _isMe =>
      message.senderId == 'me' ||
      (currentUserId != null && message.senderId == currentUserId);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: showAvatar ? 12 : 3, bottom: 2),
      child: Row(
        mainAxisAlignment:
            _isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isMe) ...[
            showAvatar
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.slate200,
                    backgroundImage: message.senderAvatarUrl != null
                        ? NetworkImage(message.senderAvatarUrl!)
                        : null,
                    child: message.senderAvatarUrl == null
                        ? Text(message.initials,
                            style: const TextStyle(fontSize: 11))
                        : null,
                  )
                : const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: _isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!_isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(message.senderName,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate500, fontSize: 11)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isMe
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(_isMe ? 18 : 4),
                      bottomRight: Radius.circular(_isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset:     const Offset(0, 1)),
                    ],
                  ),
                  child: Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 14,
                      color:  _isMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(message.timeLabel,
                      style:
                          AppTextStyles.caption.copyWith(fontSize: 10)),
                ),
              ],
            ),
          ),
          if (_isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// â”€â”€ Input bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.hint,
  });
  final TextEditingController controller;
  final bool         isSending;
  final VoidCallback onSend;
  final String       hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color:  Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:      controller,
              minLines:        1,
              maxLines:        4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText:       hint,
                filled:         true,
                fillColor:      Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:   BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:   BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:   const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSending ? AppColors.slate200 : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size:  20,
                color: isSending ? AppColors.slate400 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
            child: const Icon(Icons.chat_bubble_outline,
                size: 40, color: AppColors.slate400),
          ),
          const SizedBox(height: 16),
          Text(l10n.chatNoMessages, style: AppTextStyles.h5),
          const SizedBox(height: 6),
          Text(l10n.chatStartConversation,
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// â”€â”€ Thread settings dialog (Cupertino) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

void _showThreadSettings(BuildContext context, String conversationId) {
  showCupertinoDialog<void>(
    context: context,
    builder: (dialogCtx) => CupertinoAlertDialog(
      title: const Text('Settings'),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.pop(dialogCtx);
            try {
              await ApiClient.instance.delete('/api/chat/conversations/$conversationId');
              if (context.mounted) {
                await context.read<ChatProvider>().load();
                if (context.mounted) Navigator.pop(context);
              }
            } catch (_) {}
          },
          child: const Text('Delete chat'),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

// â”€â”€ New chat page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NewChatPage extends StatefulWidget {
  const _NewChatPage();

  @override
  State<_NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<_NewChatPage> {
  final _pager = UserSearchPager();
  final Set<String> _selected = {};
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> get _filtered => _pager.users;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _load(reset: true, query: _searchCtrl.text.trim());
      });
    });
  }

  @override
  void dispose() { _debounce?.cancel(); _searchCtrl.dispose(); super.dispose(); }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
        _pager.hasMore && !_pager.isLoading) {
      _load();
    }
    return false;
  }

  Future<void> _load({bool reset = false, String? query}) async {
    if (reset) setState(() => _loading = true);
    await _pager.load(reset: reset, query: query);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _next() async {
    if (_selected.isEmpty) return;
    final ids = _selected.toList();
    try {
      if (ids.length == 1) {
        await ApiClient.instance.post('/api/chat/conversations/dm',
            data: {'otherUserId': ids.first});
      } else {
        final selectedUsers = _pager.users.where((u) => _selected.contains(u['id']));
        final groupName = selectedUsers
            .map((u) => (u['firstName'] as String? ?? '').trim())
            .where((n) => n.isNotEmpty)
            .take(3)
            .join(', ');
        await ApiClient.instance.post('/api/chat/conversations/group',
            data: {'name': groupName.isNotEmpty ? groupName : 'Group', 'participantIds': ids});
      }
      if (!mounted) return;
      await context.read<ChatProvider>().load();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor:  AppColors.primary,
        foregroundColor:  Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        title: const Text('New chat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _next,
            child: Text('Next',
                style: TextStyle(
                    color: _selected.isEmpty
                        ? Colors.white.withValues(alpha: 0.5) : Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Suche',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    filled: true,
                    fillColor: cs.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Selected members: ${_selected.length}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(child: Text('No employees found',
                        style: TextStyle(color: cs.onSurfaceVariant)))
                    : NotificationListener<ScrollNotification>(
                        onNotification: _onScroll,
                        child: ListView.separated(
                          itemCount: _filtered.length + (_pager.hasMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                          itemBuilder: (_, i) {
                            if (i >= _filtered.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                              );
                            }
                            final u = _filtered[i];
                            final id = u['id'] as String? ?? '';
                            final name = ('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}').trim();
                            final picked = _selected.contains(id);
                            return InkWell(
                              onTap: () => setState(() {
                                if (picked) {
                                  _selected.remove(id);
                                } else {
                                  _selected.add(id);
                                }
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.person,
                                          color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(name,
                                          style: TextStyle(fontSize: 15, color: cs.onSurface)),
                                    ),
                                    if (picked)
                                      const Icon(Icons.check_circle,
                                          color: AppColors.primary, size: 22),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}