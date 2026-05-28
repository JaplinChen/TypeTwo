import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:typetwo/services/glossary_remote_client.dart';
import 'package:typetwo/services/glossary_remote_models.dart';

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
      client: MockClient((_) async => http.Response('failed', 500)),
    );

    await expectLater(
      client.sendUri(
        uri: Uri.parse('http://localhost/glossary'),
        token: '',
        method: 'GET',
      ),
      throwsA(isA<GlossaryRemoteException>()),
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
}
