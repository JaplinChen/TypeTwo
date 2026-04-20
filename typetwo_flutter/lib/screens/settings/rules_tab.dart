import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';

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
    p.update(p.config.copyWith(extraInstructions: lines));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '翻譯規則（翻譯時強制遵守，每行一條）',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
                hintText: '每行輸入一條規則…',
              ),
              onChanged: (_) => _commit(),
            ),
          ),
        ],
      ),
    );
  }
}
