import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class BridgeService {
  static const _healthUrl = 'http://127.0.0.1:8765/health';

  Process? _ownedProcess;
  Timer? _pollTimer;
  final void Function(bool running) onStatusChange;

  BridgeService({required this.onStatusChange});

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
    if (exe == null) throw Exception('找不到 TypeTwo.exe');
    await _syncConfig(exe.parent);
    _ownedProcess = await Process.start(exe.path, [], mode: ProcessStartMode.detached);
    onStatusChange(true);
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
    } catch (_) {}
  }

  Future<void> stop() async {
    _ownedProcess?.kill();
    _ownedProcess = null;
    if (Platform.isWindows) {
      await Process.run('powershell', [
        '-Command',
        'Stop-Process -Name TypeTwo -Force -ErrorAction SilentlyContinue',
      ]);
    }
    onStatusChange(false);
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      onStatusChange(await isRunning());
    });
  }

  void dispose() {
    _pollTimer?.cancel();
    _ownedProcess?.kill();
  }
}
