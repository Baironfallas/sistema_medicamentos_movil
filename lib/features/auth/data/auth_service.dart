import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../models/auth_user.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/logout_request.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import 'auth_exception.dart';
import 'auth_storage.dart';

class AuthService {
  AuthService({http.Client? client, AuthStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? AuthStorage();

  final http.Client _client;
  final AuthStorage _storage;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('/auth/login'),
            headers: _jsonHeaders,
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _decodeObject(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(decoded);
        _validateTokens(loginResponse.accessToken, loginResponse.refreshToken);
        await _storage.saveTokens(
          loginResponse.accessToken,
          loginResponse.refreshToken,
        );
        await _storage.saveUser(loginResponse.user);
        return loginResponse;
      }

      throw AuthException(
        _friendlyMessage(response.statusCode, decoded, AuthAction.login),
      );
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException('No se pudo conectar con el servidor.');
    } on TimeoutException {
      throw const AuthException(
        'La conexión tardó demasiado. Inténtalo nuevamente.',
      );
    } on FormatException {
      throw const AuthException(
        'Ocurrió un error inesperado. Inténtalo nuevamente.',
      );
    } catch (_) {
      throw const AuthException(
        'Ocurrió un error inesperado. Inténtalo nuevamente.',
      );
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('/auth/register'),
            headers: _jsonHeaders,
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = _decodeObject(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final registerResponse = RegisterResponse.fromJson(decoded);
        if (registerResponse.accessToken != null &&
            registerResponse.refreshToken != null) {
          await _storage.saveTokens(
            registerResponse.accessToken!,
            registerResponse.refreshToken!,
          );
        }
        if (registerResponse.user != null) {
          await _storage.saveUser(registerResponse.user!);
        }
        return registerResponse;
      }

      throw AuthException(
        _friendlyMessage(response.statusCode, decoded, AuthAction.register),
      );
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException('No se pudo conectar con el servidor.');
    } on TimeoutException {
      throw const AuthException(
        'La conexión tardó demasiado. Inténtalo nuevamente.',
      );
    } on FormatException {
      throw const AuthException(
        'Ocurrió un error inesperado. Inténtalo nuevamente.',
      );
    } catch (_) {
      throw const AuthException(
        'Ocurrió un error inesperado. Inténtalo nuevamente.',
      );
    }
  }

  Future<bool> logout() async {
    var serverLogoutSucceeded = true;

    try {
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        final response = await _client
            .post(
              ApiConfig.endpoint('/auth/logout'),
              headers: _jsonHeaders,
              body: jsonEncode(
                LogoutRequest(refreshToken: refreshToken).toJson(),
              ),
            )
            .timeout(const Duration(seconds: 15));

        serverLogoutSucceeded =
            response.statusCode >= 200 && response.statusCode < 300;
      }
    } on SocketException {
      serverLogoutSucceeded = false;
    } on TimeoutException {
      serverLogoutSucceeded = false;
    } on FormatException {
      serverLogoutSucceeded = false;
    } catch (_) {
      serverLogoutSucceeded = false;
    } finally {
      await _storage.clearSession();
    }

    return serverLogoutSucceeded;
  }

  Future<String?> getAccessToken() {
    return _storage.getAccessToken();
  }

  Future<String?> getRefreshToken() {
    return _storage.getRefreshToken();
  }

  Future<AuthUser?> getAuthenticatedUser() {
    return _storage.getUser();
  }

  Map<String, dynamic> _decodeObject(List<int> bodyBytes) {
    final body = utf8.decode(bodyBytes);

    if (body.trim().isEmpty) {
      return {};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return {};
  }

  String _friendlyMessage(
    int statusCode,
    Map<String, dynamic> body,
    AuthAction action,
  ) {
    final backendMessage = _extractBackendMessage(body['message']);

    if (action == AuthAction.login &&
        (statusCode == 400 || statusCode == 401 || statusCode == 404)) {
      return 'Correo o contraseña incorrectos.';
    }

    if (action == AuthAction.register && statusCode == 409) {
      return backendMessage ??
          'Ya existe una cuenta registrada con esos datos.';
    }

    if (action == AuthAction.register &&
        (statusCode == 400 || statusCode == 401)) {
      return backendMessage ??
          'No se pudo completar el registro. Verifica los datos ingresados.';
    }

    if (statusCode >= 500) {
      return 'El servidor no respondió correctamente. Inténtalo nuevamente.';
    }

    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    return 'Ocurrió un error inesperado. Inténtalo nuevamente.';
  }

  String? _extractBackendMessage(Object? value) {
    if (value is List && value.isNotEmpty) {
      return value.map((item) => item.toString()).join('\n');
    }
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  void _validateTokens(String accessToken, String refreshToken) {
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const AuthException(
        'Ocurrió un error inesperado. Inténtalo nuevamente.',
      );
    }
  }

  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

enum AuthAction { login, register }
