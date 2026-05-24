import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../medications/presentation/widgets/info_banner.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_typing_indicator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.sessionId, this.initialTitle});

  final int? sessionId;
  final String? initialTitle;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  int _lastMessageCount = 0;
  bool _lastSendingState = false;

  @override
  void initState() {
    super.initState();
    _controller = ChatController();
    final sessionId = widget.sessionId;
    if (sessionId != null) {
      _controller.openSession(sessionId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty || _controller.isSending) {
      return;
    }

    _messageController.clear();
    final success = await _controller.sendMessage(text);

    if (!mounted) {
      return;
    }

    if (!success && _controller.messagesError != null) {
      _messageController.text = text;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_controller.messagesError!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    _messageFocusNode.requestFocus();
  }

  void _maybeScrollToBottom() {
    final messageCount = _controller.messages.length;
    final isSending = _controller.isSending;
    if (messageCount == _lastMessageCount && isSending == _lastSendingState) {
      return;
    }

    _lastMessageCount = messageCount;
    _lastSendingState = isSending;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                enabled: !_controller.isSending,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu mensaje',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _controller.isSending ? null : _sendMessage,
                child: _controller.isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_controller.isLoadingMessages) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_controller.messages.isEmpty && _controller.messagesError == null) {
      return const ChatEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _controller.reloadCurrentMessages,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          if (_controller.messagesError != null) ...[
            InfoBanner(message: _controller.messagesError!),
            const SizedBox(height: 12),
          ],
          for (final message in _controller.messages)
            ChatMessageBubble(message: message),
          if (_controller.isSending) const ChatTypingIndicator(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        _maybeScrollToBottom();
        final title =
            _controller.currentSession?.displayTitle ??
            widget.initialTitle ??
            'Asistente Virtual';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 1,
            surfaceTintColor: Colors.transparent,
            shadowColor: AppColors.border.withValues(alpha: 0.1),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Nuevo asistente',
                onPressed: _controller.isSending
                    ? null
                    : _controller.startNewSession,
                icon: const Icon(
                  Icons.add_comment_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed:
                    _controller.currentSession == null ||
                        _controller.isLoadingMessages ||
                        _controller.isSending
                    ? null
                    : _controller.reloadCurrentMessages,
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessages()),
              _buildComposer(),
            ],
          ),
        );
      },
    );
  }
}
