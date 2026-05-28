import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'glossary_remote_models.dart';

class GlossaryRemoteClient {
  GlossaryRemoteClient({http.Client? client})
      : _client = client,
        _ownsClient = client == null;

  final http.Client? _client;
  final bool _ownsClient;

  Future<dynamic> sendUri({
    required Uri uri,
    required String token,
    required String method,
    Object? body,
    int expectedStatus = 200,
  }) async {
    final client = _client ?? http.Client();
    try {
      final headers = headersFor(token);
      if (body != null) headers['Content-Type'] = 'application/json';
      final requestBody = body == null ? null : jsonEncode(body);
      final response = await switch (method) {
        'GET' => client.get(uri, headers: headers),
        'POST' => client.post(uri, headers: headers, body: requestBody),
        'PUT' => client.put(uri, headers: headers, body: requestBody),
        'DELETE' => client.delete(uri, headers: headers),
        _ => throw GlossaryRemoteException('不支援的 HTTP method：$method'),
      }
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != expectedStatus) {
        throw GlossaryRemoteException(
          '詞彙表 API 失敗 (${response.statusCode})：${utf8.decode(response.bodyBytes)}',
        );
      }
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException catch (e) {
      throw GlossaryRemoteException('詞彙表 API 逾時：$e');
    } finally {
      if (_ownsClient) client.close();
    }
  }

  Future<Map<String, dynamic>> send({
    required String baseUrl,
    required String token,
    required String method,
    required String path,
    Object? body,
    int expectedStatus = 200,
  }) async {
    final normalized = normalizeBaseUrl(baseUrl);
    if (normalized.isEmpty) {
      throw const GlossaryRemoteException('尚未設定詞彙表同步 URL');
    }
    final decoded = await sendUri(
      uri: Uri.parse('$normalized$path'),
      token: token,
      method: method,
      body: body,
      expectedStatus: expectedStatus,
    );
    if (decoded is! Map<String, dynamic>) {
      throw const GlossaryRemoteException('詞彙表 API 回應格式錯誤');
    }
    return decoded;
  }

  static Map<String, String> headersFor(String token) {
    final headers = <String, String>{'Accept': 'application/json'};
    final trimmed = token.trim();
    if (trimmed.isNotEmpty) headers['Authorization'] = 'Bearer $trimmed';
    return headers;
  }

  static String normalizeBaseUrl(String value) =>
      value.trim().replaceFirst(RegExp(r'/+$'), '');
}
