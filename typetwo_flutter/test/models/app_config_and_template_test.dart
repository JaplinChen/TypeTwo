import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/services/translate_service.dart';

void main() {
  group('AppConfig', () {
    test('toJsonString 與 fromJsonString 可保留主要設定', () {
      final config = AppConfig.defaults().copyWith(
        provider: 'Azure OpenAI',
        model: 'ignored-by-azure',
        endpoint:
            'https://example.openai.azure.com/openai/deployments/demo/chat/completions?api-version=2024-02-01',
        apiKey: 'secret',
        temperature: 0.3,
        sourceLang: '英文',
        targetLang: '繁體中文',
        sourceLabel: 'English',
        targetLabel: '中文',
        template: '{source_label}:\n{source}\n\n{target_label}:\n{translation}',
        extraInstructions: ['保留專有名詞', '使用台灣用語'],
        glossary: {'API': '應用程式介面'},
        allowedProcesses: ['Teams.exe'],
        hotkeyModifiers: ['ctrl', 'shift'],
        hotkeyKey: 'k',
        thinkingMode: 'auto',
      );

      final decoded = AppConfig.fromJsonString(config.toJsonString());

      expect(decoded.provider, 'Azure OpenAI');
      expect(decoded.apiKey, 'secret');
      expect(decoded.temperature, 0.3);
      expect(decoded.template,
          '{source_label}:\n{source}\n\n{target_label}:\n{translation}');
      expect(decoded.extraInstructions, ['保留專有名詞', '使用台灣用語']);
      expect(decoded.glossary['API'], '應用程式介面');
      expect(decoded.allowedProcesses, ['Teams.exe']);
      expect(decoded.hotkeyModifiers, ['ctrl', 'shift']);
      expect(decoded.hotkeyKey, 'k');
      expect(decoded.thinkingMode, 'auto');
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
        sourceLabel: '原文',
        targetLabel: '譯文',
        template:
            '[{source_label}]\n{source}\n\n[{target_label}]\n{translation}',
      );

      final result = await TranslateService.translate('Hello', config);

      expect(result, '[原文]\nHello\n\n[譯文]\nBonjour');
    });
  });
}
