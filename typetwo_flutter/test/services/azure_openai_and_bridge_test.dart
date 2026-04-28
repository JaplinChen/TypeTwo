import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/services/provider_service.dart';
import 'package:typetwo/services/translate_service.dart';

void main() {
  group('Azure OpenAI', () {
    test('TranslateService 會送出 api-key，且不包含 model', () async {
      late HttpHeaders headers;
      late Map<String, dynamic> body;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        headers = request.headers;
        body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'choices': [
              {
                'message': {'content': 'azure-translation'}
              }
            ]
          }));
        await request.response.close();
      });

      final result = await TranslateService.translate(
        'hello',
        AppConfig.defaults().copyWith(
          provider: 'Azure OpenAI',
          endpoint: 'http://127.0.0.1:${server.port}/openai/deployments/demo/'
              'chat/completions?api-version=2024-02-01',
          apiKey: 'azure-key',
          template: '{translation}',
        ),
      );

      expect(result, 'azure-translation');
      expect(headers.value('api-key'), 'azure-key');
      expect(headers.value('authorization'), isNull);
      expect(body.containsKey('model'), isFalse);
      expect(body['messages'], isA<List<dynamic>>());
    });

    test('ProviderService.checkConnection 會用 POST 驗證 Azure endpoint', () async {
      late String method;
      late HttpHeaders headers;
      late Map<String, dynamic> body;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        method = request.method;
        headers = request.headers;
        body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        request.response.statusCode = 200;
        await request.response.close();
      });

      final (ok, message) = await ProviderService.checkConnection(
        'Azure OpenAI',
        'http://127.0.0.1:${server.port}/openai/deployments/demo/'
            'chat/completions?api-version=2024-02-01',
        'azure-key',
        'gpt-4o',
      );

      expect(ok, isTrue);
      expect(message, isEmpty);
      expect(method, 'POST');
      expect(headers.value('api-key'), 'azure-key');
      expect(headers.value('authorization'), isNull);
      expect(body.containsKey('model'), isFalse);
      expect(body['messages'], isA<List<dynamic>>());
    });
  });

  group('LM Studio', () {
    test('TranslateService 會用 OpenAI-compatible chat completions', () async {
      late HttpHeaders headers;
      late Map<String, dynamic> body;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        headers = request.headers;
        body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'choices': [
              {
                'message': {'content': 'lm-studio-translation'}
              }
            ]
          }));
        await request.response.close();
      });

      final result = await TranslateService.translate(
        'hello',
        AppConfig.defaults().copyWith(
          provider: 'LM Studio',
          endpoint: 'http://127.0.0.1:${server.port}/v1/chat/completions',
          model: 'qwen3-8b',
          template: '{translation}',
        ),
      );

      expect(result, 'lm-studio-translation');
      expect(headers.value('authorization'), isNull);
      expect(body['model'], 'qwen3-8b');
      expect(body['messages'], isA<List<dynamic>>());
    });

    test('ProviderService 會保留 path prefix 取得模型與驗證模型存在', () async {
      final requests = <String>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        requests.add(request.uri.path);
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'data': [
              {'id': 'qwen3-8b'},
              {'id': 'gemma-3-12b-it'},
            ]
          }));
        await request.response.close();
      });

      final endpoint = 'http://127.0.0.1:${server.port}/proxy/lmstudio/'
          'v1/chat/completions';
      final models = await ProviderService.fetchModels(
        'LM Studio',
        endpoint,
        '',
      );
      final (ok, message) = await ProviderService.checkConnection(
        'LM Studio',
        endpoint,
        '',
        'qwen3-8b',
      );

      expect(models.map((m) => m.$1), ['gemma-3-12b-it', 'qwen3-8b']);
      expect(ok, isTrue);
      expect(message, isEmpty);
      expect(
        requests,
        everyElement('/proxy/lmstudio/v1/models'),
      );
    });
  });

}
