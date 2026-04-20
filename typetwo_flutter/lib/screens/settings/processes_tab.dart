import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';

// Windows-only tab: restrict hotkey to specific process names
class ProcessesTab extends StatefulWidget {
  const ProcessesTab({super.key});

  @override
  State<ProcessesTab> createState() => _ProcessesTabState();
}

class _ProcessesTabState extends State<ProcessesTab> {
  final _entryCtrl = TextEditingController();

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final val = _entryCtrl.text.trim();
    if (val.isEmpty) return;
    final p = context.read<ConfigProvider>();
    if (!p.config.allowedProcesses.contains(val)) {
      p.update(p.config.copyWith(
        allowedProcesses: [...p.config.allowedProcesses, val],
      ));
    }
    _entryCtrl.clear();
  }

  void _delete(String proc) {
    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(
      allowedProcesses:
          p.config.allowedProcesses.where((x) => x != proc).toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(builder: (_, prov, __) {
      final procs = prov.config.allowedProcesses;
      final hotkey = [...prov.config.hotkeyModifiers, prov.config.hotkeyKey]
          .map((s) => s[0].toUpperCase() + s.substring(1))
          .join('+');
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '限定觸發翻譯的程式（留空 = 全部允許）',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '只有列表中的程式在前景時，$hotkey 才會觸發翻譯',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _entryCtrl,
                  decoration: const InputDecoration(
                    labelText: '程式名稱',
                    hintText: '例：Teams.exe',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: const Text('新增')),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: procs.isEmpty
                  ? const Center(
                      child: Text(
                        '列表為空，所有視窗均可觸發翻譯',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: procs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.apps, size: 18),
                        title: Text(procs[i]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _delete(procs[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }
}
