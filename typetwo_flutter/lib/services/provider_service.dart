import 'dart:convert';
import 'package:http/http.dart' as http;
import 'provider_error.dart';

part 'provider_service_fetch.dart';
part 'provider_service_check.dart';

class ProviderService {
  static Map<String, String> _openAICompatibleHeaders(String apiKey) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = apiKey.trim();
    if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<List<(String, String)>> fetchModels(
      String provider, String endpoint, String apiKey) async {
    switch (provider.toLowerCase()) {
      case 'ollama':
        return _fetchOllama(endpoint, apiKey);
      case 'openai':
        return _fetchOpenAI(endpoint, apiKey);
      case 'gemini':
        return _fetchGemini(endpoint, apiKey);
      case 'groq':
        return _fetchGroq(endpoint, apiKey);
      default:
        throw Exception('Cannot list models for $provider');
    }
  }

  static Future<(bool, String)> checkConnection(
      String provider, String endpoint, String apiKey, String model) async {
    try {
      switch (provider.toLowerCase()) {
        case 'ollama':
          return _checkOllama(endpoint, apiKey, model);
        case 'openai':
          return _checkOpenAI(endpoint, apiKey, model);
        case 'groq':
          return _checkGroq(endpoint, apiKey, model);
        case 'gemini':
          return _checkGemini(endpoint, apiKey, model);
        case 'azure openai':
          return _checkAzure(endpoint, apiKey, model);
        default:
          return (false, 'Unknown provider');
      }
    } catch (e) {
      return (false, formatProviderError(e));
    }
  }

  // ── Ollama ─────────────────────────────────────────────────────────────────

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
    if (lower.contains('llama') || lower.contains('mistral') || lower.contains('mixtral')) {
      return '通用文字模型';
    }
    return '';
  }

  // ── OpenAI ─────────────────────────────────────────────────────────────────

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

  // ── Gemini ─────────────────────────────────────────────────────────────────

  static bool _isTranslationModel(String id) {
    final lower = id.toLowerCase();
    if (RegExp(r'-0\d\d').hasMatch(id)) return false;
    if (!lower.startsWith('gemini-')) return false;
    if (lower.contains('-lite')) return false;
    if (lower.contains('-preview')) return false;
    if (lower.contains('embed')) return false;
    const blockedKeywords = [
      'image', 'vision', 'audio', 'speech', 'transcribe',
      'tts', 'video', 'realtime', 'live',
    ];
    if (blockedKeywords.any(lower.contains)) return false;
    return true;
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

  // ── Groq ───────────────────────────────────────────────────────────────────

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

  // ── Shared ─────────────────────────────────────────────────────────────────

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
