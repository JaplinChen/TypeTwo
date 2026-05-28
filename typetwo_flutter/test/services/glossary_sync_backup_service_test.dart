import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/services/config_service.dart';
import 'package:typetwo/services/glossary_sync_backup_service.dart';

void main() {
  test('GlossarySyncBackupService 會備份詞彙快照並保留最近檔案', () async {
    final tempDir = await Directory.systemTemp.createTemp('typetwo_backup_');
    ConfigService.debugConfigDir = tempDir;
    addTearDown(() async {
      ConfigService.debugConfigDir = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    final service = const GlossarySyncBackupService(keepLatest: 2);
    await service.backup(AppConfig.defaults().copyWith(
      glossary: {'詞一': 'Term 1'},
    ));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await service.backup(AppConfig.defaults().copyWith(
      glossary: {'詞二': 'Term 2'},
    ));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final latest = await service.backup(AppConfig.defaults().copyWith(
      glossary: {'詞三': 'Term 3'},
    ));

    final backupDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}glossary_sync_backups',
    );
    final files = await backupDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
    final latestJson =
        jsonDecode(await latest.readAsString()) as Map<String, dynamic>;

    expect(files, hasLength(2));
    expect(latestJson['glossary']['詞三'], 'Term 3');

    final backups = await service.listBackups();

    expect(backups, hasLength(2));
    expect(backups.first.termCount, 1);
  });

  test('GlossarySyncBackupService 可將備份還原到目前設定', () async {
    final tempDir = await Directory.systemTemp.createTemp('typetwo_restore_');
    ConfigService.debugConfigDir = tempDir;
    addTearDown(() async {
      ConfigService.debugConfigDir = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    final service = const GlossarySyncBackupService();
    final backup = await service.backup(AppConfig.defaults().copyWith(
      glossary: {'備份詞': 'Backup term'},
      langGlossary: {
        '繁體中文-越南文': {'簽核': 'Ký duyệt'},
      },
    ));

    final restored = await service.restore(
      AppConfig.defaults().copyWith(glossary: {'目前詞': 'Current term'}),
      backup.path,
    );

    expect(restored.glossary, {'備份詞': 'Backup term'});
    expect(restored.langGlossary['繁體中文-越南文'], {'簽核': 'Ký duyệt'});
  });

  test('GlossarySyncBackupService 快速連續備份不會覆蓋檔案', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('typetwo_backup_unique_');
    ConfigService.debugConfigDir = tempDir;
    addTearDown(() async {
      ConfigService.debugConfigDir = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    final service = const GlossarySyncBackupService();
    final first = await service.backup(AppConfig.defaults().copyWith(
      glossary: {'詞一': 'Term 1'},
    ));
    final second = await service.backup(AppConfig.defaults().copyWith(
      glossary: {'詞二': 'Term 2'},
    ));

    expect(first.path, isNot(second.path));
    expect(await first.exists(), isTrue);
    expect(await second.exists(), isTrue);
  });
}
