import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';

class GlossaryTab extends StatefulWidget {
  const GlossaryTab({super.key});

  @override
  State<GlossaryTab> createState() => _GlossaryTabState();
}

class _GlossaryTabState extends State<GlossaryTab> {
  final _srcCtrl = TextEditingController();
  final _tgtCtrl = TextEditingController();
  final _srcFocus = FocusNode();
  final _tgtFocus = FocusNode();

  @override
  void dispose() {
    _srcCtrl.dispose();
    _tgtCtrl.dispose();
    _srcFocus.dispose();
    _tgtFocus.dispose();
    super.dispose();
  }

  void _add() {
    final src = _srcCtrl.text.trim();
    final tgt = _tgtCtrl.text.trim();
    if (src.isEmpty) return;
    final p = context.read<ConfigProvider>();
    final updated = Map<String, String>.from(p.config.glossary)..[src] = tgt;
    p.update(p.config.copyWith(glossary: updated));
    _srcCtrl.clear();
    _tgtCtrl.clear();
    _srcFocus.requestFocus();
  }

  void _delete(String key) {
    final p = context.read<ConfigProvider>();
    final updated = Map<String, String>.from(p.config.glossary)..remove(key);
    p.update(p.config.copyWith(glossary: updated));
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['tsv', 'txt', 'json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    final text = utf8.decode(bytes);
    final name = result.files.first.name.toLowerCase();
    final Map<String, String> entries;
    if (name.endsWith('.json')) {
      entries = (jsonDecode(text) as Map)
          .map((k, v) => MapEntry(k as String, v as String));
    } else {
      entries = Map.fromEntries(
        text.split('\n').where((l) => l.contains('\t')).map((l) {
          final parts = l.split('\t');
          return MapEntry(
              parts[0].trim(), parts.length > 1 ? parts[1].trim() : '');
        }),
      );
    }
    if (!mounted) return;
    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(glossary: {...p.config.glossary, ...entries}));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已匯入 ${entries.length} 筆詞彙')),
    );
  }

  Future<void> _export() async {
    final p = context.read<ConfigProvider>();
    final glossary = p.config.glossary;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '儲存詞彙表',
      fileName: 'glossary.tsv',
    );
    if (path == null) return;
    final tsv = glossary.entries.map((e) => '${e.key}\t${e.value}').join('\n');
    await File(path).writeAsString(tsv);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已儲存 ${glossary.length} 筆詞彙')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(builder: (_, prov, __) {
      final entries = prov.config.glossary.entries.toList();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _srcCtrl,
                  focusNode: _srcFocus,
                  decoration: const InputDecoration(
                    labelText: '原文',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _tgtFocus.requestFocus(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('→',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ),
              Expanded(
                child: TextField(
                  controller: _tgtCtrl,
                  focusNode: _tgtFocus,
                  decoration: const InputDecoration(
                    labelText: '譯文',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: const Text('新增')),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              OutlinedButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('匯入 TSV/JSON'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: entries.isEmpty ? null : _export,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('匯出 TSV'),
              ),
              const Spacer(),
              Text(
                '共 ${entries.length} 筆',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = entries[i];
                return ListTile(
                  dense: true,
                  title: Text(e.key),
                  subtitle: Text(e.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _delete(e.key),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
