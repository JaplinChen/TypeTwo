import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bridge_provider.dart';
import '../../providers/config_provider.dart';

class BridgeStatusBar extends StatelessWidget {
  const BridgeStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bridge = context.watch<BridgeProvider>();
    final cs = Theme.of(context).colorScheme;

    final (dotColor, label) = switch (bridge.status) {
      BridgeStatus.running => (Colors.green, 'TypeTwo：運行中'),
      BridgeStatus.stopped => (Colors.red.shade400, 'TypeTwo：未啟動'),
      BridgeStatus.unknown => (Colors.grey, 'TypeTwo：偵測中…'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          if (bridge.busy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (bridge.status != BridgeStatus.running)
            TextButton(
              onPressed: bridge.exeFound ? () => _start(context, bridge) : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('▶ 啟動', style: TextStyle(fontSize: 12)),
            )
          else
            TextButton(
              onPressed: () => bridge.stop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('■ 停止', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _start(BuildContext context, BridgeProvider bridge) async {
    try {
      await bridge.start();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('啟動失敗：$e'), backgroundColor: Colors.red),
      );
    }
  }
}

class WindowsHint extends StatelessWidget {
  const WindowsHint({super.key});

  @override
  Widget build(BuildContext context) {
    // Select only hotkey fields — rebuilds only when hotkey changes
    final hotkey = context.select<ConfigProvider, String>(
      (p) => [...p.config.hotkeyModifiers, p.config.hotkeyKey]
          .map((s) => s[0].toUpperCase() + s.substring(1))
          .join('+'),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.keyboard_alt_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Text(
            '任意視窗選取文字後按 $hotkey 直接翻譯並貼回',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
