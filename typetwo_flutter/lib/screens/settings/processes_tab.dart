import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';

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
    final s = context.watch<LocaleProvider>().strings;
    return Consumer<ConfigProvider>(builder: (_, prov, __) {
      final procs = prov.config.allowedProcesses;
      final hotkey = [...prov.config.hotkeyModifiers, prov.config.hotkeyKey]
          .map((part) => part.isEmpty ? part : part[0].toUpperCase() + part.substring(1))
          .join('+');
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.processesTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              s.processesDesc(hotkey),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _entryCtrl,
                  decoration: InputDecoration(
                    labelText: s.processName,
                    hintText: s.processHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: Text(s.add)),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: procs.isEmpty
                  ? Center(
                      child: Text(
                        s.processesEmpty,
                        style: const TextStyle(color: Colors.grey),
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
