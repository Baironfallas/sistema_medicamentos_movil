class LogoutRequest {
  const LogoutRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}
