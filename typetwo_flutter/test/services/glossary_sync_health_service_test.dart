import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/services/glossary_sync_health_service.dart';

void main() {
  test('TypeTwo Server 測試連線會呼叫 /health', () async {
    Uri? requestedUri;
    final service = GlossarySyncHealthService(
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response('{"status":"ok"}', 200);
      }),
    );

    final result = await service.check(
      AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com/',
      ),
    );

    expect(result.ok, isTrue);
    expect(requestedUri.toString(), 'https://glossary.example.com/health');
  });

  test('TypeTwo Server 測試連線會顯示 health 詳細資訊', () async {
    final service = GlossarySyncHealthService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'ok': true,
            'db': 'ok',
            'version': '0.1.0',
            'environment': 'production',
            'migrationRevision': '202605260001',
          }),
          200,
        );
      }),
    );

    final result = await service.check(
      AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
      ),
    );

    expect(result.ok, isTrue);
    expect(result.message, contains('version 0.1.0'));
    expect(result.message, contains('production'));
    expect(result.message, contains('migration 202605260001'));
  });

  test('TypeTwo Server 測試連線會辨識 DB 異常', () async {
    final service = GlossarySyncHealthService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({'ok': false, 'db': 'connection failed'}),
          200,
        );
      }),
    );

    final result = await service.check(
      AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
      ),
    );

    expect(result.ok, isFalse);
    expect(result.message, contains('DB 狀態：connection failed'));
  });

  test('TypeTwo Server 測試連線會辨識無效 JSON', () async {
    final service = GlossarySyncHealthService(
      client: MockClient((_) async => http.Response('{bad json', 200)),
    );

    final result = await service.check(
      AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
      ),
    );

    expect(result.ok, isFalse);
    expect(result.message, contains('/health 回應格式錯誤'));
  });

  test('本機雲端資料夾測試連線會驗證資料夾可寫入', () async {
    final tempDir = await Directory.systemTemp.createTemp('typetwo_health_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    final result = await GlossarySyncHealthService().check(
      AppConfig.defaults().copyWith(
        glossarySyncTarget: GlossarySyncTargets.oneDrive,
        glossarySyncLocalPath: tempDir.path,
      ),
    );

    expect(result.ok, isTrue);
    expect(
      await File(
        '${tempDir.path}${Platform.pathSeparator}.typetwo-sync-test',
      ).exists(),
      isFalse,
    );
  });

  test('WebDAV 測試連線會用 PROPFIND 與 Basic Auth', () async {
    http.BaseRequest? capturedRequest;
    final service = GlossarySyncHealthService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('<d:multistatus />', 207);
      }),
    );

    final result = await service.check(
      AppConfig.defaults().copyWith(
        glossarySyncTarget: GlossarySyncTargets.webDav,
        glossarySyncWebDavUrl:
            'https://cloud.example.com/remote.php/dav/files/me/TypeTwo',
        glossarySyncWebDavUser: 'me',
        glossarySyncWebDavPassword: 'app-password',
      ),
    );

    expect(result.ok, isTrue);
    expect(capturedRequest?.method, 'PROPFIND');
    expect(
      capturedRequest?.headers[HttpHeaders.authorizationHeader],
      'Basic ${base64Encode(utf8.encode('me:app-password'))}',
    );
    expect(capturedRequest?.headers['Depth'], '0');
  });

  test('WebDAV URL 無 http/https scheme 時回傳失敗', () async {
    final result = await GlossarySyncHealthService().check(
      AppConfig.defaults().copyWith(
        glossarySyncTarget: GlossarySyncTargets.webDav,
        glossarySyncWebDavUrl: r'\\192.168.1.100\Share\TypeTwo',
      ),
    );

    expect(result.ok, isFalse);
    expect(result.message, contains('http'));
  });
}
