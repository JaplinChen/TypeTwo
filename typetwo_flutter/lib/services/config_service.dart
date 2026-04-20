import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_config.dart';
import 'bridge_service.dart';

class ConfigService {
  static const _fileName = 'translator_config.json';

  static Future<File> _configFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<AppConfig> load() async {
    try {
      final file = await _configFile();
      if (await file.exists()) {
        return AppConfig.fromJsonString(await file.readAsString());
      }
      // First run: seed from bundled asset
      final bundled = await rootBundle.loadString('assets/translator_config.json');
      final cfg = AppConfig.fromJsonString(bundled);
      await save(cfg);
      return cfg;
    } catch (_) {
      return AppConfig.defaults();
    }
  }

  static Future<void> save(AppConfig cfg) async {
    final json = cfg.toJsonString();
    final file = await _configFile();
    await file.writeAsString(json);
    // Sync to TypeTwo.exe directory so the bridge reads the same config
    final bridgeDir = BridgeService.exeDir();
    if (bridgeDir != null) {
      try {
        await File('${bridgeDir.path}/$_fileName').writeAsString(json);
      } catch (_) {}
    }
  }

  static Future<String> configFilePath() async {
    return (await _configFile()).path;
  }
}
