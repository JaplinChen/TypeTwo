import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_config.dart';

class TranslateService {
  static String _systemPrompt(AppConfig cfg, Map<String, String> relevantGlossary) {
    final parts = [
      'Translate ${cfg.sourceLang} to ${cfg.targetLang}. Output only the translation.',
    ];
    if (relevantGlossary.isNotEmpty) {
      final rules = relevantGlossary.entries.map((e) => '- ${e.key} → ${e.value}').join('\n');
      parts.add('Use these exact translations for the terms below (do not alter them):\n$rules');
    }
    if (cfg.extraInstructions.isNotEmpty) {
      parts.add('Rules:\n${cfg.extraInstructions.map((r) => '- $r').join('\n')}');
    }
    return parts.join('\n\n');
  }

  static double _temp(AppConfig cfg) => cfg.temperature.clamp(0.0, 2.0);

  static Map<String, String> _pickRelevant(String text, Map<String, String> glossary) {
    final out = <String, String>{};
    glossary.forEach((src, tgt) {
      if (src.isNotEmpty && text.contains(src)) out[src] = tgt;
    });
    return out;
  }

  static Future<String> translate(String text, AppConfig cfg) async {
    final relevant = _pickRelevant(text, cfg.glossary);
    final raw = await _callProvider(text, cfg, relevant);
    return cfg.template
        .replaceAll('{source_label}', cfg.sourceLabel)
        .replaceAll('{target_label}', cfg.targetLabel)
        .replaceAll('{source}', text)
        .replaceAll('{translation}', raw);
  }

  static Future<String> _callProvider(String text, AppConfig cfg, Map<String, String> relevant) async {
    switch (cfg.provider.toLowerCase()) {
      case 'ollama':
        return _ollama(text, cfg, relevant);
      case 'openai':
      case 'azure openai':
        return _openai(text, cfg, relevant);
      case 'gemini':
        return _gemini(text, cfg, relevant);
      default:
        throw Exception('Unsupported provider: ${cfg.provider}');
    }
  }

  static Future<String> _ollama(String text, AppConfig cfg, Map<String, String> relevant) async {
    final r = await http.post(
      Uri.parse(cfg.endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': cfg.model,
        'stream': false,
        'messages': [
          {'role': 'system', 'content': _systemPrompt(cfg, relevant)},
          {'role': 'user', 'content': text},
        ],
        'options': {'temperature': _temp(cfg)},
      }),
    ).timeout(const Duration(seconds: 60));
    _assertOk(r);
    return (jsonDecode(r.body) as Map)['message']['content'].toString().trim();
  }

  static Future<String> _openai(String text, AppConfig cfg, Map<String, String> relevant) async {
    final r = await http.post(
      Uri.parse(cfg.endpoint),
      headers: {
        'Authorization': 'Bearer ${cfg.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': cfg.model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt(cfg, relevant)},
          {'role': 'user', 'content': text},
        ],
        'temperature': _temp(cfg),
      }),
    ).timeout(const Duration(seconds: 60));
    _assertOk(r);
    return ((jsonDecode(r.body) as Map)['choices'] as List)[0]['message']
        ['content']
        .toString()
        .trim();
  }

  static Future<String> _gemini(String text, AppConfig cfg, Map<String, String> relevant) async {
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/${cfg.model}:generateContent?key=${cfg.apiKey}';
    final r = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': _systemPrompt(cfg, relevant)}
          ]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': text}
            ]
          }
        ],
        'generationConfig': {'temperature': _temp(cfg)},
      }),
    ).timeout(const Duration(seconds: 60));
    _assertOk(r);
    final candidates = (jsonDecode(r.body) as Map)['candidates'] as List;
    if (candidates.isEmpty) throw Exception('Gemini returned no candidates');
    return candidates[0]['content']['parts'][0]['text'].toString().trim();
  }

  static void _assertOk(http.Response r) {
    if (r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode}: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
    }
  }

  // ── Provider utilities ────────────────────────────────────────────────────

  static Future<List<String>> fetchModels(
      String provider, String endpoint, String apiKey) async {
    switch (provider.toLowerCase()) {
      case 'ollama':
        final base = Uri.parse(endpoint).replace(path: '/api/tags').toString();
        final r = await http.get(Uri.parse(base)).timeout(const Duration(seconds: 10));
        _assertOk(r);
        return ((jsonDecode(r.body) as Map)['models'] as List)
            .map((m) => m['name'].toString())
            .toList();
      case 'openai':
        final r = await http.get(
          Uri.parse('https://api.openai.com/v1/models'),
          headers: {'Authorization': 'Bearer $apiKey'},
        ).timeout(const Duration(seconds: 10));
        _assertOk(r);
        return ((jsonDecode(r.body) as Map)['data'] as List)
            .map((m) => m['id'].toString())
            .where((id) => id.contains('gpt'))
            .toList()
          ..sort();
      case 'gemini':
        final r = await http.get(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
        ).timeout(const Duration(seconds: 10));
        _assertOk(r);
        return ((jsonDecode(r.body) as Map)['models'] as List)
            .where((m) =>
                (m['supportedGenerationMethods'] as List?)
                    ?.contains('generateContent') ??
                false)
            .map((m) => m['name'].toString().split('/').last)
            .toList();
      default:
        throw Exception('Cannot list models for $provider');
    }
  }

  static Future<(bool, String)> checkConnection(
      String provider, String endpoint, String apiKey) async {
    try {
      switch (provider.toLowerCase()) {
        case 'ollama':
          final base = Uri.parse(endpoint).replace(path: '/api/tags').toString();
          final r = await http.get(Uri.parse(base)).timeout(const Duration(seconds: 5));
          return (r.statusCode == 200, '');
        case 'openai':
          final r = await http.get(
            Uri.parse('https://api.openai.com/v1/models'),
            headers: {'Authorization': 'Bearer $apiKey'},
          ).timeout(const Duration(seconds: 5));
          return (r.statusCode == 200, '');
        case 'gemini':
          final r = await http.get(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
          ).timeout(const Duration(seconds: 5));
          return (r.statusCode == 200, '');
        case 'azure openai':
          final r = await http.get(
            Uri.parse(endpoint),
            headers: {'Authorization': 'Bearer $apiKey'},
          ).timeout(const Duration(seconds: 5));
          return ([200, 404, 405].contains(r.statusCode), '');
        default:
          return (false, 'Unknown provider');
      }
    } catch (e) {
      return (false, e.toString());
    }
  }
}
