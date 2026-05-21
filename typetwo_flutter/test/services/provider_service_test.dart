import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/services/provider_service.dart';

void main() {
  group('ProviderService', () {
    test('OpenAI 模型列表使用自訂 endpoint 的同源 /models', () async {
      late String requestedPath;
      late String? authorization;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        requestedPath = request.uri.path;
        authorization = request.headers.value(HttpHeaders.authorizationHeader);
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'data': [
              {'id': 'gpt-4o-mini'},
              {'id': 'whisper-1'},
            ],
          }));
        await request.response.close();
      });

      final models = await ProviderService.fetchModels(
        'OpenAI',
        'http://127.0.0.1:${server.port}/v1/chat/completions',
        'sk-test',
      );

      expect(requestedPath, '/v1/models');
      expect(authorization, 'Bearer sk-test');
      expect(models.map((m) => m.$1), ['gpt-4o-mini']);
    });

    test('Groq 連線檢查使用自訂 endpoint 的同源 /models', () async {
      late String requestedPath;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        requestedPath = request.uri.path;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'data': []}));
        await request.response.close();
      });

      final result = await ProviderService.checkConnection(
        'Groq',
        'http://127.0.0.1:${server.port}/openai/v1/chat/completions',
        'gsk-test',
        'llama-3.3-70b-versatile',
      );

      expect(result.$1, isTrue);
      expect(requestedPath, '/openai/v1/models');
    });
  });
}
