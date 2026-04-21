import 'dart:io';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:path_provider/path_provider.dart';
import '../l10n/app_strings.dart';
import '../services/bridge_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const _supported = ['zh', 'en', 'vi'];
  static const _fileName = 'ui_locale.txt';

  String _locale = 'zh';

  String get locale => _locale;
  AppStrings get strings => AppStrings(_locale);

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final saved = (await file.readAsString()).trim();
        if (_supported.contains(saved)) _locale = saved;
      }
    } catch (e) {
      debugPrint('[LocaleProvider] load failed: $e');
    }
    // Keep bridge directory in sync on every startup
    await _persist(_locale);
  }

  Future<void> setLocale(String locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _persist(locale);
  }

  Future<void> _persist(String locale) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/$_fileName').writeAsString(locale);
    } catch (e) {
      debugPrint('[LocaleProvider] docs persist failed: $e');
    }
    // Sync to bridge exe directory so Python reads the correct locale
    try {
      final bridgeDir = BridgeService.exeDir();
      if (bridgeDir != null) {
        await File('${bridgeDir.path}/$_fileName').writeAsString(locale);
      }
    } catch (e) {
      debugPrint('[LocaleProvider] bridge sync failed: $e');
    }
  }
}
