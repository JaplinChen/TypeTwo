import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/models/app_constants.dart';
import 'package:typetwo/services/translate_service.dart';

void main() {
  group('AppConfig', () {
    test('defaults() 有正確的預設值', () {
      final cfg = AppConfig.defaults();
      expect(cfg.sourceLang, kAutoDetectLang);
      expect(cfg.targetLang, '繁體中文');
      expect(cfg.secondTargetLang, '越南文');
      expect(cfg.restrictToAllowedProcesses, false);
      expect(cfg.extraInstructions, isEmpty);
      expect(cfg.allowedProcesses, isEmpty);
      expect(cfg.schemaVersion, 1);
    });

    test('fromJson 在 restrictToAllowedProcesses 缺失時預設 false', () {
      const json = '{"provider":"Ollama","model":"qwen3:14b",'
          '"fallbackModels":[],"endpoint":"http://localhost","apiKey":"",'
          '"temperature":0,"sourceLang":"auto","targetLang":"繁體中文",'
          '"template":"{source}\\n{translation}","extraInstructions":[],'
          '"glossary":{},"allowedProcesses":["Teams.exe"],'
          '"hotkeyModifiers":["ctrl","alt"],"hotkeyKey":"t"}';
      final cfg = AppConfig.fromJsonString(json);
      expect(cfg.restrictToAllowedProcesses, false);
    });

    test('fromJson 正確讀取 schemaVersion', () {
      const json = '{"provider":"Ollama","model":"qwen3:14b",'
          '"fallbackModels":[],"endpoint":"http://localhost","apiKey":"",'
          '"temperature":0,"sourceLang":"auto","targetLang":"繁體中文",'
          '"template":"{source}\\n{translation}","extraInstructions":[],'
          '"glossary":{},"restrictToAllowedProcesses":false,"allowedProcesses":[],'
          '"hotkeyModifiers":["ctrl","alt"],"hotkeyKey":"t","schemaVersion":1}';
      expect(AppConfig.fromJsonString(json).schemaVersion, 1);

      const jsonNoVersion = '{"provider":"Ollama","model":"qwen3:14b",'
          '"fallbackModels":[],"endpoint":"http://localhost","apiKey":"",'
          '"temperature":0,"sourceLang":"auto","targetLang":"繁體中文",'
          '"template":"{source}\\n{translation}","extraInstructions":[],'
          '"glossary":{},"restrictToAllowedProcesses":false,"allowedProcesses":[],'
          '"hotkeyModifiers":["ctrl","alt"],"hotkeyKey":"t"}';
      expect(AppConfig.fromJsonString(jsonNoVersion).schemaVersion, 0);
    });

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
        glossarySyncUrl: 'https://glossary.example.com',
        glossarySyncToken: 'token',
        glossarySyncRole: 'editor',
        glossarySyncTarget: GlossarySyncTargets.localFolder,
        glossarySyncLocalPath: 'C:\\Sync\\TypeTwo',
        glossarySyncWebDavUrl:
            'https://cloud.example.com/remote.php/dav/files/me/TypeTwo',
        glossarySyncWebDavUser: 'me',
        glossarySyncWebDavPassword: 'app-password',
        glossaryLastSyncedAt: '2026-05-22T10:00:00Z',
        glossaryPendingChanges: [
          {
            'op': 'upsert',
            'contextKey': 'global',
            'sourceText': '離線詞',
            'targetText': 'Offline term',
          }
        ],
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
      expect(decoded.glossarySyncUrl, 'https://glossary.example.com');
      expect(decoded.glossarySyncToken, 'token');
      expect(decoded.glossarySyncRole, 'editor');
      expect(decoded.glossarySyncTarget, GlossarySyncTargets.localFolder);
      expect(decoded.glossarySyncLocalPath, 'C:\\Sync\\TypeTwo');
      expect(
        decoded.glossarySyncWebDavUrl,
        'https://cloud.example.com/remote.php/dav/files/me/TypeTwo',
      );
      expect(decoded.glossarySyncWebDavUser, 'me');
      expect(decoded.glossarySyncWebDavPassword, 'app-password');
      expect(decoded.glossaryLastSyncedAt, '2026-05-22T10:00:00Z');
      expect(decoded.glossaryPendingChanges.single['sourceText'], '離線詞');
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

    test('glossarySync getter 提供詞彙同步子設定且不改變 JSON 格式', () {
      final config = AppConfig.defaults().copyWith(
        glossarySyncUrl: ' https://glossary.example.com ',
        glossarySyncToken: ' token ',
        glossarySyncEmail: 'editor@example.com',
        glossarySyncRole: 'editor',
        glossarySyncTarget: GlossarySyncTargets.typeTwoServer,
        glossaryLastSyncedAt: '2026-05-22T10:00:00Z',
        glossaryRemoteIds: {'global\n申請': 'term-1'},
        glossaryPendingChanges: [
          {'op': 'delete', 'contextKey': 'global', 'sourceText': '舊詞'},
        ],
      );

      final sync = config.glossarySync;
      final json = config.toJson();

      expect(sync.url, ' https://glossary.example.com ');
      expect(sync.token, ' token ');
      expect(sync.email, 'editor@example.com');
      expect(sync.role, 'editor');
      expect(sync.target, GlossarySyncTargets.typeTwoServer);
      expect(sync.localPath, '');
      expect(sync.lastSyncedAt, '2026-05-22T10:00:00Z');
      expect(sync.remoteIds, {'global\n申請': 'term-1'});
      expect(sync.pendingChanges.single['op'], 'delete');
      expect(sync.isEnabled, isTrue);
      expect(sync.canReview, isTrue);
      expect(sync.canManageUsers, isFalse);
      expect(json.containsKey('glossarySync'), isFalse);
      expect(json['glossarySyncUrl'], ' https://glossary.example.com ');
      expect(json.containsKey('glossarySyncTarget'), isFalse);
    });

    test('本機資料夾同步設定只需要資料夾路徑即可啟用', () {
      final config = AppConfig.defaults().copyWith(
        glossarySyncTarget: GlossarySyncTargets.googleDrive,
        glossarySyncLocalPath: 'D:\\Cloud\\TypeTwo',
      );

      final sync = config.glossarySync;
      final json = config.toJson();

      expect(sync.isEnabled, isTrue);
      expect(sync.isCloudFolder, isTrue);
      expect(sync.isLocalFolder, isFalse);
      expect(sync.isTypeTwoServer, isFalse);
      expect(json['glossarySyncTarget'], GlossarySyncTargets.googleDrive);
      expect(json['glossarySyncLocalPath'], 'D:\\Cloud\\TypeTwo');
    });

    test('WebDAV 同步設定只需要 URL 即可啟用', () {
      final config = AppConfig.defaults().copyWith(
        glossarySyncTarget: GlossarySyncTargets.webDav,
        glossarySyncWebDavUrl:
            'https://cloud.example.com/remote.php/dav/files/me/TypeTwo',
        glossarySyncWebDavUser: 'me',
        glossarySyncWebDavPassword: 'app-password',
      );

      final sync = config.glossarySync;
      final json = config.toJson();

      expect(sync.isEnabled, isTrue);
      expect(sync.isWebDav, isTrue);
      expect(sync.webDavUser, 'me');
      expect(json['glossarySyncTarget'], GlossarySyncTargets.webDav);
      expect(
        json['glossarySyncWebDavUrl'],
        'https://cloud.example.com/remote.php/dav/files/me/TypeTwo',
      );
      expect(json['glossarySyncWebDavUser'], 'me');
      expect(json['glossarySyncWebDavPassword'], 'app-password');
    });

    test('providerRuntime getter 提供引擎子設定且不改變 JSON 格式', () {
      final config = AppConfig.defaults().copyWith(
        provider: 'OpenAI',
        model: ' gpt-4o ',
        fallbackModels: ['gpt-4o-mini', 'gpt-4o-mini', '  ', 'gpt-4.1-mini'],
        endpoint: 'https://api.openai.com/v1/chat/completions',
        apiKey: 'sk-test',
        temperature: 3.5,
        thinkingMode: 'auto',
        providerOrder: ['OpenAI', 'Ollama', 'Gemini'],
        providerConfigs: {
          'OpenAI': {'model': 'gpt-4o'},
        },
      );

      final runtime = config.providerRuntime;
      final json = config.toJson();

      expect(runtime.provider, 'OpenAI');
      expect(runtime.model, ' gpt-4o ');
      expect(runtime.endpoint, 'https://api.openai.com/v1/chat/completions');
      expect(runtime.apiKey, 'sk-test');
      expect(runtime.thinkingMode, 'auto');
      expect(runtime.providerOrder, ['OpenAI', 'Ollama', 'Gemini']);
      expect(runtime.providerConfigs['OpenAI']?['model'], 'gpt-4o');
      expect(runtime.clampedTemperature, 2.0);
      expect(runtime.geminiThinkingBudget, -1);
      expect(runtime.modelAttempts, [
        'gpt-4o',
        'gpt-4o-mini',
        'gpt-4.1-mini',
      ]);
      expect(json.containsKey('providerRuntime'), isFalse);
      expect(json['provider'], 'OpenAI');
    });

    test('providerRuntime 會將 Gemini thinking mode 轉為 budget', () {
      expect(
        AppConfig.defaults()
            .copyWith(thinkingMode: 'quick')
            .providerRuntime
            .geminiThinkingBudget,
        0,
      );
      expect(
        AppConfig.defaults()
            .copyWith(thinkingMode: 'auto')
            .providerRuntime
            .geminiThinkingBudget,
        -1,
      );
      expect(
        AppConfig.defaults()
            .copyWith(thinkingMode: 'thinking')
            .providerRuntime
            .geminiThinkingBudget,
        8192,
      );
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

    test('越南文 prompt 會要求保留 đầy đủ dấu 且後處理不移除聲調', () async {
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
                'message': {
                  'content':
                      'Máy tính MIS602 này, ban đầu đã gỡ Kaspersky bằng cách nào?'
                }
              }
            ]
          }));
        await request.response.close();
      });

      final result = await TranslateService.translate(
        'MIS602 這台電腦，當初是如何移除 Kaspersky 的？',
        AppConfig.defaults().copyWith(
          provider: 'OpenAI',
          endpoint: 'http://127.0.0.1:${server.port}/v1/chat/completions',
          apiKey: 'secret',
          sourceLang: '繁體中文',
          targetLang: '越南文',
          secondTargetLang: null,
          template: '{translation}',
        ),
      );

      final messages = body['messages'] as List<dynamic>;
      final system = (messages.first as Map<String, dynamic>)['content'];

      expect(system, contains('đầy đủ dấu'));
      expect(system, contains('không dấu'));
      expect(result, contains('Máy tính'));
      expect(result, contains('đã gỡ'));
      expect(result, isNot(contains('May tinh')));
    });
  });
}
