import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:typetwo/services/glossary_remote_client.dart';
import 'package:typetwo/services/glossary_remote_service.dart';

void main() {
  test('GlossaryRemoteClient headersFor 會依 token 加入 Authorization', () {
    expect(GlossaryRemoteClient.headersFor(''), {'Accept': 'application/json'});
    expect(GlossaryRemoteClient.headersFor(' token-1 '), {
      'Accept': 'application/json',
      'Authorization': 'Bearer token-1',
    });
  });

  test('GlossaryRemoteClient normalizeBaseUrl 會移除尾端斜線與空白', () {
    expect(
      GlossaryRemoteClient.normalizeBaseUrl(' http://localhost:18000/// '),
      'http://localhost:18000',
    );
  });

  test('GlossaryRemoteClient send 會送出 JSON body 並解析 Map 回應', () async {
    final client = GlossaryRemoteClient(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://localhost/auth/login');
        expect(request.headers['authorization'], 'Bearer token-1');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), {'email': 'admin@example.com'});
        return http.Response(
          jsonEncode({'ok': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final response = await client.send(
      baseUrl: 'http://localhost/',
      token: 'token-1',
      method: 'POST',
      path: '/auth/login',
      body: {'email': 'admin@example.com'},
    );

    expect(response, {'ok': true});
  });

  test('GlossaryRemoteClient sendUri 允許 204 空回應', () async {
    final client = GlossaryRemoteClient(
      client: MockClient((_) async => http.Response('', 204)),
    );

    final response = await client.sendUri(
      uri: Uri.parse('http://localhost/glossary/term-1'),
      token: 'token-1',
      method: 'DELETE',
      expectedStatus: 204,
    );

    expect(response, isNull);
  });

  test('GlossaryRemoteClient sendUri 非預期 status 會丟 GlossaryRemoteException',
      () async {
    final client = GlossaryRemoteClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'db failed'}),
          500,
          headers: {'x-request-id': 'rid-500'},
        ),
      ),
    );

    await expectLater(
      client.sendUri(
        uri: Uri.parse('http://localhost/glossary'),
        token: '',
        method: 'GET',
      ),
      throwsA(
        isA<GlossaryRemoteException>().having(
          (e) => e.message,
          'message',
          contains('TypeTwo Server 發生錯誤 (500)：db failed（Request ID: rid-500）'),
        ),
      ),
    );
  });

  test('GlossaryRemoteClient 401 會提示重新登入', () async {
    final client = GlossaryRemoteClient(
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'detail': '使用者不存在或已停用'})),
          401,
        ),
      ),
    );

    await expectLater(
      client.send(
        baseUrl: 'http://localhost',
        token: 'expired-token',
        method: 'GET',
        path: '/glossary',
      ),
      throwsA(
        isA<GlossaryRemoteException>().having(
          (e) => e.message,
          'message',
          '登入已失效，請重新登入：使用者不存在或已停用',
        ),
      ),
    );
  });

  test('GlossaryRemoteClient 429 會提示稍後再試', () async {
    final client = GlossaryRemoteClient(
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'detail': '登入失敗次數過多，請稍後再試'})),
          429,
        ),
      ),
    );

    await expectLater(
      client.send(
        baseUrl: 'http://localhost',
        token: '',
        method: 'POST',
        path: '/auth/login',
        body: {'email': 'user@example.com', 'password': 'wrong'},
      ),
      throwsA(
        isA<GlossaryRemoteException>().having(
          (e) => e.message,
          'message',
          '登入嘗試太頻繁，請稍後再試：登入失敗次數過多，請稍後再試',
        ),
      ),
    );
  });

  test('GlossaryRemoteClient 無效 JSON 會給格式錯誤', () async {
    final client = GlossaryRemoteClient(
      client: MockClient((_) async => http.Response('{bad json', 200)),
    );

    await expectLater(
      client.send(
        baseUrl: 'http://localhost',
        token: '',
        method: 'GET',
        path: '/glossary',
      ),
      throwsA(
        isA<GlossaryRemoteException>().having(
          (e) => e.message,
          'message',
          contains('詞彙表 API 回應不是有效 JSON'),
        ),
      ),
    );
  });

  test('GlossaryRemoteClient send 要求回應必須是 Map', () async {
    final client = GlossaryRemoteClient(
      client: MockClient((_) async => http.Response(jsonEncode([]), 200)),
    );

    await expectLater(
      client.send(
        baseUrl: 'http://localhost',
        token: '',
        method: 'GET',
        path: '/glossary',
      ),
      throwsA(isA<GlossaryRemoteException>()),
    );
  });

  test('GlossaryRemoteService resetUserPassword 會解析臨時密碼', () async {
    final service = GlossaryRemoteService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost/users/user-1/reset-password',
        );
        return http.Response(
          jsonEncode({
            'user': {
              'id': 'user-1',
              'email': 'user@example.com',
              'role': 'user',
              'isActive': true,
              'mustChangePassword': true,
              'createdAt': '2026-05-28T01:02:03Z',
              'updatedAt': '2026-05-28T02:03:04Z',
              'lastLoginAt': '2026-05-28T03:04:05Z',
            },
            'temporaryPassword': 'temporary-secret',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.resetUserPassword(
      baseUrl: 'http://localhost',
      token: 'token-1',
      id: 'user-1',
    );

    expect(result.user.email, 'user@example.com');
    expect(result.user.mustChangePassword, isTrue);
    expect(result.user.createdAt?.toUtc().year, 2026);
    expect(result.user.lastLoginAt?.toUtc().hour, 3);
    expect(result.temporaryPassword, 'temporary-secret');
  });

  test('GlossaryRemoteService rejectTerm 會送出退回原因', () async {
    final service = GlossaryRemoteService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
            request.url.toString(), 'http://localhost/glossary/term-1/reject');
        expect(jsonDecode(request.body), {'reason': '譯文不符合公司用語'});
        return http.Response(
          jsonEncode({
            'id': 'term-1',
            'sourceText': '待退回詞',
            'targetText': 'Rejected term',
            'contextKey': 'global',
            'status': 'rejected',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.rejectTerm(
      baseUrl: 'http://localhost',
      token: 'token-1',
      id: 'term-1',
      reason: ' 譯文不符合公司用語 ',
    );

    expect(result.status, 'rejected');
  });

  test('GlossaryRemoteService listTermHistory 會解析 history 與退回原因', () async {
    final service = GlossaryRemoteService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
            request.url.toString(), 'http://localhost/glossary/term-1/history');
        return http.Response(
          jsonEncode([
            {
              'id': 'history-1',
              'termId': 'term-1',
              'sourceText': '待退回詞',
              'targetText': 'Rejected term',
              'contextKey': 'global',
              'status': 'rejected',
              'version': 2,
              'operation': 'reject',
              'reason': '譯文不符合公司用語',
              'changedAt': '2026-05-29T01:02:03Z',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.listTermHistory(
      baseUrl: 'http://localhost',
      token: 'token-1',
      id: 'term-1',
    );

    expect(result.single.operation, 'reject');
    expect(result.single.reason, '譯文不符合公司用語');
    expect(result.single.changedAt?.toUtc().year, 2026);
  });

  test('GlossaryImportPayload 可解析 AppConfig JSON 與扁平詞彙 JSON', () {
    final appConfigPayload = GlossaryImportPayload.fromJson({
      'glossary': {'申請': 'Apply'},
      'langGlossary': {
        '繁體中文-越南文': {'簽核': 'Ký duyệt'},
      },
    });

    expect(appConfigPayload.termCount, 2);
    expect(appConfigPayload.glossary, {'申請': 'Apply'});
    expect(appConfigPayload.conflictStrategy, 'overwrite');
    expect(appConfigPayload.langGlossary['繁體中文-越南文'], {
      '簽核': 'Ký duyệt',
    });

    final flatPayload = GlossaryImportPayload.fromJson({
      '入口網站': 'Portal',
      '採購': 'Purchase',
    });

    expect(flatPayload.termCount, 2);
    expect(flatPayload.glossary['入口網站'], 'Portal');
  });

  test('GlossaryRemoteService previewImport 與 importGlossary 會送出匯入 payload',
      () async {
    final requests = <String>[];
    final service = GlossaryRemoteService(
      client: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        expect(request.headers['authorization'], 'Bearer token-1');
        expect(jsonDecode(request.body), {
          'glossary': {'申請': 'Apply'},
          'langGlossary': {
            '繁體中文-越南文': {'簽核': 'Ký duyệt'},
          },
          'status': 'approved',
          'conflictStrategy': 'keepExisting',
        });
        if (request.url.path.endsWith('/preview')) {
          return http.Response(
            jsonEncode({
              'imported': 1,
              'updated': 1,
              'unchanged': 0,
              'skipped': 0,
              'items': [
                {
                  'action': 'updated',
                  'contextKey': 'global',
                  'sourceText': '申請',
                  'targetText': 'Apply',
                  'status': 'approved',
                  'currentTargetText': 'Submit',
                  'currentStatus': 'approved',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'imported': 1, 'updated': 1}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    const payload = GlossaryImportPayload(
      glossary: {'申請': 'Apply'},
      langGlossary: {
        '繁體中文-越南文': {'簽核': 'Ký duyệt'},
      },
      conflictStrategy: 'keepExisting',
    );

    final preview = await service.previewImport(
      baseUrl: 'http://localhost',
      token: 'token-1',
      payload: payload,
    );
    final imported = await service.importGlossary(
      baseUrl: 'http://localhost',
      token: 'token-1',
      payload: payload,
    );

    expect(preview.writableCount, 2);
    expect(preview.items.single.currentTargetText, 'Submit');
    expect(imported.imported, 1);
    expect(imported.updated, 1);
    expect(requests, [
      'POST /glossary/import/preview',
      'POST /glossary/import',
    ]);
  });

  test('GlossaryRemoteService restoreTermHistory 會呼叫 history restore endpoint',
      () async {
    final service = GlossaryRemoteService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost/glossary/term-1/history/history-1/restore',
        );
        return http.Response(
          jsonEncode({
            'id': 'term-1',
            'sourceText': '回復詞',
            'targetText': 'Original',
            'contextKey': 'global',
            'status': 'approved',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.restoreTermHistory(
      baseUrl: 'http://localhost',
      token: 'token-1',
      id: 'term-1',
      historyId: 'history-1',
    );

    expect(result.targetText, 'Original');
  });
}
