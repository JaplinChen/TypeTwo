import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:win32/win32.dart';
import '../l10n/app_strings.dart';
import '../models/app_config.dart';
import '../services/provider_error.dart';
import '../services/translate_service.dart';
import 'process_picker_service.dart';
part '_hotkey_key_maps.dart';
part '_hotkey_send_input.dart';

class HotkeyService {
  bool _active = false;
  bool _busy = false;
  HotKey? _hotKey;
  Future<AppConfig> Function()? _getConfig;
  String Function() _getLocale = () => 'zh';

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> register(
    Future<AppConfig> Function() getConfig, {
    String Function()? getLocale,
  }) async {
    if (!Platform.isWindows || _active) return;
    _getConfig = getConfig;
    if (getLocale != null) _getLocale = getLocale;
    final cfg = await getConfig();
    await _registerHotkey(cfg.hotkeyModifiers, cfg.hotkeyKey);
  }

  Future<void> reregister(AppConfig cfg) async {
    if (!Platform.isWindows) return;
    await unregister();
    await _registerHotkey(cfg.hotkeyModifiers, cfg.hotkeyKey);
  }

  Future<void> unregister() async {
    if (!Platform.isWindows || !_active || _hotKey == null) return;
    await hotKeyManager.unregister(_hotKey!);
    _active = false;
  }

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

    final modifiers =
        mods.map((m) => _modifierMap[m]).whereType<HotKeyModifier>().toList();

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
      final s = AppStrings(_getLocale());
      final combo =
          [...mods, key].map((p) => p[0].toUpperCase() + p.substring(1)).join('+');
      _msgBox(s.hotkeyRegisterFailed(combo, e));
      return false;
    }
  }

  Future<void> _onHotkey(
      Future<AppConfig> Function() getConfig, List<String> mods) async {
    if (_busy) return;
    _busy = true;
    try {
      final cfg = await getConfig();
      final s = AppStrings(_getLocale());

      if (!await _isAllowed(cfg)) return;

      final before = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
      _clearClipboard();
      final seqBefore = GetClipboardSequenceNumber();

      await _waitHotkeyReleased(mods, cfg.hotkeyKey);
      _sendCtrl(_vkC);

      final selected = (await _pollClipboardText(seqBefore)).trim();
      if (selected.isEmpty) {
        await Clipboard.setData(ClipboardData(text: before));
        _msgBox(s.hotkeyNoSelection);
        return;
      }

      try {
        final result = await TranslateService.translate(selected, cfg);
        await Clipboard.setData(ClipboardData(text: result));
        _sendCtrl(_vkV);
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (e) {
        final detail = formatProviderError(e, locale: _getLocale());
        _msgBox(s.hotkeyTranslateFailed(detail));
      } finally {
        await Future.delayed(const Duration(milliseconds: 300));
        await Clipboard.setData(ClipboardData(text: before));
      }
    } finally {
      _busy = false;
    }
  }

  // ── Allowed-process filter ─────────────────────────────────────────────────

  static Future<bool> _isAllowed(AppConfig cfg) async {
    if (!cfg.restrictToAllowedProcesses) return true;
    final allowed = cfg.allowedProcesses;
    if (allowed.isEmpty) return false;
    final proc = await ProcessPickerService.foregroundProcess();
    if (proc == null) return false;
    final lower = proc.toLowerCase();
    return allowed.any((a) => a.toLowerCase() == lower);
  }
}
