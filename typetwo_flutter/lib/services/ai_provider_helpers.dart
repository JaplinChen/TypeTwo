class AiProviderHelpers {
  const AiProviderHelpers._();

  static Map<String, String> openAICompatibleHeaders(String apiKey) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = apiKey.trim();
    if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Uri openAICompatibleModelsUri({
    required String endpoint,
    required String defaultUrl,
  }) {
    if (endpoint.trim().isEmpty) return Uri.parse(defaultUrl);
    final uri = Uri.parse(endpoint);
    final path = uri.path.replaceFirst(
      RegExp(r'/chat/completions/?$'),
      '/models',
    );
    if (path != uri.path) return _replacePathWithoutQuery(uri, path);
    return _replacePathWithoutQuery(uri, '/v1/models');
  }

  static Uri _replacePathWithoutQuery(Uri uri, String path) {
    if (uri.hasPort) {
      return Uri(
        scheme: uri.scheme,
        userInfo: uri.userInfo,
        host: uri.host,
        port: uri.port,
        path: path,
      );
    }
    return Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      path: path,
    );
  }
}
