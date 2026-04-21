import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class BridgeService {
  static const _healthUrl = 'http://127.0.0.1:8765/health';
  static const _startupTimeout = Duration(seconds: 8);
  static const _startupInterval = Duration(milliseconds: 400);

  Process? _ownedProcess;
  int? _ownedPid;
  Timer? _pollTimer;
  final void Function(bool running) onStatusChange;

  BridgeService({required this.onStatusChange});

  bool get canStopOwnedProcess => _ownedPid != null;

  // ── Exe location ───────────────────────────────────────────────────────────

  static File? findExe() {
    final exeDir = File(Platform.resolvedExecutable).parent;
    final candidates = [
      File('${exeDir.path}/TypeTwo.exe'),
      _devExe(exeDir),
    ];
    for (final f in candidates) {
      if (f != null && f.existsSync()) return f;
    }
    return null;
  }

  static File? _devExe(Directory exeDir) {
    try {
      // flutter run: .../typetwo_flutter/build/windows/x64/runner/Debug/
      // up 6 levels → project root TypeTwo/
      var d = exeDir;
      for (int i = 0; i < 6; i++) {
        d = d.parent;
      }
      final f = File('${d.path}/src/dist/TypeTwo.exe');
      return f;
    } catch (_) {
      return null;
    }
  }

  static Directory? exeDir() {
    final exe = findExe();
    return exe?.parent;
  }

  // ── Health ─────────────────────────────────────────────────────────────────

  Future<bool> isRunning() async {
    try {
      final r = await http
          .get(Uri.parse(_healthUrl))
          .timeout(const Duration(seconds: 2));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (await isRunning()) {
      onStatusChange(true);
      return;
    }
    final exe = findExe();
    if (exe == null) throw const ExeNotFoundException();
    await _syncConfig(exe.parent);
    _ownedProcess =
        await Process.start(exe.path, [], mode: ProcessStartMode.detached);
    _ownedPid = _ownedProcess?.pid;

    // Poll until bridge responds or timeout
    final deadline = DateTime.now().add(_startupTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(_startupInterval);
      if (await isRunning()) {
        onStatusChange(true);
        return;
      }
    }
    // Startup timed out — kill the stuck process and report failure
    await _killOwnedProcess();
    onStatusChange(false);
    throw const BridgeStartTimeoutException();
  }

  static Future<void> _syncConfig(Directory bridgeDir) async {
    const fileName = 'translator_config.json';
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final src = File('${docsDir.path}/$fileName');
      final dst = File('${bridgeDir.path}/$fileName');
      if (await src.exists()) {
        await src.copy(dst.path);
      }
    } catch (e) {
      debugPrint('[BridgeService] config sync failed: $e');
    }
  }

  Future<void> stop() async {
    if (_ownedPid == null) {
      throw const BridgeOwnershipException();
    }
    await _killOwnedProcess();
    onStatusChange(false);
  }

  Future<void> _killOwnedProcess() async {
    final pid = _ownedPid;
    _ownedProcess = null;
    _ownedPid = null;
    if (pid == null) return;
    if (Platform.isWindows) {
      await Process.run('taskkill', [
        '/PID',
        '$pid',
        '/T',
        '/F',
      ]);
    } else {
      try {
        Process.killPid(pid);
      } catch (_) {
        // Ignore kill failures; health polling will reconcile the state.
      }
    }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      isRunning().then(onStatusChange).catchError((e) {
        debugPrint('[BridgeService] poll error: $e');
      });
    });
  }

  void dispose() {
    _pollTimer?.cancel();
    _ownedProcess?.kill();
    _ownedPid = null;
  }
}

class ExeNotFoundException implements Exception {
  const ExeNotFoundException();
}

class BridgeStartTimeoutException implements Exception {
  const BridgeStartTimeoutException();
}

class BridgeOwnershipException implements Exception {
  const BridgeOwnershipException();
}
