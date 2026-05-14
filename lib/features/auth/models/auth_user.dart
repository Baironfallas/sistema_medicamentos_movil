class AuthUser {
  const AuthUser({
    required this.userId,
    required this.identification,
    required this.firstName,
    required this.firstLastName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.secondName,
    this.secondLastName,
  });

  final int userId;
  final String identification;
  final String firstName;
  final String? secondName;
  final String firstLastName;
  final String? secondLastName;
  final String email;
  final String role;
  final String createdAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: _toInt(json['userId']),
      identification: _toString(json['identification']),
      firstName: _toString(json['firstName']),
      secondName: _nullableString(json['secondName']),
      firstLastName: _toString(json['firstLastName']),
      secondLastName: _nullableString(json['secondLastName']),
      email: _toString(json['email']),
      role: _toString(json['role']),
      createdAt: _toString(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'identification': identification,
      'firstName': firstName,
      'secondName': secondName,
      'firstLastName': firstLastName,
      'secondLastName': secondLastName,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }

  String get displayName => '$firstName $firstLastName'.trim();

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(Object? value) => value?.toString() ?? '';

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
