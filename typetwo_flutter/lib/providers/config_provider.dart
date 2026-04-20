import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import '../services/config_service.dart';

class ConfigProvider extends ChangeNotifier {
  AppConfig _config = AppConfig.defaults();
  bool _loading = true;
  String? _error;

  AppConfig get config => _config;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _config = await ConfigService.load();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Returns true if config was also synced to the TypeTwo.exe directory.
  Future<bool> save(AppConfig cfg) async {
    final synced = await ConfigService.save(cfg);
    _config = cfg;
    notifyListeners();
    return synced;
  }

  void update(AppConfig cfg) {
    _config = cfg;
    notifyListeners();
  }

  /// Update in-memory config without triggering Consumer/watch rebuilds.
  /// Use for per-keystroke text field changes. Save button reads _config directly,
  /// so quieted changes are still persisted when the user clicks 儲存.
  void updateQuiet(AppConfig cfg) {
    _config = cfg;
  }
}
