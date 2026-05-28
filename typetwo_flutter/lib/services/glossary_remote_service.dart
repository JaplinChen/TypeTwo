import 'package:http/http.dart' as http;

import 'glossary_remote_client.dart';
import 'glossary_remote_models.dart';

export 'glossary_remote_models.dart';

class GlossaryRemoteService {
  GlossaryRemoteService({http.Client? client})
      : _client = GlossaryRemoteClient(client: client);

  final GlossaryRemoteClient _client;

  Future<GlossaryRemoteBundle> fetchApproved({
    required String baseUrl,
    required String token,
  }) async {
    final normalized = GlossaryRemoteClient.normalizeBaseUrl(baseUrl);
    if (normalized.isEmpty) {
      throw const GlossaryRemoteException('尚未設定詞彙表同步 URL');
    }
    final decoded = await _client.sendUri(
      uri: Uri.parse('$normalized/glossary?status=approved'),
      token: token,
      method: 'GET',
    );
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
  }

  Future<GlossaryLoginResult> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final response = await _client.send(
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
    final normalized = GlossaryRemoteClient.normalizeBaseUrl(baseUrl);
    final decoded = await _client.sendUri(
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
    final decoded = await _client.send(
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
    final decoded = await _client.send(
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
    final normalized = GlossaryRemoteClient.normalizeBaseUrl(baseUrl);
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (contextKey != null) query['contextKey'] = contextKey;
    final uri = Uri.parse('$normalized/glossary/terms').replace(
      queryParameters: query.isEmpty ? null : query,
    );
    final decoded =
        await _client.sendUri(uri: uri, token: token, method: 'GET');
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
    final decoded = await _client.send(
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
    final decoded = await _client.send(
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
    final normalized = GlossaryRemoteClient.normalizeBaseUrl(baseUrl);
    if (normalized.isEmpty) {
      throw const GlossaryRemoteException('尚未設定詞彙表同步 URL');
    }
    await _client.sendUri(
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
    final decoded = await _client.send(
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
    final decoded = await _client.send(
      baseUrl: baseUrl,
      token: token,
      method: 'POST',
      path: '/glossary/$id/reject',
    );
    return GlossaryRemoteTerm.fromJson(decoded);
  }

  static String remoteKey(String contextKey, String sourceText) =>
      _remoteKey(contextKey, sourceText);

  static String _remoteKey(String contextKey, String sourceText) =>
      '$contextKey\n$sourceText';
}
