part of 'translate_service.dart';

Future<String> _ollama(
    String text, AppConfig cfg, Map<String, String> relevant) async {
  final r = await http
      .post(
        Uri.parse(cfg.endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': cfg.model,
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
  final r = await http
      .post(
        Uri.parse(cfg.endpoint),
        headers: _openAICompatibleHeaders(cfg.apiKey),
        body: jsonEncode({
          'model': cfg.model,
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
  final r = await http
      .post(
        Uri.parse(cfg.endpoint),
        headers: {
          'api-key': cfg.apiKey,
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
  final url =
      'https://generativelanguage.googleapis.com/v1beta/models/${cfg.model}:generateContent?key=${cfg.apiKey}';
  final isGemma = cfg.model.toLowerCase().startsWith('gemma');
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
      'thinkingBudget': switch (cfg.thinkingMode) {
        'auto' => -1,
        'thinking' => 8192,
        _ => 0,
      }
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
