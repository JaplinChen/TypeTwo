part of 'provider_service.dart';

Future<(bool, String)> _checkOllama(
    String endpoint, String apiKey, String model) async {
  final adapter = ProviderService._adapter('ollama', endpoint, apiKey);
  final r = await http
      .get(adapter.modelListUri, headers: adapter.modelListHeaders)
      .timeout(const Duration(seconds: 5));
  if (r.statusCode == 200) return (true, '');
  return (
    false,
    formatProviderError(ProviderHttpException(
      statusCode: r.statusCode,
      provider: 'ollama',
      body: r.body,
      retryAfter: r.headers['retry-after'],
    )),
  );
}

Future<(bool, String)> _checkOpenAI(
    String endpoint, String apiKey, String model) async {
  final adapter = ProviderService._adapter('openai', endpoint, apiKey);
  final r = await http
      .get(
        adapter.modelListUri,
        headers: adapter.modelListHeaders,
      )
      .timeout(const Duration(seconds: 5));
  if (r.statusCode == 200) return (true, '');
  return (
    false,
    formatProviderError(ProviderHttpException(
      statusCode: r.statusCode,
      provider: 'openai',
      body: r.body,
      retryAfter: r.headers['retry-after'],
    )),
  );
}

Future<(bool, String)> _checkGroq(
    String endpoint, String apiKey, String model) async {
  final adapter = ProviderService._adapter('groq', endpoint, apiKey);
  final r = await http
      .get(
        adapter.modelListUri,
        headers: adapter.modelListHeaders,
      )
      .timeout(const Duration(seconds: 5));
  if (r.statusCode == 200) return (true, '');
  return (
    false,
    formatProviderError(ProviderHttpException(
      statusCode: r.statusCode,
      provider: 'groq',
      body: r.body,
      retryAfter: r.headers['retry-after'],
    )),
  );
}

Future<(bool, String)> _checkGemini(
    String endpoint, String apiKey, String model) async {
  final adapter = ProviderService._adapter('gemini', endpoint, apiKey);
  final r = await http
      .get(adapter.modelListUri, headers: adapter.modelListHeaders)
      .timeout(const Duration(seconds: 5));
  if (r.statusCode != 200) {
    return (
      false,
      formatProviderError(ProviderHttpException(
        statusCode: r.statusCode,
        provider: 'gemini',
        body: r.body,
        retryAfter: r.headers['retry-after'],
      )),
    );
  }
  if (model.trim().isEmpty) return (true, '');
  try {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final models = (body['models'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();
    final exists = models.any((m) {
      final id = m['name'].toString().split('/').last;
      final methods = (m['supportedGenerationMethods'] as List<dynamic>?) ?? [];
      return id == model && methods.contains('generateContent');
    });
    if (exists) return (true, '');
    return (false, 'Gemini 模型不存在、未開放，或不支援 generateContent：$model');
  } catch (_) {
    return (true, '');
  }
}

Future<(bool, String)> _checkAzure(
    String endpoint, String apiKey, String model) async {
  final r = await http
      .post(
        Uri.parse(endpoint),
        headers: {
          'api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': [
            {'role': 'user', 'content': 'Reply with OK.'}
          ],
          'max_tokens': 1,
          'temperature': 0,
        }),
      )
      .timeout(const Duration(seconds: 5));
  if (r.statusCode == 200) return (true, '');
  return (
    false,
    formatProviderError(ProviderHttpException(
      statusCode: r.statusCode,
      provider: 'azure openai',
      body: r.body,
      retryAfter: r.headers['retry-after'],
    )),
  );
}
