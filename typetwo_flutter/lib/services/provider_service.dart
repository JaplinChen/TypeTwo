import 'dart:convert';
import 'package:http/http.dart' as http;
import 'provider_error.dart';

class ProviderService {
  static Map<String, String> _openAICompatibleHeaders(String apiKey) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = apiKey.trim();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String _openAICompatibleModelsUrl(String endpoint) {
    final uri = Uri.parse(endpoint);
    final normalizedPath = uri.path.replaceAll(RegExp(r'/+$'), '');
    const suffix = '/chat/completions';
    final modelPath = normalizedPath.endsWith(suffix)
        ? '${normalizedPath.substring(0, normalizedPath.length - suffix.length)}/models'
        : normalizedPath.endsWith('/models')
            ? normalizedPath
            : '$normalizedPath/models';
    return uri.replace(path: modelPath, query: '').toString();
  }

  static Future<List<(String, String)>> fetchModels(
      String provider, String endpoint, String apiKey) async {
    switch (provider.toLowerCase()) {
      case 'ollama':
        final base = Uri.parse(endpoint).replace(path: '/api/tags').toString();
        final r = await http
            .get(Uri.parse(base))
            .timeout(const Duration(seconds: 10));
        _assertOk(r, provider);
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          return (body['models'] as List<dynamic>)
              .map((m) => m['name'].toString())
              .where(_isOllamaTranslationModel)
              .map((name) => (name, _ollamaHint(name)))
              .toList();
        } catch (_) {
          throw Exception(
              'Unexpected Ollama response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
        }
      case 'openai':
        final r = await http.get(
          Uri.parse('https://api.openai.com/v1/models'),
          headers: {'Authorization': 'Bearer $apiKey'},
        ).timeout(const Duration(seconds: 10));
        _assertOk(r, provider);
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          final ids = (body['data'] as List<dynamic>)
              .map((m) => m['id'].toString())
              .where(_isOpenAITranslationModel)
              .toList()
            ..sort();
          return ids.map((id) => (id, _openAIHint(id))).toList();
        } catch (_) {
          throw Exception(
              'Unexpected OpenAI response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
        }
      case 'gemini':
        final r = await http.get(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models'),
          headers: {'x-goog-api-key': apiKey},
        ).timeout(const Duration(seconds: 10));
        _assertOk(r, provider);
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          final ids = (body['models'] as List<dynamic>).where((m) {
            final mm = m as Map<String, dynamic>;
            final id = mm['name'].toString().split('/').last;
            final methods =
                (mm['supportedGenerationMethods'] as List<dynamic>?) ?? [];
            return methods.contains('generateContent') &&
                _isTranslationModel(id);
          }).map((m) {
            return (m as Map<String, dynamic>)['name']
                .toString()
                .split('/')
                .last;
          }).toList()
            ..sort();
          return ids.map((id) => (id, _geminiHint(id))).toList();
        } catch (_) {
          throw Exception(
              'Unexpected Gemini response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
        }
      case 'groq':
        final gr = await http.get(
          Uri.parse('https://api.groq.com/openai/v1/models'),
          headers: _openAICompatibleHeaders(apiKey),
        ).timeout(const Duration(seconds: 10));
        _assertOk(gr, provider);
        try {
          final body = jsonDecode(gr.body) as Map<String, dynamic>;
          const blocked = ['whisper', 'tts', 'embed', 'vision', 'guard', 'tool'];
          final ids = (body['data'] as List<dynamic>)
              .map((m) => (m as Map<String, dynamic>)['id'].toString())
              .where((id) => !blocked.any(id.toLowerCase().contains))
              .toList()
            ..sort();
          return ids.map((id) => (id, _groqHint(id))).toList();
        } catch (_) {
          throw Exception(
              'Unexpected Groq response: ${gr.body.substring(0, gr.body.length.clamp(0, 200))}');
        }
      default:
        throw Exception('Cannot list models for $provider');
    }
  }

  static bool _isOllamaTranslationModel(String name) {
    final lower = name.toLowerCase();
    const visionKeywords = [
      'llava',
      'bakllava',
      'moondream',
      'cogvlm',
      'minicpm-v',
      'clip'
    ];
    if (visionKeywords.any((k) => lower.contains(k))) return false;
    if (lower.contains('embed')) return false;
    return true;
  }

  static String _ollamaHint(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gemma')) return '輕量・適合翻譯';
    if (lower.contains('qwen')) return '中文支援佳';
    if (lower.contains('phi')) return '輕量・速度快';
    if (lower.contains('llama') ||
        lower.contains('mistral') ||
        lower.contains('mixtral')) {
      return '通用文字模型';
    }
    return '';
  }

  static bool _isOpenAITranslationModel(String id) {
    if (!id.contains('gpt')) return false;
    if (id.contains('-vision')) return false;
    if (id.contains('instruct')) return false;
    if (RegExp(r'-\d{4}-\d{2}-\d{2}$').hasMatch(id)) return false;
    if (RegExp(r'-\d{4}$').hasMatch(id)) return false;
    return true;
  }

  static String _openAIHint(String id) {
    if (id.startsWith('gpt-4o-mini')) return '快速・CP 值高';
    if (id.startsWith('gpt-4o')) return '高品質';
    if (id.startsWith('gpt-4-turbo')) return '舊一代 GPT-4';
    if (id.startsWith('gpt-3.5')) return '舊一代・速度快';
    return '';
  }

  static bool _isTranslationModel(String id) {
    final lower = id.toLowerCase();
    if (RegExp(r'-0\d\d').hasMatch(id)) return false;
    if (!lower.startsWith('gemini-')) return false;
    if (lower.contains('-lite')) return false;
    if (lower.contains('-preview')) return false;
    if (lower.contains('embed')) return false;
    const blockedKeywords = [
      'image',
      'vision',
      'audio',
      'speech',
      'transcribe',
      'tts',
      'video',
      'realtime',
      'live',
    ];
    if (blockedKeywords.any(lower.contains)) return false;
    return true;
  }

  static String _groqHint(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('llama-3.3-70b')) return '高品質・免費配額大';
    if (lower.contains('llama-3.1-70b')) return '高品質';
    if (lower.contains('llama') && lower.contains('8b')) return '輕量・速度快';
    if (lower.contains('gemma2')) return '輕量・適合翻譯';
    if (lower.contains('qwen')) return '中文支援佳';
    if (lower.contains('mixtral')) return '多語言・品質佳';
    return '通用文字模型';
  }

  static String _geminiHint(String id) {
    if (id.startsWith('gemini-2.5-flash')) return '快速・CP 值高';
    if (id.startsWith('gemini-2.5-pro')) return '高品質・長文脈絡佳';
    if (id.startsWith('gemini-3')) return '新一代・可用於翻譯';
    if (id.startsWith('gemini-2.0-flash')) return '穩定・回應快';
    if (id.contains('-flash')) return '快速・適合翻譯';
    if (id.contains('-pro')) return '高品質・適合翻譯';
    if (id.startsWith('gemini-')) return '通用文字模型';
    return '';
  }

  static Future<(bool, String)> checkConnection(
      String provider, String endpoint, String apiKey, String model) async {
    try {
      switch (provider.toLowerCase()) {
        case 'ollama':
          final base =
              Uri.parse(endpoint).replace(path: '/api/tags').toString();
          final r = await http
              .get(Uri.parse(base))
              .timeout(const Duration(seconds: 5));
          if (r.statusCode == 200) return (true, '');
          return (
            false,
            formatProviderError(
              ProviderHttpException(
                statusCode: r.statusCode,
                provider: provider,
                body: r.body,
                retryAfter: r.headers['retry-after'],
              ),
            ),
          );
        case 'openai':
          final r = await http
              .post(
                Uri.parse(endpoint),
                headers: _openAICompatibleHeaders(apiKey),
                body: jsonEncode({
                  'model': model,
                  'messages': [
                    {
                      'role': 'user',
                      'content': 'Reply with OK.',
                    }
                  ],
                  'max_tokens': 1,
                  'temperature': 0,
                }),
              )
              .timeout(const Duration(seconds: 5));
          if (r.statusCode == 200) return (true, '');
          return (
            false,
            formatProviderError(
              ProviderHttpException(
                statusCode: r.statusCode,
                provider: provider,
                body: r.body,
                retryAfter: r.headers['retry-after'],
              ),
            ),
          );
        case 'groq':
          final gr = await http
              .get(
                Uri.parse('https://api.groq.com/openai/v1/models'),
                headers: _openAICompatibleHeaders(apiKey),
              )
              .timeout(const Duration(seconds: 5));
          if (gr.statusCode == 200) return (true, '');
          return (
            false,
            formatProviderError(
              ProviderHttpException(
                statusCode: gr.statusCode,
                provider: provider,
                body: gr.body,
                retryAfter: gr.headers['retry-after'],
              ),
            ),
          );
        case 'gemini':
          final r = await http.get(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models'),
            headers: {'x-goog-api-key': apiKey},
          ).timeout(const Duration(seconds: 5));
          if (r.statusCode == 200) {
            if (model.trim().isEmpty) return (true, '');
            try {
              final body = jsonDecode(r.body) as Map<String, dynamic>;
              final models = (body['models'] as List<dynamic>? ?? [])
                  .whereType<Map<String, dynamic>>();
              final exists = models.any((m) {
                final id = m['name'].toString().split('/').last;
                final methods =
                    (m['supportedGenerationMethods'] as List<dynamic>?) ?? [];
                return id == model && methods.contains('generateContent');
              });
              if (exists) return (true, '');
              return (false, 'Gemini 模型不存在、未開放，或不支援 generateContent：$model');
            } catch (_) {
              return (true, '');
            }
          }
          return (
            false,
            formatProviderError(
              ProviderHttpException(
                statusCode: r.statusCode,
                provider: provider,
                body: r.body,
                retryAfter: r.headers['retry-after'],
              ),
            ),
          );
        case 'azure openai':
          final r = await http
              .post(
                Uri.parse(endpoint),
                headers: {
                  'api-key': apiKey,
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'messages': [
                    {
                      'role': 'user',
                      'content': 'Reply with OK.',
                    }
                  ],
                  'max_tokens': 1,
                  'temperature': 0,
                }),
              )
              .timeout(const Duration(seconds: 5));
          if (r.statusCode == 200) return (true, '');
          return (
            false,
            formatProviderError(
              ProviderHttpException(
                statusCode: r.statusCode,
                provider: provider,
                body: r.body,
                retryAfter: r.headers['retry-after'],
              ),
            ),
          );
        default:
          return (false, 'Unknown provider');
      }
    } catch (e) {
      return (false, formatProviderError(e));
    }
  }

  static void _assertOk(http.Response r, String provider) {
    if (r.statusCode != 200) {
      throw ProviderHttpException(
        statusCode: r.statusCode,
        provider: provider,
        body: r.body.substring(0, r.body.length.clamp(0, 400)),
        retryAfter: r.headers['retry-after'],
      );
    }
  }
}
