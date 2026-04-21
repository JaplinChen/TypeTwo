import 'dart:convert';
import 'package:http/http.dart' as http;

class ProviderService {
  static Future<List<String>> fetchModels(
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
          return (body['data'] as List<dynamic>)
              .map((m) => m['id'].toString())
              .where((id) => id.contains('gpt'))
              .toList()
            ..sort();
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
              .where((m) =>
                  ((m as Map<String, dynamic>)['supportedGenerationMethods']
                          as List<dynamic>?)
                      ?.contains('generateContent') ??
                  false)
              .map((m) => (m as Map<String, dynamic>)['name']
                  .toString()
                  .split('/')
                  .last)
              .toList();
        } catch (_) {
          throw Exception('Unexpected Gemini response: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
        }
      default:
        throw Exception('Cannot list models for $provider');
    }
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
