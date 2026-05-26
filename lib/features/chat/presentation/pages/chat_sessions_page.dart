import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../medications/presentation/widgets/info_banner.dart';
import '../../models/chat_session.dart';
import '../controllers/chat_controller.dart';
import 'chat_page.dart';

class ChatSessionsPage extends StatefulWidget {
  const ChatSessionsPage({super.key});

  @override
  State<ChatSessionsPage> createState() => _ChatSessionsPageState();
}

class _ChatSessionsPageState extends State<ChatSessionsPage> {
  late final ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController();
    _controller.loadSessions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openChat({ChatSession? session}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          sessionId: session?.id,
          initialTitle: session?.displayTitle,
        ),
      ),
    );

    if (mounted) {
      await _controller.loadSessions();
    }
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _controller.loadSessions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 120),
          if (_controller.sessionsError != null) ...[
            InfoBanner(message: _controller.sessionsError!),
            const SizedBox(height: 24),
          ],
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.forum_outlined,
                  color: AppColors.textSecondary,
                  size: 58,
                ),
                const SizedBox(height: 14),
                const Text(
                  'No tienes conversaciones guardadas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Inicia una nueva consulta cuando lo necesites.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                  onPressed: () => _openChat(),
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Nuevo asistente'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRow(ChatSession session) {
    return InkWell(
      onTap: () => _openChat(session: session),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 18, 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withValues(alpha: 0.65),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.lastActivityLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.7),
          ),
        ),
        title: const Text(
          'Asistente Virtual',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Nuevo chat',
            onPressed: () => _openChat(),
            icon: const Icon(
              Icons.add_comment_outlined,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _controller.isLoadingSessions
                ? null
                : _controller.loadSessions,
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoadingSessions) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (_controller.sessions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _controller.loadSessions,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              itemCount:
                  _controller.sessions.length +
                  (_controller.sessionsError == null ? 0 : 1),
              separatorBuilder: (_, __) => const SizedBox.shrink(),
              itemBuilder: (context, index) {
                if (_controller.sessionsError != null && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: InfoBanner(message: _controller.sessionsError!),
                  );
                }

                final offset = _controller.sessionsError == null ? 0 : 1;
                return _buildSessionRow(_controller.sessions[index - offset]);
              },
            ),
          );
        },
      ),
    );
  }
}
