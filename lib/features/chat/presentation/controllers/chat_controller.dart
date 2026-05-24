import 'package:flutter/foundation.dart';

import '../../data/chat_exception.dart';
import '../../data/chat_service.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

class ChatController extends ChangeNotifier {
  ChatController({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  List<ChatSession> sessions = [];
  List<ChatMessage> messages = [];
  ChatSession? currentSession;

  bool isLoadingSessions = false;
  bool isLoadingMessages = false;
  bool isSending = false;

  String? sessionsError;
  String? messagesError;

  Future<void> loadSessions() async {
    isLoadingSessions = true;
    sessionsError = null;
    notifyListeners();

    try {
      sessions = await _service.getSessions();
    } catch (error) {
      sessionsError = _errorMessage(error);
    } finally {
      isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<bool> openSession(int sessionId) async {
    isLoadingMessages = true;
    messagesError = null;
    notifyListeners();

    try {
      final detail = await _service.getSession(sessionId);
      currentSession = detail.session;
      messages = detail.messages;
      return true;
    } catch (error) {
      messagesError = _errorMessage(error);
      return false;
    } finally {
      isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> reloadCurrentMessages() async {
    final sessionId = currentSession?.id;
    if (sessionId == null) {
      return;
    }

    isLoadingMessages = true;
    messagesError = null;
    notifyListeners();

    try {
      messages = await _service.getMessages(sessionId);
    } catch (error) {
      messagesError = _errorMessage(error);
    } finally {
      isLoadingMessages = false;
      notifyListeners();
    }
  }

  void startNewSession() {
    currentSession = null;
    messages = [];
    messagesError = null;
    notifyListeners();
  }

  Future<bool> sendMessage(String content) async {
    final message = content.trim();
    if (message.isEmpty) {
      messagesError = 'Escribe un mensaje antes de enviarlo.';
      notifyListeners();
      return false;
    }

    if (message.length > 2000) {
      messagesError = 'El mensaje no puede superar los 2000 caracteres.';
      notifyListeners();
      return false;
    }

    isSending = true;
    messagesError = null;
    notifyListeners();

    try {
      final session = currentSession;
      if (session == null) {
        final detail = await _service.createSession(message);
        currentSession = detail.session;
        messages = detail.messages;
      } else {
        final exchange = await _service.sendMessage(session.id, message);
        messages = [
          ...messages,
          exchange.userMessage,
          exchange.assistantMessage,
        ];
      }

      await _refreshSessionsSilently();
      return true;
    } catch (error) {
      messagesError = _errorMessage(error);
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> _refreshSessionsSilently() async {
    try {
      sessions = await _service.getSessions();
    } catch (_) {
      // The conversation already succeeded; keep the chat usable if history
      // refresh fails.
    }
  }

  String _errorMessage(Object error) {
    if (error is ChatException) {
      return error.message;
    }
    return 'Ocurrio un error inesperado.';
  }
}
