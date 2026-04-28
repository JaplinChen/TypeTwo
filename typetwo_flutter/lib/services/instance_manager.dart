import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

// CreateMutexW is not exported by win32 5.x — bind it manually.
final _kernel32 = DynamicLibrary.open('kernel32.dll');

typedef _CreateMutexWNative = IntPtr Function(
    Pointer<SECURITY_ATTRIBUTES>, Int32, Pointer<Utf16>);
typedef _CreateMutexW = int Function(
    Pointer<SECURITY_ATTRIBUTES>, int, Pointer<Utf16>);
final _createMutex =
    _kernel32.lookupFunction<_CreateMutexWNative, _CreateMutexW>(
        'CreateMutexW');

class InstanceManager {
  static const _mutexName = 'Local\\TypeTwo.SingleInstance';
  static const _eventName = 'Local\\TypeTwo.ShowWindow';

  static int _mutex = 0;
  static int _showEvent = 0;
  static Timer? _pollTimer;

  /// Returns true if this is the first instance.
  /// If false, signals the existing instance to show its window.
  static bool acquire() {
    if (!Platform.isWindows) return true;

    // Capture GetLastError inside the using() block before arena frees memory,
    // since HeapFree may reset the last error on some Windows versions.
    int lastError = 0;
    using((arena) {
      final name = _mutexName.toNativeUtf16(allocator: arena);
      SetLastError(0);
      _mutex = _createMutex(nullptr, FALSE, name);
      lastError = GetLastError();
    });

    if (_mutex == 0 || lastError == ERROR_ALREADY_EXISTS) {
      if (_mutex != 0) CloseHandle(_mutex);
      _mutex = 0;
      _signalExisting();
      return false;
    }

    _createShowEvent();
    return true;
  }

  static void release() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_showEvent != 0) {
      CloseHandle(_showEvent);
      _showEvent = 0;
    }
    if (_mutex != 0) {
      CloseHandle(_mutex);
      _mutex = 0;
    }
  }

  static void _signalExisting() {
    using((arena) {
      final name = _eventName.toNativeUtf16(allocator: arena);
      final h = OpenEvent(EVENT_MODIFY_STATE, FALSE, name);
      if (h == 0) return;
      SetEvent(h);
      CloseHandle(h);
    });
  }

  static void _createShowEvent() {
    using((arena) {
      final name = _eventName.toNativeUtf16(allocator: arena);
      _showEvent = CreateEvent(nullptr, FALSE, FALSE, name);
    });
    if (_showEvent != 0) _startPolling();
  }

  static void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (_showEvent == 0) return;
      final result = WaitForSingleObject(_showEvent, 0);
      if (result == WAIT_OBJECT_0) {
        windowManager.show();
        windowManager.focus();
      }
    });
  }
}
