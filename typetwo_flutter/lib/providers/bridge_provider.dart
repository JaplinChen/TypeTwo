import 'package:flutter/foundation.dart';
import '../services/bridge_service.dart';

enum BridgeStatus { unknown, running, stopped }

class BridgeProvider extends ChangeNotifier {
  late final BridgeService _service;
  BridgeStatus _status = BridgeStatus.unknown;
  bool _busy = false;

  BridgeStatus get status => _status;
  bool get busy => _busy;
  bool get isRunning => _status == BridgeStatus.running;
  bool get exeFound => BridgeService.findExe() != null;

  BridgeProvider() {
    _service = BridgeService(onStatusChange: (running) {
      _status = running ? BridgeStatus.running : BridgeStatus.stopped;
      notifyListeners();
    });
    _service.startPolling();
    _checkNow();
  }

  Future<void> _checkNow() async {
    final running = await _service.isRunning();
    _status = running ? BridgeStatus.running : BridgeStatus.stopped;
    notifyListeners();
  }

  Future<void> start() async {
    _busy = true;
    notifyListeners();
    try {
      await _service.start();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _busy = true;
    notifyListeners();
    try {
      await _service.stop();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
