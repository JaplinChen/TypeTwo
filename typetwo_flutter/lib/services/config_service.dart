import 'dart:io';
import 'package:flutter/services.dart';
import '../models/app_config.dart';

class ConfigService {
  static const _fileName = 'translator_config.json';

  static Future<File> _configFile() async {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null) {
        final dir = Directory('$localAppData\\TypeTwo');
        await dir.create(recursive: true);
        return File('${dir.path}\\$_fileName');
      }
    }
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

    // Migration: check old location (next to exe) and migrate it
    if (Platform.isWindows) {
      final oldFile = File(
          '${File(Platform.resolvedExecutable).parent.path}/$_fileName');
      if (oldFile.path != file.path && await oldFile.exists()) {
        try {
          final cfg = AppConfig.fromJsonString(await oldFile.readAsString());
          await save(cfg);
          return cfg;
        } catch (_) {}
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
