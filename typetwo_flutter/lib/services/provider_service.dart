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

  static void _assertOk(http.Response r) {
    if (r.statusCode != 200) {
      throw Exception(
          'HTTP ${r.statusCode}: ${r.body.substring(0, r.body.length.clamp(0, 200))}');
    }
  }
}
