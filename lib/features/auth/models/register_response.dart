import 'auth_user.dart';

class RegisterResponse {
  const RegisterResponse({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.message,
  });

  final String? accessToken;
  final String? refreshToken;
  final AuthUser? user;
  final String? message;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return RegisterResponse(
      accessToken: _nullableString(json['accessToken']),
      refreshToken: _nullableString(json['refreshToken']),
      user: userJson is Map
          ? AuthUser.fromJson(userJson.cast<String, dynamic>())
          : null,
      message: _messageFromJson(json['message']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (user != null) 'user': user!.toJson(),
      if (message != null) 'message': message,
    };
  }

  bool get hasSession => accessToken != null && refreshToken != null;

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static String? _messageFromJson(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).join('\n');
    }
    return _nullableString(value);
  }
}
