part of 'translate_service.dart';

Future<String> _ollama(
    String text, AppConfig cfg, Map<String, String> relevant) async {
  final runtime = cfg.providerRuntime;
  final r = await http
      .post(
        Uri.parse(runtime.endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': runtime.model,
          'stream': false,
          'think': false,
          'messages': [
            {'role': 'system', 'content': _systemPrompt(cfg, relevant)},
            {'role': 'user', 'content': _wrap(text)},
          ],
          'options': {
            'temperature': _temp(cfg),
            'num_ctx': 4096,
            'num_predict': 1024,
          },
        }),
      )
      .timeout(const Duration(seconds: 60));
  _assertOk(r);
  try {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return (body['message'] as Map<String, dynamic>)['content']
        .toString()
        .trim();
  } catch (_) {
    throw Exception(
        'Unexpected Ollama response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
  }
}

Future<String> _openai(
    String text, AppConfig cfg, Map<String, String> relevant) async {
  final runtime = cfg.providerRuntime;
  final r = await http
      .post(
        Uri.parse(runtime.endpoint),
        headers: AiProviderHelpers.openAICompatibleHeaders(runtime.apiKey),
        body: jsonEncode({
          'model': runtime.model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt(cfg, relevant)},
            {'role': 'user', 'content': _wrap(text)},
          ],
          'temperature': _temp(cfg),
        }),
      )
      .timeout(const Duration(seconds: 60));
  _assertOk(r);
  try {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>;
    if (choices.isEmpty) throw Exception('empty choices list');
    return (choices[0]['message'] as Map<String, dynamic>)['content']
        .toString()
        .trim();
  } catch (_) {
    throw Exception(
        'Unexpected OpenAI response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
  }
}

Future<String> _azureOpenAI(
    String text, AppConfig cfg, Map<String, String> relevant) async {
  final runtime = cfg.providerRuntime;
  final r = await http
      .post(
        Uri.parse(runtime.endpoint),
        headers: {
          'api-key': runtime.apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': [
            {'role': 'system', 'content': _systemPrompt(cfg, relevant)},
            {'role': 'user', 'content': _wrap(text)},
          ],
          'temperature': _temp(cfg),
        }),
      )
      .timeout(const Duration(seconds: 60));
  _assertOk(r);
  try {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>;
    if (choices.isEmpty) throw Exception('empty choices list');
    return (choices[0]['message'] as Map<String, dynamic>)['content']
        .toString()
        .trim();
  } catch (_) {
    throw Exception(
        'Unexpected Azure OpenAI response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
  }
}

Future<String> _gemini(
    String text, AppConfig cfg, Map<String, String> relevant) async {
  final runtime = cfg.providerRuntime;
  final url =
      'https://generativelanguage.googleapis.com/v1beta/models/${runtime.model}:generateContent?key=${runtime.apiKey}';
  final isGemma = runtime.model.toLowerCase().startsWith('gemma');
  final systemPrompt = _systemPrompt(cfg, relevant);
  final userText = isGemma ? '$systemPrompt\n\n${_wrap(text)}' : _wrap(text);
  final body = <String, dynamic>{
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': userText}
        ]
      }
    ],
    'generationConfig': <String, dynamic>{'temperature': _temp(cfg)},
  };
  if (!isGemma) {
    body['system_instruction'] = {
      'parts': [
        {'text': systemPrompt}
      ]
    };
    (body['generationConfig'] as Map<String, dynamic>)['thinkingConfig'] = {
      'thinkingBudget': runtime.geminiThinkingBudget,
    };
  }
  final r = await http
      .post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 60));
  _assertOk(r);
  try {
    final decoded = jsonDecode(r.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>;
    if (candidates.isEmpty) throw Exception('empty candidates list');
    return ((candidates[0]['content'] as Map<String, dynamic>)['parts']
            as List<dynamic>)[0]['text']
        .toString()
        .trim();
  } catch (_) {
    throw Exception(
        'Unexpected Gemini response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
  }
}
