import 'dart:io';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:path_provider/path_provider.dart';
export '../l10n/app_strings.dart';
import '../l10n/app_strings.dart';
import '../platform/tray_service.dart';

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
    await _persist(_locale);
  }

  Future<void> setLocale(String locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _persist(locale);
    if (Platform.isWindows) await TrayService().updateLocale(locale);
  }

  Future<void> _persist(String locale) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/$_fileName').writeAsString(locale);
    } catch (e) {
      debugPrint('[LocaleProvider] persist failed: $e');
    }
  }
}
