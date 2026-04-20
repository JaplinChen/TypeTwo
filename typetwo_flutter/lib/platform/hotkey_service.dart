import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:win32/win32.dart';
import '../models/app_config.dart';
import '../services/translate_service.dart';

class HotkeyService {
  static const int _vkAlt = 0x12;
  static const int _vkShift = 0x10;
  static const int _vkControl = 0x11;
  static const int _vkC = 0x43;
  static const int _vkV = 0x56;
  static const int _inputKeyboard = 1;
  static const int _keyEventfKeyUp = 0x0002;

  bool _active = false;
  bool _deferToBridge = false;
  HotKey? _hotKey;
  Future<AppConfig> Function()? _getConfig;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> register(Future<AppConfig> Function() getConfig) async {
    if (!Platform.isWindows || _active) return;
    _getConfig = getConfig;
    final cfg = await getConfig();
    await _registerHotkey(cfg.hotkeyModifiers, cfg.hotkeyKey);
  }

  /// Called when TypeTwo.exe bridge starts or stops.
  /// Bridge running → Flutter yields hotkey control to the bridge.
  /// Bridge stopped → Flutter re-registers its own hotkey.
  Future<void> setBridgeActive(bool active) async {
    if (_deferToBridge == active) return;
    _deferToBridge = active;
    if (active) {
      await unregister();
    } else if (_getConfig != null) {
      await register(_getConfig!);
    }
  }

  Future<void> reregister(AppConfig cfg) async {
    if (!Platform.isWindows || _deferToBridge) return;
    await unregister();
    await _registerHotkey(cfg.hotkeyModifiers, cfg.hotkeyKey);
  }

  Future<void> unregister() async {
    if (!Platform.isWindows || !_active || _hotKey == null) return;
    await hotKeyManager.unregister(_hotKey!);
    _active = false;
  }

  // ── Key / modifier maps ────────────────────────────────────────────────────

  static const Map<String, HotKeyModifier> _modifierMap = {
    'ctrl': HotKeyModifier.control,
    'alt': HotKeyModifier.alt,
    'shift': HotKeyModifier.shift,
    'meta': HotKeyModifier.meta,
  };

  static const Map<String, PhysicalKeyboardKey> _keyMap = {
    'a': PhysicalKeyboardKey.keyA, 'b': PhysicalKeyboardKey.keyB,
    'c': PhysicalKeyboardKey.keyC, 'd': PhysicalKeyboardKey.keyD,
    'e': PhysicalKeyboardKey.keyE, 'f': PhysicalKeyboardKey.keyF,
    'g': PhysicalKeyboardKey.keyG, 'h': PhysicalKeyboardKey.keyH,
    'i': PhysicalKeyboardKey.keyI, 'j': PhysicalKeyboardKey.keyJ,
    'k': PhysicalKeyboardKey.keyK, 'l': PhysicalKeyboardKey.keyL,
    'm': PhysicalKeyboardKey.keyM, 'n': PhysicalKeyboardKey.keyN,
    'o': PhysicalKeyboardKey.keyO, 'p': PhysicalKeyboardKey.keyP,
    'q': PhysicalKeyboardKey.keyQ, 'r': PhysicalKeyboardKey.keyR,
    's': PhysicalKeyboardKey.keyS, 't': PhysicalKeyboardKey.keyT,
    'u': PhysicalKeyboardKey.keyU, 'v': PhysicalKeyboardKey.keyV,
    'w': PhysicalKeyboardKey.keyW, 'x': PhysicalKeyboardKey.keyX,
    'y': PhysicalKeyboardKey.keyY, 'z': PhysicalKeyboardKey.keyZ,
    '0': PhysicalKeyboardKey.digit0, '1': PhysicalKeyboardKey.digit1,
    '2': PhysicalKeyboardKey.digit2, '3': PhysicalKeyboardKey.digit3,
    '4': PhysicalKeyboardKey.digit4, '5': PhysicalKeyboardKey.digit5,
    '6': PhysicalKeyboardKey.digit6, '7': PhysicalKeyboardKey.digit7,
    '8': PhysicalKeyboardKey.digit8, '9': PhysicalKeyboardKey.digit9,
    'f1': PhysicalKeyboardKey.f1,   'f2': PhysicalKeyboardKey.f2,
    'f3': PhysicalKeyboardKey.f3,   'f4': PhysicalKeyboardKey.f4,
    'f5': PhysicalKeyboardKey.f5,   'f6': PhysicalKeyboardKey.f6,
    'f7': PhysicalKeyboardKey.f7,   'f8': PhysicalKeyboardKey.f8,
    'f9': PhysicalKeyboardKey.f9,   'f10': PhysicalKeyboardKey.f10,
    'f11': PhysicalKeyboardKey.f11, 'f12': PhysicalKeyboardKey.f12,
    'enter': PhysicalKeyboardKey.enter,
    'space': PhysicalKeyboardKey.space,
    'tab': PhysicalKeyboardKey.tab,
    'escape': PhysicalKeyboardKey.escape,
    'backspace': PhysicalKeyboardKey.backspace,
    'delete': PhysicalKeyboardKey.delete,
    'insert': PhysicalKeyboardKey.insert,
    'home': PhysicalKeyboardKey.home,
    'end': PhysicalKeyboardKey.end,
    'pageup': PhysicalKeyboardKey.pageUp,
    'pagedown': PhysicalKeyboardKey.pageDown,
    'arrowup': PhysicalKeyboardKey.arrowUp,
    'arrowdown': PhysicalKeyboardKey.arrowDown,
    'arrowleft': PhysicalKeyboardKey.arrowLeft,
    'arrowright': PhysicalKeyboardKey.arrowRight,
    'minus': PhysicalKeyboardKey.minus,
    'equal': PhysicalKeyboardKey.equal,
    'comma': PhysicalKeyboardKey.comma,
    'period': PhysicalKeyboardKey.period,
    'slash': PhysicalKeyboardKey.slash,
    'semicolon': PhysicalKeyboardKey.semicolon,
    'quote': PhysicalKeyboardKey.quote,
    'backquote': PhysicalKeyboardKey.backquote,
    'backslash': PhysicalKeyboardKey.backslash,
    'bracketleft': PhysicalKeyboardKey.bracketLeft,
    'bracketright': PhysicalKeyboardKey.bracketRight,
  };

  static String? physicalKeyToString(PhysicalKeyboardKey key) {
    for (final entry in _keyMap.entries) {
      if (entry.value == key) return entry.key;
    }
    return null;
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<bool> _registerHotkey(List<String> mods, String key) async {
    final physKey = _keyMap[key];
    if (physKey == null) return false;

    final modifiers = mods
        .map((m) => _modifierMap[m])
        .whereType<HotKeyModifier>()
        .toList();

    _hotKey = HotKey(
      key: physKey,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );
    try {
      await hotKeyManager.register(
        _hotKey!,
        keyDownHandler: (_) => _onHotkey(_getConfig!, mods),
      );
      _active = true;
      return true;
    } catch (e) {
      _hotKey = null;
      _msgBox('快捷鍵註冊失敗：${mods.join("+")}+$key\n\n請換一個組合。\n\n$e');
      return false;
    }
  }

  Future<void> _onHotkey(
      Future<AppConfig> Function() getConfig, List<String> mods) async {
    final before = await _clipGet() ?? '';

    // Release non-Ctrl modifiers so target app receives plain Ctrl+C
    if (mods.contains('alt')) _sendKeyUp(_vkAlt);
    if (mods.contains('shift')) _sendKeyUp(_vkShift);
    await Future.delayed(const Duration(milliseconds: 50));

    _sendCtrl(_vkC);
    await Future.delayed(const Duration(milliseconds: 400));

    final after = await _clipGet() ?? '';
    final selected = after.trim();

    if (selected.isEmpty || selected == before.trim()) {
      _msgBox('請先選取要翻譯的文字，再按快捷鍵。');
      return;
    }

    try {
      final cfg = await getConfig();
      final result = await TranslateService.translate(selected, cfg);
      await Clipboard.setData(ClipboardData(text: result));
      _sendCtrl(_vkV);
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (e) {
      _msgBox('翻譯失敗。\n\n$e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      await Clipboard.setData(ClipboardData(text: before));
    }
  }

  // ── Clipboard ──────────────────────────────────────────────────────────────

  static Future<String?> _clipGet() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  // ── SendInput helpers ──────────────────────────────────────────────────────

  static void _sendKeyUp(int vk) {
    final input = calloc<INPUT>(1);
    try {
      input[0].type = _inputKeyboard;
      input[0].ki.wVk = vk;
      input[0].ki.dwFlags = _keyEventfKeyUp;
      SendInput(1, input, sizeOf<INPUT>());
    } finally {
      calloc.free(input);
    }
  }

  static void _sendCtrl(int vk) {
    final inputs = calloc<INPUT>(4);
    try {
      inputs[0].type = _inputKeyboard;
      inputs[0].ki.wVk = _vkControl;
      inputs[0].ki.dwFlags = 0;
      inputs[1].type = _inputKeyboard;
      inputs[1].ki.wVk = vk;
      inputs[1].ki.dwFlags = 0;
      inputs[2].type = _inputKeyboard;
      inputs[2].ki.wVk = vk;
      inputs[2].ki.dwFlags = _keyEventfKeyUp;
      inputs[3].type = _inputKeyboard;
      inputs[3].ki.wVk = _vkControl;
      inputs[3].ki.dwFlags = _keyEventfKeyUp;
      SendInput(4, inputs, sizeOf<INPUT>());
    } finally {
      calloc.free(inputs);
    }
  }

  // ── Message box ────────────────────────────────────────────────────────────

  static void _msgBox(String msg) {
    using((arena) {
      MessageBox(
        NULL,
        msg.toNativeUtf16(allocator: arena),
        'TypeTwo'.toNativeUtf16(allocator: arena),
        MB_ICONASTERISK,
      );
    });
  }
}
