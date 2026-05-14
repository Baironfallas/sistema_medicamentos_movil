import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_user.dart';

class AuthStorage {
  AuthStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() {
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<void> saveUser(AuthUser user) {
    return _secureStorage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<AuthUser?> getUser() async {
    final rawUser = await _secureStorage.read(key: _userKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is Map<String, dynamic>) {
        return AuthUser.fromJson(decoded);
      }
      if (decoded is Map) {
        return AuthUser.fromJson(decoded.cast<String, dynamic>());
      }
    } on FormatException {
      await _secureStorage.delete(key: _userKey);
    }

    return null;
  }

  Future<void> clearUser() {
    return _secureStorage.delete(key: _userKey);
  }

  Future<void> clearSession() async {
    await Future.wait([clearTokens(), clearUser()]);
  }

  Future<bool> hasSession() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
