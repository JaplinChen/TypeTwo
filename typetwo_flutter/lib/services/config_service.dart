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
    final file = await _configFile();

    if (await file.exists()) {
      try {
        return AppConfig.fromJsonString(await file.readAsString());
      } catch (e) {
        // Auto-delete so next startup is clean; surface error once via ConfigProvider
        try { await file.delete(); } catch (_) {}
        throw Exception(
          'Config corrupted (auto-reset to defaults).\nPath: ${file.path}\nDetails: $e',
        );
      }
    }

    // First run: seed from bundled asset
    try {
      final bundled =
          await rootBundle.loadString('assets/translator_config.json');
      final cfg = AppConfig.fromJsonString(bundled);
      await save(cfg);
      return cfg;
    } catch (_) {
      return AppConfig.defaults();
    }
  }

  /// Returns true if the config was successfully synced to the TypeTwo.exe directory.
  static Future<bool> save(AppConfig cfg) async {
    final json = cfg.toJsonString();
    final file = await _configFile();
    await file.writeAsString(json);
    return await _syncToBridge(json);
  }

  static Future<bool> _syncToBridge(String json) async {
    final bridgeDir = BridgeService.exeDir();
    if (bridgeDir == null) return false;
    try {
      await File('${bridgeDir.path}/$_fileName').writeAsString(json);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> configFilePath() async {
    return (await _configFile()).path;
  }
}
