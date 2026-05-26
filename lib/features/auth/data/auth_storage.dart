import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_user.dart';

class AuthStorage {
  AuthStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';

  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;
  static AuthUser? _cachedUser;

  final FlutterSecureStorage _secureStorage;

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    final cached = _cachedAccessToken;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final token = await _secureStorage.read(key: _accessTokenKey);
    _cachedAccessToken = token;
    return token;
  }

  Future<String?> getRefreshToken() async {
    final cached = _cachedRefreshToken;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final token = await _secureStorage.read(key: _refreshTokenKey);
    _cachedRefreshToken = token;
    return token;
  }

  Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<void> saveUser(AuthUser user) {
    _cachedUser = user;
    return _secureStorage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<AuthUser?> getUser() async {
    final cached = _cachedUser;
    if (cached != null) {
      return cached;
    }

    final rawUser = await _secureStorage.read(key: _userKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is Map<String, dynamic>) {
        final user = AuthUser.fromJson(decoded);
        _cachedUser = user;
        return user;
      }
      if (decoded is Map) {
        final user = AuthUser.fromJson(decoded.cast<String, dynamic>());
        _cachedUser = user;
        return user;
      }
    } on FormatException {
      await _secureStorage.delete(key: _userKey);
    }

    _cachedUser = null;

    return null;
  }

  Future<void> clearUser() {
    _cachedUser = null;
    return _secureStorage.delete(key: _userKey);
  }

  Future<void> clearSession() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
    await Future.wait([clearTokens(), clearUser()]);
  }

  Future<bool> hasSession() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
