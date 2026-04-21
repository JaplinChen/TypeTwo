import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';

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
    int skipped = 0;
    if (name.endsWith('.json')) {
      final decoded = jsonDecode(text);
      if (decoded is! Map<dynamic, dynamic>) {
        if (mounted) {
          final s = context.read<LocaleProvider>().strings;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.importJsonInvalid), backgroundColor: Colors.red),
          );
        }
        return;
      }
      entries = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    } else {
      final lines = text.split('\n');
      skipped = lines.where((l) => l.trim().isNotEmpty && !l.contains('\t')).length;
      entries = Map.fromEntries(
        lines.where((l) => l.contains('\t')).map((l) {
          final parts = l.split('\t');
          return MapEntry(
              parts[0].trim(), parts.length > 1 ? parts[1].trim() : '');
        }),
      );
    }
    if (!mounted) return;
    final s = context.read<LocaleProvider>().strings;
    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(glossary: {...p.config.glossary, ...entries}));
    final msg = skipped > 0
        ? '${s.importedEntries(entries.length)} · ${s.skippedLines(skipped)}'
        : s.importedEntries(entries.length);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _export() async {
    final s = context.read<LocaleProvider>().strings;
    final p = context.read<ConfigProvider>();
    final glossary = p.config.glossary;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: s.saveGlossaryDialog,
      fileName: 'glossary.tsv',
    );
    if (path == null) return;
    final tsv = glossary.entries.map((e) => '${e.key}\t${e.value}').join('\n');
    await File(path).writeAsString(tsv);
    if (!mounted) return;
    final s2 = context.read<LocaleProvider>().strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s2.savedEntries(glossary.length))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
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
                  decoration: InputDecoration(
                    labelText: s.glossarySrc,
                    border: const OutlineInputBorder(),
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
                  decoration: InputDecoration(
                    labelText: s.glossaryTgt,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: Text(s.add)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              OutlinedButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.upload_file, size: 16),
                label: Text(s.importTsv),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: entries.isEmpty ? null : _export,
                icon: const Icon(Icons.download, size: 16),
                label: Text(s.exportTsv),
              ),
              const Spacer(),
              Text(
                s.glossaryCount(entries.length),
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
