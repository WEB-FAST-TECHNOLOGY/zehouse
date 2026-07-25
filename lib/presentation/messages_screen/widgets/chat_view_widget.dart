import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../services/messaging_service.dart';

class ChatViewWidget extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final String conversationId;
  final VoidCallback onBack;
  final bool isTabletPanel;

  const ChatViewWidget({
    super.key,
    required this.conversation,
    required this.conversationId,
    required this.onBack,
    this.isTabletPanel = false,
  });

  @override
  State<ChatViewWidget> createState() => _ChatViewWidgetState();
}

class _ChatViewWidgetState extends State<ChatViewWidget> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  dynamic _messagesChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    MessagingService.instance.markMessagesRead(widget.conversationId);
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await MessagingService.instance.fetchMessages(
        widget.conversationId,
      );
      final uid = MessagingService.instance.currentUserId ?? '';
      if (mounted) {
        setState(() {
          _messages = msgs.map((m) => m.toDisplayMap(uid)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _messagesChannel = MessagingService.instance.subscribeToMessages(
      widget.conversationId,
      (msg) {
        final uid = MessagingService.instance.currentUserId ?? '';
        if (mounted) {
          setState(() {
            _messages.add(msg.toDisplayMap(uid));
          });
          _scrollToBottom();
          // Mark as read if received from other user
          if (msg.senderId != uid) {
            MessagingService.instance.markMessagesRead(widget.conversationId);
          }
        }
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      await MessagingService.instance.sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
    } catch (_) {
      // Restore text on failure
      if (mounted) {
        _messageController.text = text;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Chat header
          SafeArea(
            bottom: false,
            child: Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (!widget.isTabletPanel)
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.primary,
                          ),
                          onPressed: widget.onBack,
                        ),
                      if (!widget.isTabletPanel) const SizedBox(width: 4),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: CustomImageWidget(
                              imageUrl: conv['avatarUrl'] as String? ?? '',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              semanticLabel:
                                  conv['avatarSemanticLabel'] as String? ?? '',
                            ),
                          ),
                          if (conv['isOnline'] as bool? ?? false)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conv['contactName'] as String? ?? 'Utilisateur',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              (conv['isOnline'] as bool? ?? false)
                                  ? 'En ligne'
                                  : conv['contactRole'] as String? ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: (conv['isOnline'] as bool? ?? false)
                                    ? AppTheme.success
                                    : AppTheme.muted,
                                fontWeight: (conv['isOnline'] as bool? ?? false)
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.phone_rounded,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: AppTheme.muted,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  // Property context card
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomImageWidget(
                            imageUrl: conv['propertyImageUrl'] as String? ?? '',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            semanticLabel:
                                conv['propertySemanticLabel'] as String? ?? '',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conv['propertyTitle'] as String? ?? '',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                conv['propertyPrice'] as String? ?? '',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'Commencez la conversation…',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.muted,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.attach_file_rounded,
                      size: 20,
                      color: AppTheme.muted,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Votre message…',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.muted,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isSending ? AppTheme.muted : AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message['isMe'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.70,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe ? null : Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message['text'] as String? ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message['time'] as String? ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withAlpha(179)
                              : AppTheme.muted,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        Icon(
                          (message['isRead'] as bool? ?? false)
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 12,
                          color: (message['isRead'] as bool? ?? false)
                              ? Colors.white.withAlpha(230)
                              : Colors.white.withAlpha(128),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
