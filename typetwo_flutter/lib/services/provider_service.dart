import 'dart:convert';
import 'package:http/http.dart' as http;

class ProviderService {
  static Future<List<(String, String)>> fetchModels(
      String provider, String endpoint, String apiKey) async {
    switch (provider.toLowerCase()) {
      case 'ollama':
        final base = Uri.parse(endpoint).replace(path: '/api/tags').toString();
        final r =
            await http.get(Uri.parse(base)).timeout(const Duration(seconds: 10));
        _assertOk(r);
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          return (body['models'] as List<dynamic>)
              .map((m) => m['name'].toString())
              .where(_isOllamaTranslationModel)
              .map((name) => (name, _ollamaHint(name)))
              .toList();
        } catch (_) {
          throw Exception('Unexpected Ollama response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
        }
      case 'openai':
        final r = await http.get(
          Uri.parse('https://api.openai.com/v1/models'),
          headers: {'Authorization': 'Bearer $apiKey'},
        ).timeout(const Duration(seconds: 10));
        _assertOk(r);
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          final ids = (body['data'] as List<dynamic>)
              .map((m) => m['id'].toString())
              .where(_isOpenAITranslationModel)
              .toList()
            ..sort();
          return ids.map((id) => (id, _openAIHint(id))).toList();
        } catch (_) {
          throw Exception('Unexpected OpenAI response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
        }
      case 'gemini':
        final r = await http.get(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models'),
          headers: {'x-goog-api-key': apiKey},
        ).timeout(const Duration(seconds: 10));
        _assertOk(r);
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          return (body['models'] as List<dynamic>)
              .where((m) {
                final mm = m as Map<String, dynamic>;
                final id = mm['name'].toString().split('/').last;
                final methods =
                    (mm['supportedGenerationMethods'] as List<dynamic>?) ?? [];
                return methods.contains('generateContent') &&
                    _isTranslationModel(id);
              })
              .map((m) {
                final id = (m as Map<String, dynamic>)['name']
                    .toString()
                    .split('/')
                    .last;
                return (id, _geminiHint(id));
              })
              .toList();
        } catch (_) {
          throw Exception('Unexpected Gemini response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
        }
      default:
        throw Exception('Cannot list models for $provider');
    }
  }

  static bool _isOllamaTranslationModel(String name) {
    final lower = name.toLowerCase();
    const visionKeywords = ['llava', 'bakllava', 'moondream', 'cogvlm', 'minicpm-v', 'clip'];
    if (visionKeywords.any((k) => lower.contains(k))) return false;
    if (lower.contains('embed')) return false;
    return true;
  }

  static String _ollamaHint(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gemma')) return '輕量・適合翻譯';
    if (lower.contains('qwen')) return '中文支援佳';
    if (lower.contains('phi')) return '輕量・速度快';
    if (lower.contains('llama') || lower.contains('mistral') || lower.contains('mixtral')) return '通用文字模型';
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
    if (RegExp(r'-0\d\d').hasMatch(id)) return false;
    if (id.contains('-lite')) return false;
    if (id.contains('-preview')) return false;
    if (id.contains('embed')) return false;
    return RegExp(r'^gemini-\d+\.\d+-flash').hasMatch(id);
  }

  static String _geminiHint(String id) {
    if (id.startsWith('gemini-2.5-flash')) return '快速・CP 值高';
    if (id.startsWith('gemini-2.0-flash')) return '穩定・回應快';
    if (RegExp(r'^gemini-\d+\.\d+-flash').hasMatch(id)) return '快速・適合翻譯';
    return '';
  }

  static Future<(bool, String)> checkConnection(
      String provider, String endpoint, String apiKey) async {
    try {
      switch (provider.toLowerCase()) {
        case 'ollama':
          final base =
              Uri.parse(endpoint).replace(path: '/api/tags').toString();
          final r = await http
              .get(Uri.parse(base))
              .timeout(const Duration(seconds: 5));
          return (r.statusCode == 200, '');
        case 'openai':
          final r = await http.get(
            Uri.parse('https://api.openai.com/v1/models'),
            headers: {'Authorization': 'Bearer $apiKey'},
          ).timeout(const Duration(seconds: 5));
          return (r.statusCode == 200, '');
        case 'gemini':
          final r = await http.get(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models'),
            headers: {'x-goog-api-key': apiKey},
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

  static void _assertOk(http.Response r) {
    if (r.statusCode != 200) {
      throw Exception(
          'HTTP ${r.statusCode}: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
    }
  }
}
