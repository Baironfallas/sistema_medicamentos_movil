class ApiConfig {
  ApiConfig._();

  /// Override with:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'http://10.0.2.2:3000',
    defaultValue: 'http://localhost:3000',
  );

  static Uri endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }
}
