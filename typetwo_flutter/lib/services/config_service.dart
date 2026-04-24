import 'dart:io';
import 'package:flutter/services.dart';
import '../models/app_config.dart';

class ConfigService {
  static const _fileName = 'translator_config.json';

  static Future<File> _configFile() async {
    final dir = File(Platform.resolvedExecutable).parent;
    return File('${dir.path}/$_fileName');
  }

  static Future<AppConfig> load() async {
    final file = await _configFile();
    if (await file.exists()) {
      try {
        return AppConfig.fromJsonString(await file.readAsString());
      } catch (e) {
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

  static Future<bool> save(AppConfig cfg) async {
    final json = cfg.toJsonString();
    final file = await _configFile();
    await file.writeAsString(json);
    return true;
  }

  static Future<String> configFilePath() async {
    return (await _configFile()).path;
  }
}
