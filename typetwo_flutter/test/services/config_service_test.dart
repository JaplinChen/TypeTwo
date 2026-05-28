import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/services/config_service.dart';

void main() {
  group('ConfigService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('typetwo_config_test_');
      ConfigService.debugConfigDir = tempDir;
    });

    tearDown(() async {
      ConfigService.debugConfigDir = null;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('設定檔損壞時保留備份，不直接刪除內容', () async {
      final configFile = File('${tempDir.path}${Platform.pathSeparator}'
          'translator_config.json');
      await configFile.writeAsString('{not valid json');

      await expectLater(ConfigService.load(), throwsException);

      expect(await configFile.exists(), isFalse);
      final backups = await tempDir
          .list()
          .where((entity) =>
              entity is File &&
              entity.path.contains('translator_config.json.corrupt.'))
          .toList();

      expect(backups, hasLength(1));
      expect(await File(backups.single.path).readAsString(), '{not valid json');
    });

    test('save 會將詞彙表拆到 glossary.json 並避免寫入主設定檔', () async {
      final config = AppConfig.defaults().copyWith(
        glossary: {
          '申請': 'Nộp đơn',
          '入口網站': 'Portal',
        },
      );

      await ConfigService.save(config);

      final configFile = File('${tempDir.path}${Platform.pathSeparator}'
          'translator_config.json');
      final glossaryFile =
          File('${tempDir.path}${Platform.pathSeparator}glossary.json');

      final configJson =
          jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
      final glossaryJson =
          jsonDecode(await glossaryFile.readAsString()) as Map<String, dynamic>;

      expect(configJson.containsKey('glossary'), isFalse);
      expect(glossaryJson, {
        '申請': 'Nộp đơn',
        '入口網站': 'Portal',
      });
    });
  });
}
