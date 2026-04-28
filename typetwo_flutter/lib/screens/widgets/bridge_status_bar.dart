import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';

class WindowsHint extends StatelessWidget {
  const WindowsHint({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
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
            s.windowsHint(hotkey),
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
