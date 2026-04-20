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

  Future<void> save(AppConfig cfg) async {
    await ConfigService.save(cfg);
    _config = cfg;
    notifyListeners();
  }

  void update(AppConfig cfg) {
    _config = cfg;
    notifyListeners();
  }
}
