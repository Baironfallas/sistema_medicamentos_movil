class RegisterRequest {
  const RegisterRequest({
    required this.identification,
    required this.firstName,
    required this.firstLastName,
    required this.email,
    required this.password,
    this.secondName,
    this.secondLastName,
  });

  final String identification;
  final String firstName;
  final String? secondName;
  final String firstLastName;
  final String? secondLastName;
  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'identification': identification.trim(),
      'firstName': firstName.trim(),
      if (_hasText(secondName)) 'secondName': secondName!.trim(),
      'firstLastName': firstLastName.trim(),
      if (_hasText(secondLastName)) 'secondLastName': secondLastName!.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
