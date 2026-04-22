import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/providers/bridge_provider.dart';
import 'package:typetwo/services/bridge_service.dart';
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

  group('Bridge lifecycle', () {
    test('BridgeProvider 建構時不會立刻觸發狀態檢查，需顯式 initialize', () async {
      var callbackCount = 0;
      final provider = BridgeProvider(
        onBridgeStatusChange: (_) async {
          callbackCount++;
        },
      );
      addTearDown(provider.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(callbackCount, 0);

      await provider.initialize();
      expect(callbackCount, greaterThanOrEqualTo(1));
    });

    test('BridgeService 不會停止外部既有程序', () {
      final service = BridgeService(onStatusChange: (_) {});

      expect(
        service.stop,
        throwsA(isA<BridgeOwnershipException>()),
      );
    });
  });
}
