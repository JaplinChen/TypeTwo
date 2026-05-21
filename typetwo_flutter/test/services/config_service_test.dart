import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
  });
}
