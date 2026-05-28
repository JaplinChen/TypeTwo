import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/providers/config_provider.dart';
import 'package:typetwo/services/config_service.dart';
import 'package:typetwo/services/glossary_sync_backup_service.dart';
import 'package:typetwo/services/glossary_mutation_service.dart';
import 'package:typetwo/services/glossary_remote_service.dart';
import 'package:typetwo/services/glossary_sync_service.dart';
import 'package:typetwo/services/glossary_sync_provider.dart';

void main() {
  test('GlossarySyncService 會從遠端詞彙表更新 AppConfig', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    server.listen((request) async {
      expect(request.headers.value('authorization'), 'Bearer token-1');
      if (request.uri.path == '/glossary/terms') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode([
            {
              'id': 'term-1',
              'sourceText': '申請',
              'targetText': 'Nộp đơn',
              'contextKey': 'global',
            },
            {
              'id': 'term-2',
              'sourceText': '簽核',
              'targetText': 'Ký duyệt',
              'contextKey': '繁體中文-越南文',
            },
          ]));
        await request.response.close();
        return;
      }
      expect(request.uri.path, '/glossary');
      expect(request.uri.queryParameters['status'], 'approved');
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'glossary': {'申請': 'Nộp đơn'},
          'langGlossary': {
            '繁體中文-越南文': {'簽核': 'Ký duyệt'},
          },
          'syncedAt': '2026-05-22T10:00:00Z',
        }));
      await request.response.close();
    });

    final config = AppConfig.defaults().copyWith(
      glossary: {'舊詞': 'Old'},
      glossarySyncUrl: 'http://127.0.0.1:${server.port}/',
      glossarySyncToken: 'token-1',
    );

    final synced = await GlossarySyncService.sync(config);

    expect(synced.glossary, {'申請': 'Nộp đơn'});
    expect(synced.langGlossary, {
      '繁體中文-越南文': {'簽核': 'Ký duyệt'},
    });
    expect(synced.glossaryLastSyncedAt, '2026-05-22T10:00:00.000Z');
    expect(synced.glossaryRemoteIds, {
      'global\n申請': 'term-1',
      '繁體中文-越南文\n簽核': 'term-2',
    });
  });

  test('GlossarySyncService 可同步到本機雲端資料夾快照', () async {
    final tempDir = await Directory.systemTemp.createTemp('typetwo_sync_');
    addTearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    final config = AppConfig.defaults().copyWith(
      glossary: {'本機詞': 'Local term'},
      langGlossary: {
        '繁體中文-越南文': {'簽核': 'Ký duyệt'},
      },
      glossarySyncTarget: GlossarySyncTargets.oneDrive,
      glossarySyncLocalPath: tempDir.path,
    );

    final firstSync = await GlossarySyncService.sync(config);
    final snapshot = File(
      '${tempDir.path}${Platform.pathSeparator}'
      '${LocalFolderSyncProvider.snapshotFileName}',
    );

    expect(await snapshot.exists(), isTrue);
    expect(firstSync.glossaryLastSyncedAt, isNotNull);

    await snapshot.writeAsString(jsonEncode({
      'glossary': {'遠端詞': 'Remote term'},
      'langGlossary': {
        '繁體中文-越南文': {'遠端語言詞': 'Remote lang term'},
      },
    }));

    final secondSync = await GlossarySyncService.sync(config);

    expect(secondSync.glossary, {
      '遠端詞': 'Remote term',
      '本機詞': 'Local term',
    });
    expect(secondSync.langGlossary['繁體中文-越南文'], {
      '遠端語言詞': 'Remote lang term',
      '簽核': 'Ký duyệt',
    });
  });

  test('GlossarySyncService 可同步到 WebDAV 快照', () async {
    final requests = <String>[];
    var storedSnapshot = jsonEncode({
      'glossary': {'遠端詞': 'Remote term'},
      'langGlossary': {
        '繁體中文-越南文': {'遠端語言詞': 'Remote lang term'},
      },
    });
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    server.listen((request) async {
      requests.add('${request.method} ${request.uri.path}');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Basic ${base64Encode(utf8.encode('user:secret'))}',
      );
      if (request.method == 'GET') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(storedSnapshot);
      } else if (request.method == 'PUT') {
        storedSnapshot = await utf8.decoder.bind(request).join();
        request.response.statusCode = 204;
      } else {
        request.response.statusCode = 405;
      }
      await request.response.close();
    });

    final config = AppConfig.defaults().copyWith(
      glossary: {'本機詞': 'Local term'},
      langGlossary: {
        '繁體中文-越南文': {'簽核': 'Ký duyệt'},
      },
      glossarySyncTarget: GlossarySyncTargets.webDav,
      glossarySyncWebDavUrl: 'http://127.0.0.1:${server.port}/typetwo',
      glossarySyncWebDavUser: 'user',
      glossarySyncWebDavPassword: 'secret',
    );

    final synced = await GlossarySyncService.sync(config);
    final uploaded = jsonDecode(storedSnapshot) as Map<String, dynamic>;

    expect(requests, [
      'GET /typetwo/glossary.snapshot.json',
      'PUT /typetwo/glossary.snapshot.json',
    ]);
    expect(synced.glossary, {
      '遠端詞': 'Remote term',
      '本機詞': 'Local term',
    });
    expect(uploaded['glossary']['本機詞'], 'Local term');
    expect(uploaded['langGlossary']['繁體中文-越南文']['簽核'], 'Ký duyệt');
  });

  test('GlossaryRemoteService 支援登入與詞彙 CRUD', () async {
    final requests = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    server.listen((request) async {
      requests.add('${request.method} ${request.uri.path}');
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/auth/login') {
        request.response.write(jsonEncode({
          'accessToken': 'token-2',
          'tokenType': 'bearer',
          'role': 'editor',
        }));
      } else if (request.method == 'POST' && request.uri.path == '/glossary') {
        request.response.statusCode = 201;
        request.response.write(jsonEncode({
          'id': 'term-3',
          'sourceText': '表單',
          'targetText': 'Biểu mẫu',
          'contextKey': 'global',
        }));
      } else if (request.method == 'PUT' &&
          request.uri.path == '/glossary/term-3') {
        request.response.write(jsonEncode({
          'id': 'term-3',
          'sourceText': '表單',
          'targetText': 'Biểu đơn',
          'contextKey': 'global',
        }));
      } else if (request.method == 'DELETE' &&
          request.uri.path == '/glossary/term-3') {
        request.response.statusCode = 204;
      } else {
        request.response.statusCode = 404;
        request.response.write(jsonEncode({'error': 'not found'}));
      }
      await request.response.close();
    });

    final remote = GlossaryRemoteService();
    final baseUrl = 'http://127.0.0.1:${server.port}';
    final login = await remote.login(
      baseUrl: baseUrl,
      email: 'editor@example.com',
      password: 'secret',
    );
    final created = await remote.createTerm(
      baseUrl: baseUrl,
      token: login.accessToken,
      contextKey: 'global',
      sourceText: '表單',
      targetText: 'Biểu mẫu',
    );
    final updated = await remote.updateTerm(
      baseUrl: baseUrl,
      token: login.accessToken,
      id: created.id,
      contextKey: 'global',
      sourceText: '表單',
      targetText: 'Biểu đơn',
    );
    await remote.deleteTerm(
      baseUrl: baseUrl,
      token: login.accessToken,
      id: updated.id,
    );

    expect(login.role, 'editor');
    expect(created.id, 'term-3');
    expect(updated.targetText, 'Biểu đơn');
    expect(requests, [
      'POST /auth/login',
      'POST /glossary',
      'PUT /glossary/term-3',
      'DELETE /glossary/term-3',
    ]);
  });

  test('ConfigProvider 遠端失敗時保留本機變更並建立待同步佇列', () async {
    final tempDir = await Directory.systemTemp.createTemp('typetwo_pending_');
    ConfigService.debugConfigDir = tempDir;
    addTearDown(() async {
      ConfigService.debugConfigDir = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    final provider = ConfigProvider()
      ..update(AppConfig.defaults().copyWith(
        glossarySyncUrl: 'http://127.0.0.1:1',
        glossarySyncToken: 'token',
      ));

    await expectLater(
      provider.saveGlossaryEntry(
        contextKey: 'global',
        sourceText: '離線詞',
        targetText: 'Offline term',
      ),
      throwsA(isA<GlossaryPendingException>()),
    );

    expect(provider.config.glossary['離線詞'], 'Offline term');
    expect(provider.config.glossaryPendingChanges, hasLength(1));
    expect(provider.config.glossaryPendingChanges.single['op'], 'upsert');
  });

  test('ConfigProvider 同步前會建立本機備份', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('typetwo_sync_backup_');
    ConfigService.debugConfigDir = tempDir;
    addTearDown(() async {
      ConfigService.debugConfigDir = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    final syncDir = Directory('${tempDir.path}${Platform.pathSeparator}sync');
    final provider = ConfigProvider()
      ..update(AppConfig.defaults().copyWith(
        glossary: {'同步前': 'Before sync'},
        glossarySyncTarget: GlossarySyncTargets.localFolder,
        glossarySyncLocalPath: syncDir.path,
      ));

    await provider.syncGlossaryFromRemote();

    final backupDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}glossary_sync_backups',
    );
    final backups = await backupDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
    final backupJson =
        jsonDecode(await backups.single.readAsString()) as Map<String, dynamic>;

    expect(backups, hasLength(1));
    expect(backupJson['glossary']['同步前'], 'Before sync');
  });

  test('ConfigProvider 可還原詞彙同步備份', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('typetwo_restore_provider_');
    ConfigService.debugConfigDir = tempDir;
    addTearDown(() async {
      ConfigService.debugConfigDir = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    final provider = ConfigProvider()
      ..update(AppConfig.defaults().copyWith(
        glossary: {'備份詞': 'Backup term'},
      ));
    await const GlossarySyncBackupService().backup(provider.config);
    provider.update(AppConfig.defaults().copyWith(
      glossary: {'目前詞': 'Current term'},
    ));
    final backups = await provider.listGlossarySyncBackups();

    await provider.restoreGlossarySyncBackup(backups.single.path);

    expect(provider.config.glossary, {'備份詞': 'Backup term'});

    final backupsAfterRestore = await provider.listGlossarySyncBackups();
    expect(backupsAfterRestore, hasLength(2));
    final currentBackup = backupsAfterRestore.first.path == backups.single.path
        ? backupsAfterRestore.last
        : backupsAfterRestore.first;
    final currentSnapshot = await LocalFolderSyncProvider.readSnapshotFile(
        File(currentBackup.path));
    expect(currentSnapshot.glossary, {'目前詞': 'Current term'});
  });

  test('GlossaryMutationService 可依序送出待同步變更並清空佇列', () async {
    final remote = _FakeGlossaryRemoteService();
    final service = GlossaryMutationService(remote: remote);
    final config = AppConfig.defaults().copyWith(
      glossarySyncUrl: 'http://localhost',
      glossarySyncToken: 'token',
      glossaryRemoteIds: {'global\n舊詞': 'term-old'},
      glossaryPendingChanges: [
        {
          'op': 'upsert',
          'contextKey': 'global',
          'sourceText': '新詞',
          'targetText': 'New term',
        },
        {
          'op': 'delete',
          'contextKey': 'global',
          'sourceText': '舊詞',
        },
      ],
    );

    final updated = await service.flushPendingChanges(config);

    expect(remote.calls, [
      'create global 新詞 New term',
      'delete term-old',
    ]);
    expect(updated.glossaryPendingChanges, isEmpty);
    expect(updated.glossaryRemoteIds, {'global\n新詞': 'term-1'});
  });
}

class _FakeGlossaryRemoteService extends GlossaryRemoteService {
  _FakeGlossaryRemoteService();

  final List<String> calls = [];

  @override
  Future<GlossaryRemoteTerm> createTerm({
    required String baseUrl,
    required String token,
    required String contextKey,
    required String sourceText,
    required String targetText,
  }) async {
    calls.add('create $contextKey $sourceText $targetText');
    return GlossaryRemoteTerm(
      id: 'term-1',
      sourceText: sourceText,
      targetText: targetText,
      contextKey: contextKey,
      status: 'approved',
    );
  }

  @override
  Future<GlossaryRemoteTerm> updateTerm({
    required String baseUrl,
    required String token,
    required String id,
    required String contextKey,
    required String sourceText,
    required String targetText,
  }) async {
    calls.add('update $id $contextKey $sourceText $targetText');
    return GlossaryRemoteTerm(
      id: id,
      sourceText: sourceText,
      targetText: targetText,
      contextKey: contextKey,
      status: 'approved',
    );
  }

  @override
  Future<void> deleteTerm({
    required String baseUrl,
    required String token,
    required String id,
  }) async {
    calls.add('delete $id');
  }
}
