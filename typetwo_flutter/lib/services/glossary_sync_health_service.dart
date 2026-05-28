import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/app_config.dart';
import 'glossary_remote_client.dart';
import 'glossary_sync_provider.dart';

class GlossarySyncHealthService {
  GlossarySyncHealthService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<GlossarySyncHealthResult> check(AppConfig config) async {
    final sync = config.glossarySync;
    if (sync.isTypeTwoServer) return _checkTypeTwoServer(sync);
    if (sync.isWebDav) return _checkWebDav(sync);
    if (sync.isCloudFolder) return _checkLocalFolder(sync);
    return const GlossarySyncHealthResult.failure('未知的同步空間');
  }

  Future<GlossarySyncHealthResult> _checkTypeTwoServer(
    GlossarySyncConfig sync,
  ) async {
    final baseUrl = GlossaryRemoteClient.normalizeBaseUrl(sync.url);
    if (baseUrl.isEmpty) {
      return const GlossarySyncHealthResult.failure('尚未設定同步 URL');
    }
    try {
      final response = await _client.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return GlossarySyncHealthResult.failure(
          'TypeTwo Server 無法連線：HTTP ${response.statusCode}',
        );
      }
      return const GlossarySyncHealthResult.success('TypeTwo Server 可連線');
    } catch (e) {
      return GlossarySyncHealthResult.failure('TypeTwo Server 連線失敗：$e');
    }
  }

  Future<GlossarySyncHealthResult> _checkLocalFolder(
    GlossarySyncConfig sync,
  ) async {
    final path = sync.localPath.trim();
    if (path.isEmpty) {
      return const GlossarySyncHealthResult.failure('尚未設定同步資料夾');
    }
    try {
      final folder = Directory(path);
      if (!await folder.exists()) await folder.create(recursive: true);
      final probe = File(
        '${folder.path}${Platform.pathSeparator}.typetwo-sync-test',
      );
      await probe.writeAsString(DateTime.now().toUtc().toIso8601String());
      await probe.delete();
      return const GlossarySyncHealthResult.success('同步資料夾可寫入');
    } catch (e) {
      return GlossarySyncHealthResult.failure('同步資料夾不可寫入：$e');
    }
  }

  Future<GlossarySyncHealthResult> _checkWebDav(
    GlossarySyncConfig sync,
  ) async {
    final url = sync.webDavUrl.trim();
    if (url.isEmpty) {
      return const GlossarySyncHealthResult.failure('尚未設定 WebDAV URL');
    }
    try {
      final request = http.Request('PROPFIND', Uri.parse(url));
      request.headers.addAll(WebDavSyncProvider.headersFor(sync));
      request.headers[HttpHeaders.contentTypeHeader] = 'application/xml';
      request.headers['Depth'] = '0';
      request.body = _webDavPropfindBody;
      final response = await http.Response.fromStream(
        await _client.send(request),
      );
      if ({200, 207}.contains(response.statusCode)) {
        return const GlossarySyncHealthResult.success('WebDAV 資料夾可連線');
      }
      return GlossarySyncHealthResult.failure(
        'WebDAV 資料夾無法連線：HTTP ${response.statusCode}',
      );
    } catch (e) {
      return GlossarySyncHealthResult.failure('WebDAV 連線失敗：$e');
    }
  }
}

class GlossarySyncHealthResult {
  const GlossarySyncHealthResult({
    required this.ok,
    required this.message,
  });

  const GlossarySyncHealthResult.success(String message)
      : this(ok: true, message: message);

  const GlossarySyncHealthResult.failure(String message)
      : this(ok: false, message: message);

  final bool ok;
  final String message;
}

const _webDavPropfindBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:resourcetype/>
  </d:prop>
</d:propfind>
''';
