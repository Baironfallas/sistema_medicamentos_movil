class ApiConfig {
  ApiConfig._();

  /// Override with:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sistema-medicamentos-backend-production.up.railway.app',
  );

  static Uri endpoint(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBaseUrl$normalizedPath');
  }
}
