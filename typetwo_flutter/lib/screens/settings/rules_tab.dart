import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';

class RulesTab extends StatefulWidget {
  const RulesTab({super.key});

  @override
  State<RulesTab> createState() => _RulesTabState();
}

class _RulesTabState extends State<RulesTab> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<ConfigProvider>().config;
    _ctrl = TextEditingController(
      text: cfg.extraInstructions.join('\n'),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final lines = _ctrl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final p = context.read<ConfigProvider>();
    p.updateQuiet(p.config.copyWith(extraInstructions: lines));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.rulesTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
                hintText: s.rulesHint,
              ),
              onChanged: (_) => _commit(),
            ),
          ),
        ],
      ),
    );
  }
}
