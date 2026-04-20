import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../platform/hotkey_service.dart';
import '../../providers/config_provider.dart';

class HotkeyTab extends StatefulWidget {
  const HotkeyTab({super.key});

  @override
  State<HotkeyTab> createState() => _HotkeyTabState();
}

class _HotkeyTabState extends State<HotkeyTab> {
  bool _recording = false;
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
    setState(() => _recording = true);
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

    if (mods.isEmpty) return KeyEventResult.handled;

    final keyName = HotkeyService.physicalKeyToString(event.physicalKey);
    if (keyName == null) return KeyEventResult.handled;

    setState(() => _recording = false);

    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(hotkeyModifiers: mods, hotkeyKey: keyName));

    return KeyEventResult.handled;
  }

  String _label(String part) {
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
    final cfg = context.watch<ConfigProvider>().config;
    final parts = [...cfg.hotkeyModifiers, cfg.hotkeyKey];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('全域翻譯快捷鍵', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '選取文字後按下快捷鍵，即可翻譯並貼回。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Wrap(
                spacing: 4,
                children: parts.map((p) => _KeyChip(label: _label(p))).toList(),
              ),
              const SizedBox(width: 16),
              Focus(
                focusNode: _focusNode,
                onKeyEvent: _onKey,
                child: _recording
                    ? FilledButton.tonal(
                        onPressed: () => setState(() => _recording = false),
                        child: const Text('取消'),
                      )
                    : OutlinedButton.icon(
                        onPressed: _startRecording,
                        icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                        label: const Text('重新錄製'),
                      ),
              ),
            ],
          ),
          if (_recording) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  '請按下快捷鍵組合（需包含 Ctrl、Alt 或 Shift）…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          Text(
            '儲存後新快捷鍵立即生效。',
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
