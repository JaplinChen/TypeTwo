import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class RunningProcessInfo {
  final String processName;
  final String windowTitle;

  const RunningProcessInfo({
    required this.processName,
    required this.windowTitle,
  });
}

class ProcessPickerService {
  const ProcessPickerService._();

  static Future<String?> foregroundProcess() async {
    if (!Platform.isWindows) return null;
    final hwnd = GetForegroundWindow();
    if (hwnd == 0) return null;
    return _processNameFromWindow(hwnd);
  }

  static Future<List<RunningProcessInfo>> listVisibleProcesses() async {
    if (!Platform.isWindows) return const [];

    final byProcess = <String, RunningProcessInfo>{};
    var hwnd = GetTopWindow(NULL);
    while (hwnd != 0) {
      if (_isCandidateWindow(hwnd)) {
        final title = _windowTitle(hwnd);
        final processName = _processNameFromWindow(hwnd);
        if (title.isNotEmpty &&
            processName != null &&
            !_isIgnored(processName)) {
          final existing = byProcess[processName.toLowerCase()];
          if (existing == null || existing.windowTitle.isEmpty) {
            byProcess[processName.toLowerCase()] = RunningProcessInfo(
              processName: processName,
              windowTitle: title,
            );
          }
        }
      }
      hwnd = GetWindow(hwnd, GW_HWNDNEXT);
    }

    final items = byProcess.values.toList()
      ..sort((a, b) {
        final byName =
            a.processName.toLowerCase().compareTo(b.processName.toLowerCase());
        if (byName != 0) return byName;
        return a.windowTitle
            .toLowerCase()
            .compareTo(b.windowTitle.toLowerCase());
      });
    return items;
  }

  static bool _isCandidateWindow(int hwnd) {
    if (IsWindowVisible(hwnd) == 0) return false;
    if (GetWindow(hwnd, GW_OWNER) != 0) return false;
    return _windowTitle(hwnd).isNotEmpty;
  }

  static String _windowTitle(int hwnd) {
    final length = GetWindowTextLength(hwnd);
    if (length <= 0) return '';
    final buffer = wsalloc(length + 1);
    try {
      final copied = GetWindowText(hwnd, buffer, length + 1);
      if (copied <= 0) return '';
      return buffer.toDartString().trim();
    } finally {
      free(buffer);
    }
  }

  static String? _processNameFromWindow(int hwnd) {
    final pidPtr = calloc<Uint32>();
    try {
      GetWindowThreadProcessId(hwnd, pidPtr);
      final pid = pidPtr.value;
      if (pid == 0) return null;
      return _processNameFromPid(pid);
    } finally {
      calloc.free(pidPtr);
    }
  }

  static String? _processNameFromPid(int pid) {
    final process = OpenProcess(
      PROCESS_QUERY_LIMITED_INFORMATION,
      FALSE,
      pid,
    );
    if (process == 0) return null;

    final pathBuffer = wsalloc(MAX_PATH);
    final sizePtr = calloc<Uint32>()..value = MAX_PATH;
    try {
      final ok = QueryFullProcessImageName(process, 0, pathBuffer, sizePtr);
      if (ok == 0) return null;
      final fullPath = pathBuffer.toDartString();
      if (fullPath.isEmpty) return null;
      return fullPath.split(Platform.pathSeparator).last;
    } finally {
      free(pathBuffer);
      calloc.free(sizePtr);
      CloseHandle(process);
    }
  }

  static bool _isIgnored(String processName) {
    final lower = processName.toLowerCase();
    return lower == 'typetwo.exe' || lower == 'typetwoui.exe';
  }
}
