import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/auth_storage.dart';
import '../models/chat_message.dart';
import '../models/chat_message_exchange.dart';
import '../models/chat_session.dart';
import '../models/chat_session_detail.dart';
import 'chat_exception.dart';

class ChatService {
  ChatService({
    http.Client? client,
    AuthStorage? storage,
    AuthService? authService,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? AuthStorage() {
    _authService = authService ?? AuthService(client: _client, storage: _storage);
  }

  final http.Client _client;
  final AuthStorage _storage;
  late final AuthService _authService;

  Future<List<ChatSession>> getSessions() async {
    return _guard(() async {
      final response = await _sendWithAuthRetry(
        (headers) => _client
            .get(ApiConfig.endpoint('/chat-sessions'), headers: headers)
            .timeout(const Duration(seconds: 20)),
      );

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);

      final items = _extractList(decoded, ['data', 'items', 'sessions']);
      return items
          .whereType<Map>()
          .map((item) => ChatSession.fromJson(item.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<ChatSessionDetail> createSession(String content) async {
    return _guard(() async {
      final response = await _sendWithAuthRetry(
        (headers) => _client
            .post(
              ApiConfig.endpoint('/chat-sessions'),
              headers: headers,
              body: jsonEncode({'content': content.trim()}),
            )
            .timeout(const Duration(seconds: 45)),
      );

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);

      final data = _extractObject(decoded, ['data', 'sessionDetail']);
      if (data.isEmpty) {
        throw const ChatException('No se pudo leer la sesion de chat.');
      }

      return ChatSessionDetail.fromJson(data);
    });
  }

  Future<ChatSessionDetail> getSession(int sessionId) async {
    return _guard(() async {
      final response = await _sendWithAuthRetry(
        (headers) => _client
            .get(
              ApiConfig.endpoint('/chat-sessions/$sessionId'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 20)),
      );

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);

      final data = _extractObject(decoded, ['data', 'sessionDetail']);
      if (data.isEmpty) {
        throw const ChatException('No se pudo leer la sesion de chat.');
      }

      return ChatSessionDetail.fromJson(data);
    });
  }

  Future<List<ChatMessage>> getMessages(int sessionId) async {
    return _guard(() async {
      final response = await _sendWithAuthRetry(
        (headers) => _client
            .get(
              ApiConfig.endpoint('/chat-sessions/$sessionId/messages'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 20)),
      );

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);

      final items = _extractList(decoded, ['data', 'items', 'messages']);
      return items
          .whereType<Map>()
          .map((item) => ChatMessage.fromJson(item.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<ChatMessageExchange> sendMessage(int sessionId, String content) async {
    return _guard(() async {
      final response = await _sendWithAuthRetry(
        (headers) => _client
            .post(
              ApiConfig.endpoint('/chat-sessions/$sessionId/messages'),
              headers: headers,
              body: jsonEncode({'content': content.trim()}),
            )
            .timeout(const Duration(seconds: 45)),
      );

      final decoded = _decodeResponse(response);
      _throwIfNotSuccess(response, decoded, response.bodyBytes);

      final data = _extractObject(decoded, ['data', 'exchange']);
      if (data.isEmpty) {
        throw const ChatException('No se pudo leer la respuesta del chat.');
      }

      return ChatMessageExchange.fromJson(data);
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ChatException {
      rethrow;
    } on http.ClientException catch (error, stackTrace) {
      debugPrint('ChatService client error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw ChatException(
        'No se pudo completar la solicitud. Verifica que el backend este disponible en ${ApiConfig.baseUrl}.',
      );
    } on SocketException {
      throw const ChatException('No se pudo conectar con el servidor.');
    } on TimeoutException {
      throw const ChatException(
        'La respuesta tardo demasiado. Intenta nuevamente.',
      );
    } on FormatException {
      throw const ChatException(
        'El servidor respondio con datos invalidos.',
      );
    } catch (error, stackTrace) {
      debugPrint('ChatService unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const ChatException(
        'No se pudo completar la solicitud. Intenta nuevamente.',
      );
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const ChatException('Sesion no valida. Inicia sesion.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _sendWithAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final response = await request(await _authHeaders());
    if (response.statusCode != 401) {
      return response;
    }

    final refreshed = await _authService.refreshSession();
    if (!refreshed) {
      return response;
    }

    return request(await _authHeaders());
  }

  dynamic _decodeResponse(http.Response response) {
    final body = _bodyText(response.bodyBytes);
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      debugPrint('ChatService invalid JSON response: $error');
      debugPrint('ChatService raw response: $body');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        rethrow;
      }
      return null;
    }
  }

  String _bodyText(List<int> bodyBytes) {
    return utf8.decode(bodyBytes, allowMalformed: true);
  }

  void _throwIfNotSuccess(
    http.Response response,
    dynamic decoded, [
    List<int>? rawBodyBytes,
  ]) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw ChatException(
      _friendlyMessage(
        response.statusCode,
        decoded,
        rawBodyBytes == null ? null : _bodyText(rawBodyBytes),
      ),
      statusCode: response.statusCode,
    );
  }

  String _friendlyMessage(int statusCode, dynamic decoded, String? rawBody) {
    final backendMessage = _extractBackendMessage(decoded);

    if (statusCode == 401) {
      return backendMessage ?? 'Sesion expirada. Inicia sesion nuevamente.';
    }

    if (statusCode == 403) {
      return 'No tienes permisos para usar este chat.';
    }

    if (statusCode == 404) {
      return backendMessage ?? 'No se encontro la sesion de chat.';
    }

    if (statusCode == 400) {
      return backendMessage ?? 'Escribe un mensaje valido.';
    }

    if (statusCode >= 500) {
      return backendMessage ??
          'El asistente no respondio correctamente. Intenta mas tarde.';
    }

    if (rawBody != null && rawBody.trim().isNotEmpty) {
      return rawBody.trim();
    }

    return backendMessage ??
        'La solicitud fallo con estado HTTP $statusCode. Intenta nuevamente.';
  }

  String? _extractBackendMessage(dynamic decoded) {
    if (decoded is Map) {
      final message = decoded['message'];
      if (message is List && message.isNotEmpty) {
        return message.map((item) => item.toString()).join('\n');
      }
      final text = message?.toString().trim();
      return text == null || text.isEmpty ? null : text;
    }
    return null;
  }

  List<dynamic> _extractList(dynamic decoded, List<String> keys) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map) {
      for (final key in keys) {
        final value = decoded[key];
        if (value is List) {
          return value;
        }
      }
    }
    return [];
  }

  Map<String, dynamic> _extractObject(dynamic decoded, List<String> keys) {
    if (decoded is Map<String, dynamic>) {
      for (final key in keys) {
        final value = decoded[key];
        if (value is Map<String, dynamic>) {
          return value;
        }
        if (value is Map) {
          return value.cast<String, dynamic>();
        }
      }
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return {};
  }
}
