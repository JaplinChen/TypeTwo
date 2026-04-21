import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../platform/hotkey_service.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';

class HotkeyTab extends StatefulWidget {
  const HotkeyTab({super.key});

  @override
  State<HotkeyTab> createState() => _HotkeyTabState();
}

class _HotkeyTabState extends State<HotkeyTab> {
  bool _recording = false;
  bool _noModifier = false;
  final FocusNode _focusNode = FocusNode();

  static final _modifierKeys = {
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  };

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _recording = true;
      _noModifier = false;
    });
    _focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (!_recording) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    if (_modifierKeys.contains(event.logicalKey)) return KeyEventResult.handled;

    final hw = HardwareKeyboard.instance;
    final mods = <String>[
      if (hw.isControlPressed) 'ctrl',
      if (hw.isAltPressed) 'alt',
      if (hw.isShiftPressed) 'shift',
      if (hw.isMetaPressed) 'meta',
    ];

    if (mods.isEmpty) {
      setState(() => _noModifier = true);
      return KeyEventResult.handled;
    }
    setState(() => _noModifier = false);

    final keyName = HotkeyService.physicalKeyToString(event.physicalKey);
    if (keyName == null) return KeyEventResult.handled;

    setState(() => _recording = false);

    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(hotkeyModifiers: mods, hotkeyKey: keyName));

    return KeyEventResult.handled;
  }

  String _keyLabel(String part) {
    const labels = {
      'ctrl': 'Ctrl', 'alt': 'Alt', 'shift': 'Shift', 'meta': 'Win',
      'enter': 'Enter', 'space': 'Space', 'tab': 'Tab',
      'escape': 'Esc', 'backspace': 'Backspace', 'delete': 'Del',
      'insert': 'Ins', 'home': 'Home', 'end': 'End',
      'pageup': 'PgUp', 'pagedown': 'PgDn',
      'arrowup': '↑', 'arrowdown': '↓', 'arrowleft': '←', 'arrowright': '→',
    };
    return labels[part] ?? part.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    final hotkeyStr = context.select<ConfigProvider, String>(
      (p) => [...p.config.hotkeyModifiers, p.config.hotkeyKey].join(','),
    );
    final parts = hotkeyStr.split(',');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.hotkeyTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(s.hotkeyDesc, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          Row(
            children: [
              Wrap(
                spacing: 4,
                children:
                    parts.map((p) => _KeyChip(label: _keyLabel(p))).toList(),
              ),
              const SizedBox(width: 16),
              Focus(
                focusNode: _focusNode,
                onKeyEvent: _onKey,
                child: _recording
                    ? FilledButton.tonal(
                        onPressed: () => setState(() => _recording = false),
                        child: Text(s.cancel),
                      )
                    : OutlinedButton.icon(
                        onPressed: _startRecording,
                        icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                        label: Text(s.reRecord),
                      ),
              ),
            ],
          ),
          if (_recording) ...[
            const SizedBox(height: 12),
            if (_noModifier)
              Text(
                s.noModifierWarning,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              )
            else
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(s.pressHotkey, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
          ],
          const SizedBox(height: 32),
          Text(
            s.hotkeyEffect,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  const _KeyChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
