part of 'provider_service.dart';

Future<List<(String, String)>> _fetchOllama(
    String endpoint, String apiKey) async {
  final adapter = ProviderService._adapter('ollama', endpoint, apiKey);
  final r = await http
      .get(adapter.modelListUri, headers: adapter.modelListHeaders)
      .timeout(const Duration(seconds: 10));
  ProviderService._assertOk(r, 'ollama');
  try {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return (body['models'] as List<dynamic>)
        .map((m) => m['name'].toString())
        .where(ProviderService._isOllamaTranslationModel)
        .map((name) => (name, ProviderService._ollamaHint(name)))
        .toList();
  } catch (_) {
    throw Exception(
        'Unexpected Ollama response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
  }
}

Future<List<(String, String)>> _fetchOpenAI(
    String endpoint, String apiKey) async {
  final adapter = ProviderService._adapter('openai', endpoint, apiKey);
  final r = await http
      .get(adapter.modelListUri, headers: adapter.modelListHeaders)
      .timeout(const Duration(seconds: 10));
  ProviderService._assertOk(r, 'openai');
  try {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final ids = (body['data'] as List<dynamic>)
        .map((m) => m['id'].toString())
        .where(ProviderService._isOpenAITranslationModel)
        .toList()
      ..sort();
    return ids.map((id) => (id, ProviderService._openAIHint(id))).toList();
  } catch (_) {
    throw Exception(
        'Unexpected OpenAI response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
  }
}

Future<List<(String, String)>> _fetchGemini(
    String endpoint, String apiKey) async {
  final adapter = ProviderService._adapter('gemini', endpoint, apiKey);
  final r = await http
      .get(adapter.modelListUri, headers: adapter.modelListHeaders)
      .timeout(const Duration(seconds: 10));
  ProviderService._assertOk(r, 'gemini');
  try {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final ids = (body['models'] as List<dynamic>).where((m) {
      final mm = m as Map<String, dynamic>;
      final id = mm['name'].toString().split('/').last;
      final methods =
          (mm['supportedGenerationMethods'] as List<dynamic>?) ?? [];
      return methods.contains('generateContent') &&
          ProviderService._isTranslationModel(id);
    }).map((m) {
      return (m as Map<String, dynamic>)['name'].toString().split('/').last;
    }).toList()
      ..sort();
    return ids.map((id) => (id, ProviderService._geminiHint(id))).toList();
  } catch (_) {
    throw Exception(
        'Unexpected Gemini response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
  }
}

Future<List<(String, String)>> _fetchGroq(
    String endpoint, String apiKey) async {
  final adapter = ProviderService._adapter('groq', endpoint, apiKey);
  final r = await http
      .get(adapter.modelListUri, headers: adapter.modelListHeaders)
      .timeout(const Duration(seconds: 10));
  ProviderService._assertOk(r, 'groq');
  try {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    const blocked = ['whisper', 'tts', 'embed', 'vision', 'guard', 'tool'];
    final ids = (body['data'] as List<dynamic>)
        .map((m) => (m as Map<String, dynamic>)['id'].toString())
        .where((id) => !blocked.any(id.toLowerCase().contains))
        .toList()
      ..sort();
    return ids.map((id) => (id, ProviderService._groqHint(id))).toList();
  } catch (_) {
    throw Exception(
        'Unexpected Groq response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
  }
}
