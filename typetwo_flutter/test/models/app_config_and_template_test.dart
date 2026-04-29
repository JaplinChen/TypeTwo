import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/models/app_constants.dart';
import 'package:typetwo/services/translate_service.dart';

void main() {
  group('AppConfig', () {
    test('toJsonString 與 fromJsonString 可保留主要設定', () {
      final config = AppConfig.defaults().copyWith(
        provider: 'Azure OpenAI',
        model: 'ignored-by-azure',
        fallbackModels: ['gpt-4o-mini', 'gpt-4.1-mini'],
        endpoint:
            'https://example.openai.azure.com/openai/deployments/demo/chat/completions?api-version=2024-02-01',
        apiKey: 'secret',
        temperature: 0.3,
        sourceLang: '英文',
        targetLang: '繁體中文',
        template: '{source}\n\n{translation}',
        extraInstructions: ['保留專有名詞', '使用台灣用語'],
        glossary: {'API': '應用程式介面'},
        allowedProcesses: ['Teams.exe'],
        hotkeyModifiers: ['ctrl', 'shift'],
        hotkeyKey: 'k',
        thinkingMode: 'auto',
      );

      final decoded = AppConfig.fromJsonString(config.toJsonString());

      expect(decoded.provider, 'Azure OpenAI');
      expect(decoded.fallbackModels, ['gpt-4o-mini', 'gpt-4.1-mini']);
      expect(decoded.apiKey, 'secret');
      expect(decoded.temperature, 0.3);
      expect(decoded.template, '{source}\n\n{translation}');
      expect(decoded.extraInstructions, ['保留專有名詞', '使用台灣用語']);
      expect(decoded.glossary['API'], '應用程式介面');
      expect(decoded.allowedProcesses, ['Teams.exe']);
      expect(decoded.hotkeyModifiers, ['ctrl', 'shift']);
      expect(decoded.hotkeyKey, 'k');
      expect(decoded.thinkingMode, 'auto');
    });

    test('providerConfigs 可在序列化/反序列化後保留', () {
      final config = AppConfig.defaults().copyWith(
        providerConfigs: {
          'OpenAI': {
            'apiKey': 'sk-test',
            'endpoint': 'https://api.openai.com/v1/chat/completions',
            'model': 'gpt-4o',
            'fallbackModels': <String>['gpt-4o-mini'],
          },
          'Gemini': {
            'apiKey': 'AIza-test',
            'endpoint': '',
            'model': 'gemini-2.0-flash',
            'fallbackModels': <String>[],
          },
        },
      );

      final decoded = AppConfig.fromJsonString(config.toJsonString());

      expect(decoded.providerConfigs['OpenAI']?['apiKey'], 'sk-test');
      expect(decoded.providerConfigs['OpenAI']?['model'], 'gpt-4o');
      expect(decoded.providerConfigs['OpenAI']?['fallbackModels'],
          ['gpt-4o-mini']);
      expect(decoded.providerConfigs['Gemini']?['apiKey'], 'AIza-test');
    });

    test('缺少 providerConfigs 的舊格式 JSON 預設為空 Map', () {
      const json = '{"provider":"Ollama","model":"qwen3:14b",'
          '"fallbackModels":[],"endpoint":"http://localhost","apiKey":"",'
          '"temperature":0,"sourceLang":"繁體中文","targetLang":"越南文",'
          '"template":"{source}\\n{translation}","extraInstructions":[],'
          '"glossary":{},"restrictToAllowedProcesses":false,"allowedProcesses":[],'
          '"hotkeyModifiers":["ctrl","alt"],"hotkeyKey":"t"}';
      final decoded = AppConfig.fromJsonString(json);
      expect(decoded.providerConfigs, isEmpty);
    });
  });

  group('TranslateService template', () {
    test('translate 會把 provider 結果套進自訂 template', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        final response = {
          'message': {'content': 'Bonjour'}
        };
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(response));
        await request.response.close();
      });

      final config = AppConfig.defaults().copyWith(
        provider: 'Ollama',
        endpoint: 'http://127.0.0.1:${server.port}/api/chat',
        template: '[原文]\n{source}\n\n[譯文]\n{translation}',
      );

      final result = await TranslateService.translate('Hello', config);

      expect(result, '[原文]\nHello\n\n[譯文]\nBonjour');
    });

    test('主模型 429 時會自動改用備援模型', () async {
      final attemptedModels = <String>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        final model = body['model'].toString();
        attemptedModels.add(model);

        if (model == 'gemini-2.5-flash') {
          request.response
            ..statusCode = 429
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': 'quota exceeded'}));
        } else {
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'choices': [
                {
                  'message': {'content': '備援成功'}
                }
              ]
            }));
        }
        await request.response.close();
      });

      final result = await TranslateService.translate(
        'Hello',
        AppConfig.defaults().copyWith(
          provider: 'OpenAI',
          endpoint: 'http://127.0.0.1:${server.port}/v1/chat/completions',
          apiKey: 'secret',
          model: 'gemini-2.5-flash',
          fallbackModels: ['gemini-2.0-flash'],
          template: '{translation}',
        ),
      );

      expect(result, '備援成功');
      expect(attemptedModels, [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
      ]);
    });

    test('自動雙目標遇到越南文會固定翻譯成繁體中文', () async {
      late Map<String, dynamic> body;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'choices': [
              {
                'message': {'content': '越南盾'}
              }
            ]
          }));
        await request.response.close();
      });

      final result = await TranslateService.translate(
        'Tiền đồng',
        AppConfig.defaults().copyWith(
          provider: 'OpenAI',
          endpoint: 'http://127.0.0.1:${server.port}/v1/chat/completions',
          apiKey: 'secret',
          sourceLang: kAutoDetectLang,
          targetLang: '繁體中文',
          secondTargetLang: '越南文',
          template: '{translation}',
        ),
      );

      final messages = body['messages'] as List<dynamic>;
      final system = (messages.first as Map<String, dynamic>)['content'];

      expect(result, '越南盾');
      expect(system, contains('translate to 繁體中文'));
      expect(system, isNot(contains('translate it to 越南文')));
    });

    test('詞彙表可依目標語言反向套用', () async {
      late Map<String, dynamic> body;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'choices': [
              {
                'message': {'content': 'kinh doanh'}
              }
            ]
          }));
        await request.response.close();
      });

      final result = await TranslateService.translate(
        'kinh doanh',
        AppConfig.defaults().copyWith(
          provider: 'OpenAI',
          endpoint: 'http://127.0.0.1:${server.port}/v1/chat/completions',
          apiKey: 'secret',
          sourceLang: kAutoDetectLang,
          targetLang: '繁體中文',
          secondTargetLang: '越南文',
          template: '{translation}',
          glossary: {'業務': 'Kinh doanh'},
        ),
      );

      final messages = body['messages'] as List<dynamic>;
      final system = (messages.first as Map<String, dynamic>)['content'];

      expect(result, '業務');
      expect(system, contains('translate to 繁體中文'));
      expect(system, contains('Kinh doanh → 業務'));
    });
  });
}
