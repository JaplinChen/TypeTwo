import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_config.dart';

const _appGroupChannel = MethodChannel('typetwo/appgroup');

class ConfigService {
  static const _fileName = 'translator_config.json';
  static const _glossaryFileName = 'glossary.json';
  static const _currentSchemaVersion = 1;

  static Future<Directory> _configDir() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      final dir = Directory('$appData\\TypeTwo');
      await dir.create(recursive: true);
      return dir;
    }
    return getApplicationSupportDirectory();
  }

  static Future<File> _configFile() async {
    final dir = await _configDir();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  static Future<File> _glossaryFile() async {
    final dir = await _configDir();
    return File('${dir.path}${Platform.pathSeparator}$_glossaryFileName');
  }

  // Migrate config from old exe-dir location to AppData.
  static Future<void> _migrateFromExeDir() async {
    final exeDir = File(Platform.resolvedExecutable).parent;
    final oldConfig = File('${exeDir.path}${Platform.pathSeparator}$_fileName');
    if (!await oldConfig.exists()) return;

    final newFile = await _configFile();

    if (await newFile.exists()) {
      // AppData already exists: re-migrate only if exe dir has rules but AppData doesn't.
      // This handles the case where migration ran before the user had set any rules.
      try {
        final appDataMap =
            jsonDecode(await newFile.readAsString()) as Map<String, dynamic>;
        final hasAppDataRules =
            ((appDataMap['extraInstructions'] as List?)?.isNotEmpty) ?? false;
        if (hasAppDataRules) return;

        final oldMap =
            jsonDecode(await oldConfig.readAsString()) as Map<String, dynamic>;
        final hasOldRules =
            ((oldMap['extraInstructions'] as List?)?.isNotEmpty) ?? false;
        if (!hasOldRules) return;

        await oldConfig.copy(newFile.path);
      } catch (_) {}
      return;
    }

    await oldConfig.copy(newFile.path);

    final newGlossary = await _glossaryFile();
    if (!await newGlossary.exists()) {
      final oldGlossary =
          File('${exeDir.path}${Platform.pathSeparator}$_glossaryFileName');
      if (await oldGlossary.exists()) {
        await oldGlossary.copy(newGlossary.path);
      }
    }
  }

  static Future<AppConfig> load() async {
    await _migrateFromExeDir();

    final file = await _configFile();
    final gFile = await _glossaryFile();

    if (await file.exists()) {
      try {
        final configJson =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;

        if (await gFile.exists()) {
          try {
            final glossaryJson = jsonDecode(await gFile.readAsString());
            if (glossaryJson is Map) configJson['glossary'] = glossaryJson;
          } catch (_) {}
        }
        // If glossary.json missing but old config had inline glossary, keep it
        // for this load and migrate on save.

        AppConfig cfg = AppConfig.fromJson(configJson);

        // Migrate: write glossary.json if it didn't exist yet
        if (!await gFile.exists() && cfg.glossary.isNotEmpty) {
          await _writeGlossary(cfg.glossary);
        }

        final migrated = _migrate(cfg);
        if (migrated.schemaVersion != cfg.schemaVersion) await save(migrated);
        return migrated;
      } catch (e) {
        try {
          await file.delete();
        } catch (_) {}
        throw Exception(
          'Config corrupted (auto-reset to defaults).\nPath: ${file.path}\nDetails: $e',
        );
      }
    }

    // First run: seed from bundled assets
    try {
      final bundledConfig =
          await rootBundle.loadString('assets/translator_config.json');
      final configJson =
          jsonDecode(bundledConfig) as Map<String, dynamic>;

      try {
        final bundledGlossary =
            await rootBundle.loadString('assets/glossary.json');
        final glossaryJson = jsonDecode(bundledGlossary);
        if (glossaryJson is Map) configJson['glossary'] = glossaryJson;
      } catch (_) {}

      final cfg = AppConfig.fromJson(configJson);
      await save(cfg);
      return cfg;
    } catch (_) {
      return AppConfig.defaults();
    }
  }

  static Future<bool> save(AppConfig cfg) async {
    final json = cfg.toJson();
    final glossaryRaw = json.remove('glossary');
    final glossary = glossaryRaw is Map
        ? glossaryRaw.map((k, v) => MapEntry(k.toString(), v.toString()))
        : <String, String>{};

    final configJson = const JsonEncoder.withIndent('  ').convert(json);
    final glossaryJson = const JsonEncoder.withIndent('  ').convert(glossary);

    final file = await _configFile();
    await file.writeAsString(configJson);
    await _writeGlossary(glossary);

    if (Platform.isIOS) {
      await _syncToAppGroup(configJson, glossaryJson);
    }

    return true;
  }

  static Future<void> _syncToAppGroup(
      String configJson, String glossaryJson) async {
    try {
      final path = await _appGroupChannel
          .invokeMethod<String>('getContainerPath');
      if (path == null) return;
      final dir = Directory(path);
      await dir.create(recursive: true);
      await File('$path/$_fileName').writeAsString(configJson);
      await File('$path/$_glossaryFileName').writeAsString(glossaryJson);
    } catch (_) {}
  }

  static Future<void> _writeGlossary(Map<String, String> glossary) async {
    final gFile = await _glossaryFile();
    await gFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(glossary));
  }

  static AppConfig _migrate(AppConfig cfg) {
    if (cfg.schemaVersion >= _currentSchemaVersion) return cfg;
    AppConfig updated = cfg;
    if (cfg.schemaVersion < 1) {
      // v0→v1: reset restrictToAllowedProcesses to false (old default was true)
      updated = updated.copyWith(
        restrictToAllowedProcesses: false,
        schemaVersion: 1,
      );
    }
    return updated;
  }

  static Future<String> configFilePath() async {
    return (await _configFile()).path;
  }
}
