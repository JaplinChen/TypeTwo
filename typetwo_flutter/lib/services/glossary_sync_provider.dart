import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/app_config.dart';
import 'glossary_remote_service.dart';

abstract class GlossarySyncProvider {
  Future<AppConfig> sync(AppConfig config);
}

class TypeTwoServerSyncProvider implements GlossarySyncProvider {
  const TypeTwoServerSyncProvider({GlossaryRemoteService? remote})
      : _remote = remote;

  final GlossaryRemoteService? _remote;

  @override
  Future<AppConfig> sync(AppConfig config) async {
    final sync = config.glossarySync;
    final bundle = await (_remote ?? GlossaryRemoteService()).fetchApproved(
      baseUrl: sync.url,
      token: sync.token,
    );
    return config.copyWith(
      glossary: bundle.glossary,
      langGlossary: bundle.langGlossary,
      glossaryLastSyncedAt: bundle.syncedAt.toUtc().toIso8601String(),
      glossaryRemoteIds: bundle.remoteIds,
    );
  }
}

class LocalFolderSyncProvider implements GlossarySyncProvider {
  const LocalFolderSyncProvider();

  static const snapshotFileName = 'glossary.snapshot.json';

  @override
  Future<AppConfig> sync(AppConfig config) async {
    final folderPath = config.glossarySync.localPath.trim();
    if (folderPath.isEmpty) {
      throw const GlossaryLocalSyncException('尚未設定同步資料夾');
    }

    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final file =
        File('${folder.path}${Platform.pathSeparator}$snapshotFileName');
    final now = DateTime.now().toUtc().toIso8601String();
    if (!await file.exists()) {
      final initialized = config.copyWith(glossaryLastSyncedAt: now);
      await _writeSnapshot(file, initialized);
      return initialized;
    }

    final remote = await readSnapshotFile(file);
    final merged = config.copyWith(
      glossary: {
        ...remote.glossary,
        ...config.glossary,
      },
      langGlossary:
          _mergeLangGlossary(remote.langGlossary, config.langGlossary),
      glossaryLastSyncedAt: now,
    );
    await _writeSnapshot(file, merged);
    return merged;
  }

  static Map<String, Map<String, String>> _mergeLangGlossary(
    Map<String, Map<String, String>> remote,
    Map<String, Map<String, String>> local,
  ) {
    final merged = <String, Map<String, String>>{};
    for (final entry in remote.entries) {
      merged[entry.key] = Map<String, String>.from(entry.value);
    }
    for (final entry in local.entries) {
      merged[entry.key] = {
        ...(merged[entry.key] ?? const <String, String>{}),
        ...entry.value,
      };
    }
    return merged;
  }

  static Future<AppConfig> readSnapshotFile(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const GlossaryLocalSyncException('同步檔案格式錯誤');
      }
      return AppConfig.fromJson(decoded);
    } on GlossaryLocalSyncException {
      rethrow;
    } catch (e) {
      throw GlossaryLocalSyncException('讀取同步檔案失敗：$e');
    }
  }

  static Future<void> _writeSnapshot(File file, AppConfig config) async {
    await file.writeAsString(encodeSnapshot(config));
  }

  static String encodeSnapshot(AppConfig config) {
    final snapshot = {
      'schemaVersion': 1,
      'updatedAt': config.glossaryLastSyncedAt,
      'glossary': config.glossary,
      if (config.langGlossary.isNotEmpty) 'langGlossary': config.langGlossary,
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(snapshot);
  }
}

class WebDavSyncProvider implements GlossarySyncProvider {
  WebDavSyncProvider({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<AppConfig> sync(AppConfig config) async {
    final sync = config.glossarySync;
    final baseUrl = sync.webDavUrl.trim();
    if (baseUrl.isEmpty) {
      throw const GlossaryWebDavSyncException('尚未設定 WebDAV URL');
    }
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      throw const GlossaryWebDavSyncException(
        'WebDAV URL 格式錯誤：請輸入 http:// 或 https:// 開頭的網址',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final snapshotUri = _snapshotUri(baseUrl);
    final headers = headersFor(sync);
    final remoteResponse = await _client.get(snapshotUri, headers: headers);

    if (remoteResponse.statusCode == 404) {
      final initialized = config.copyWith(glossaryLastSyncedAt: now);
      await _putSnapshot(snapshotUri, headers, initialized);
      return initialized;
    }

    if (remoteResponse.statusCode < 200 || remoteResponse.statusCode >= 300) {
      throw GlossaryWebDavSyncException(
        'WebDAV 讀取失敗：HTTP ${remoteResponse.statusCode}',
      );
    }

    final remote = _decodeSnapshot(remoteResponse.body);
    final merged = config.copyWith(
      glossary: {
        ...remote.glossary,
        ...config.glossary,
      },
      langGlossary: LocalFolderSyncProvider._mergeLangGlossary(
        remote.langGlossary,
        config.langGlossary,
      ),
      glossaryLastSyncedAt: now,
    );
    await _putSnapshot(snapshotUri, headers, merged);
    return merged;
  }

  static Uri _snapshotUri(String baseUrl) {
    final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse('$normalized${LocalFolderSyncProvider.snapshotFileName}');
  }

  static Map<String, String> headersFor(GlossarySyncConfig sync) {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };
    final user = sync.webDavUser.trim();
    if (user.isNotEmpty && sync.webDavPassword.isNotEmpty) {
      final token = base64Encode(utf8.encode('$user:${sync.webDavPassword}'));
      headers[HttpHeaders.authorizationHeader] = 'Basic $token';
    }
    return headers;
  }

  static AppConfig _decodeSnapshot(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const GlossaryWebDavSyncException('WebDAV 同步檔案格式錯誤');
      }
      return AppConfig.fromJson(decoded);
    } on GlossaryWebDavSyncException {
      rethrow;
    } catch (e) {
      throw GlossaryWebDavSyncException('讀取 WebDAV 同步檔案失敗：$e');
    }
  }

  Future<void> _putSnapshot(
    Uri uri,
    Map<String, String> headers,
    AppConfig config,
  ) async {
    final response = await _client.put(
      uri,
      headers: headers,
      body: LocalFolderSyncProvider.encodeSnapshot(config),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GlossaryWebDavSyncException(
        'WebDAV 寫入失敗：HTTP ${response.statusCode}',
      );
    }
  }
}

class GlossaryLocalSyncException implements Exception {
  const GlossaryLocalSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GlossaryWebDavSyncException implements Exception {
  const GlossaryWebDavSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}
