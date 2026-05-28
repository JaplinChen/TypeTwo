import 'dart:io';

import '../models/app_config.dart';
import 'config_service.dart';
import 'glossary_sync_provider.dart';

class GlossarySyncBackupService {
  const GlossarySyncBackupService({this.keepLatest = 10});

  final int keepLatest;

  Future<File> backup(AppConfig config) async {
    final dir = await _backupDir();
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-');
    var file = File('${dir.path}${Platform.pathSeparator}glossary-$stamp.json');
    var suffix = 1;
    while (await file.exists()) {
      file = File(
        '${dir.path}${Platform.pathSeparator}glossary-$stamp-$suffix.json',
      );
      suffix += 1;
    }
    await file.writeAsString(LocalFolderSyncProvider.encodeSnapshot(config));
    await _prune(dir);
    return file;
  }

  Future<List<GlossarySyncBackupInfo>> listBackups() async {
    final dir = await _backupDir();
    final files = await dir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    final backups = <GlossarySyncBackupInfo>[];
    for (final file in files) {
      try {
        final snapshot = await LocalFolderSyncProvider.readSnapshotFile(file);
        backups.add(GlossarySyncBackupInfo(
          path: file.path,
          createdAt: file.uri.pathSegments.last
              .replaceFirst('glossary-', '')
              .replaceFirst('.json', ''),
          termCount: snapshot.glossary.length +
              snapshot.langGlossary.values
                  .fold<int>(0, (sum, terms) => sum + terms.length),
        ));
      } catch (_) {}
    }
    return backups;
  }

  Future<AppConfig> restore(AppConfig current, String path) async {
    final snapshot = await LocalFolderSyncProvider.readSnapshotFile(File(path));
    return current.copyWith(
      glossary: snapshot.glossary,
      langGlossary: snapshot.langGlossary,
    );
  }

  Future<Directory> _backupDir() async {
    final configDir = await ConfigService.configDir();
    final dir = Directory(
      '${configDir.path}${Platform.pathSeparator}glossary_sync_backups',
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> _prune(Directory dir) async {
    if (keepLatest <= 0) return;
    final files = await dir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    for (final file in files.skip(keepLatest)) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}

class GlossarySyncBackupInfo {
  const GlossarySyncBackupInfo({
    required this.path,
    required this.createdAt,
    required this.termCount,
  });

  final String path;
  final String createdAt;
  final int termCount;
}
