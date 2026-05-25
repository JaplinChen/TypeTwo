import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GlossaryRemoteBundle {
  const GlossaryRemoteBundle({
    required this.glossary,
    required this.langGlossary,
    required this.syncedAt,
    required this.remoteIds,
  });

  final Map<String, String> glossary;
  final Map<String, Map<String, String>> langGlossary;
  final DateTime syncedAt;
  final Map<String, String> remoteIds;

  factory GlossaryRemoteBundle.fromJson(Map<String, dynamic> json) {
    final rawGlossary = json['glossary'];
    final rawLangGlossary = json['langGlossary'];
    final syncedAtText = json['syncedAt']?.toString();
    return GlossaryRemoteBundle(
      glossary: rawGlossary is Map
          ? rawGlossary.map((k, v) => MapEntry(k.toString(), v.toString()))
          : <String, String>{},
      langGlossary: rawLangGlossary is Map
          ? {
              for (final entry in rawLangGlossary.entries)
                if (entry.value is Map)
                  entry.key.toString(): (entry.value as Map).map(
                    (k, v) => MapEntry(k.toString(), v.toString()),
                  ),
            }
          : <String, Map<String, String>>{},
      syncedAt: DateTime.tryParse(syncedAtText ?? '') ?? DateTime.now().toUtc(),
      remoteIds: <String, String>{},
    );
  }
}

class GlossaryRemoteTerm {
  const GlossaryRemoteTerm({
    required this.id,
    required this.sourceText,
    required this.targetText,
    required this.contextKey,
    required this.status,
  });

  final String id;
  final String sourceText;
  final String targetText;
  final String contextKey;
  final String status;

  factory GlossaryRemoteTerm.fromJson(Map<String, dynamic> json) =>
      GlossaryRemoteTerm(
        id: json['id'].toString(),
        sourceText: json['sourceText']?.toString() ?? '',
        targetText: json['targetText']?.toString() ?? '',
        contextKey: json['contextKey']?.toString() ?? 'global',
        status: json['status']?.toString() ?? 'approved',
      );
}

class GlossaryLoginResult {
  const GlossaryLoginResult({required this.accessToken, required this.role});

  final String accessToken;
  final String role;
}

class GlossaryRemoteUser {
  const GlossaryRemoteUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String email;
  final String role;
  final bool isActive;

  factory GlossaryRemoteUser.fromJson(Map<String, dynamic> json) =>
      GlossaryRemoteUser(
        id: json['id'].toString(),
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'user',
        isActive: json['isActive'] == true,
      );
}

class GlossaryRemoteService {
  GlossaryRemoteService({http.Client? client})
      : _client = client,
        _ownsClient = client == null;

  final http.Client? _client;
  final bool _ownsClient;

  Future<GlossaryRemoteBundle> fetchApproved({
    required String baseUrl,
    required String token,
  }) async {
    final normalized = _normalizeBaseUrl(baseUrl);
    if (normalized.isEmpty) {
      throw const GlossaryRemoteException('尚未設定詞彙表同步 URL');
    }
    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$normalized/glossary?status=approved'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw GlossaryRemoteException(
          '詞彙表同步失敗 (${response.statusCode})：${response.body}',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const GlossaryRemoteException('詞彙表同步回應格式錯誤');
      }
      final bundle = GlossaryRemoteBundle.fromJson(decoded);
      final terms = await listTerms(
        baseUrl: normalized,
        token: token,
        status: 'approved',
      );
      return GlossaryRemoteBundle(
        glossary: bundle.glossary,
        langGlossary: bundle.langGlossary,
        syncedAt: bundle.syncedAt,
        remoteIds: {
          for (final term in terms)
            _remoteKey(term.contextKey, term.sourceText): term.id
        },
      );
    } on TimeoutException catch (e) {
      throw GlossaryRemoteException('詞彙表同步逾時：$e');
    } finally {
      if (_ownsClient) client.close();
    }
  }

  Future<GlossaryLoginResult> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final response = await _send(
      baseUrl: baseUrl,
      token: '',
      method: 'POST',
      path: '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    final token = response['accessToken']?.toString() ?? '';
    if (token.isEmpty) {
      throw const GlossaryRemoteException('登入回應缺少 token');
    }
    return GlossaryLoginResult(
      accessToken: token,
      role: response['role']?.toString() ?? 'user',
    );
  }

  Future<List<GlossaryRemoteUser>> listUsers({
    required String baseUrl,
    required String token,
  }) async {
    final normalized = _normalizeBaseUrl(baseUrl);
    final decoded = await _sendUri(
      uri: Uri.parse('$normalized/users'),
      token: token,
      method: 'GET',
    );
    if (decoded is! List) {
      throw const GlossaryRemoteException('使用者清單回應格式錯誤');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(GlossaryRemoteUser.fromJson)
        .toList();
  }

  Future<GlossaryRemoteUser> createUser({
    required String baseUrl,
    required String token,
    required String email,
    required String password,
    required String role,
  }) async {
    final decoded = await _send(
      baseUrl: baseUrl,
      token: token,
      method: 'POST',
      path: '/users',
      body: {'email': email, 'password': password, 'role': role},
      expectedStatus: 201,
    );
    return GlossaryRemoteUser.fromJson(decoded);
  }

  Future<GlossaryRemoteUser> updateUser({
    required String baseUrl,
    required String token,
    required String id,
    String? role,
    bool? isActive,
  }) async {
    final body = <String, Object>{};
    if (role != null) body['role'] = role;
    if (isActive != null) body['isActive'] = isActive;
    final decoded = await _send(
      baseUrl: baseUrl,
      token: token,
      method: 'PUT',
      path: '/users/$id',
      body: body,
    );
    return GlossaryRemoteUser.fromJson(decoded);
  }

  Future<List<GlossaryRemoteTerm>> listTerms({
    required String baseUrl,
    required String token,
    String? status,
    String? contextKey,
  }) async {
    final normalized = _normalizeBaseUrl(baseUrl);
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (contextKey != null) query['contextKey'] = contextKey;
    final uri = Uri.parse('$normalized/glossary/terms').replace(
      queryParameters: query.isEmpty ? null : query,
    );
    final decoded = await _sendUri(uri: uri, token: token, method: 'GET');
    if (decoded is! List) {
      throw const GlossaryRemoteException('詞彙清單回應格式錯誤');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(GlossaryRemoteTerm.fromJson)
        .toList();
  }

  Future<GlossaryRemoteTerm> createTerm({
    required String baseUrl,
    required String token,
    required String contextKey,
    required String sourceText,
    required String targetText,
  }) async {
    final decoded = await _send(
      baseUrl: baseUrl,
      token: token,
      method: 'POST',
      path: '/glossary',
      body: {
        'contextKey': contextKey,
        'sourceText': sourceText,
        'targetText': targetText,
      },
      expectedStatus: 201,
    );
    return GlossaryRemoteTerm.fromJson(decoded);
  }

  Future<GlossaryRemoteTerm> updateTerm({
    required String baseUrl,
    required String token,
    required String id,
    required String contextKey,
    required String sourceText,
    required String targetText,
  }) async {
    final decoded = await _send(
      baseUrl: baseUrl,
      token: token,
      method: 'PUT',
      path: '/glossary/$id',
      body: {
        'contextKey': contextKey,
        'sourceText': sourceText,
        'targetText': targetText,
      },
    );
    return GlossaryRemoteTerm.fromJson(decoded);
  }

  Future<void> deleteTerm({
    required String baseUrl,
    required String token,
    required String id,
  }) async {
    final normalized = _normalizeBaseUrl(baseUrl);
    if (normalized.isEmpty) {
      throw const GlossaryRemoteException('尚未設定詞彙表同步 URL');
    }
    await _sendUri(
      uri: Uri.parse('$normalized/glossary/$id'),
      token: token,
      method: 'DELETE',
      expectedStatus: 204,
    );
  }

  Future<GlossaryRemoteTerm> approveTerm({
    required String baseUrl,
    required String token,
    required String id,
  }) async {
    final decoded = await _send(
      baseUrl: baseUrl,
      token: token,
      method: 'POST',
      path: '/glossary/$id/approve',
    );
    return GlossaryRemoteTerm.fromJson(decoded);
  }

  Future<GlossaryRemoteTerm> rejectTerm({
    required String baseUrl,
    required String token,
    required String id,
  }) async {
    final decoded = await _send(
      baseUrl: baseUrl,
      token: token,
      method: 'POST',
      path: '/glossary/$id/reject',
    );
    return GlossaryRemoteTerm.fromJson(decoded);
  }

  Future<dynamic> _sendUri({
    required Uri uri,
    required String token,
    required String method,
    Object? body,
    int expectedStatus = 200,
  }) async {
    final client = _client ?? http.Client();
    try {
      final headers = _headers(token);
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

  Future<Map<String, dynamic>> _send({
    required String baseUrl,
    required String token,
    required String method,
    required String path,
    Object? body,
    int expectedStatus = 200,
  }) async {
    final normalized = _normalizeBaseUrl(baseUrl);
    if (normalized.isEmpty) {
      throw const GlossaryRemoteException('尚未設定詞彙表同步 URL');
    }
    final decoded = await _sendUri(
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

  static String remoteKey(String contextKey, String sourceText) =>
      _remoteKey(contextKey, sourceText);

  static String _remoteKey(String contextKey, String sourceText) =>
      '$contextKey\n$sourceText';

  static Map<String, String> _headers(String token) {
    final headers = <String, String>{'Accept': 'application/json'};
    final trimmed = token.trim();
    if (trimmed.isNotEmpty) headers['Authorization'] = 'Bearer $trimmed';
    return headers;
  }

  static String _normalizeBaseUrl(String value) =>
      value.trim().replaceFirst(RegExp(r'/+$'), '');
}

class GlossaryRemoteException implements Exception {
  const GlossaryRemoteException(this.message);

  final String message;

  @override
  String toString() => message;
}
