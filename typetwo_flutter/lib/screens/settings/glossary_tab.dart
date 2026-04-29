import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';

const _kGlobal = 'global';

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
  String _selectedContext = _kGlobal;

  @override
  void dispose() {
    _srcCtrl.dispose();
    _tgtCtrl.dispose();
    _srcFocus.dispose();
    _tgtFocus.dispose();
    super.dispose();
  }

  Map<String, String> _currentGlossary(ConfigProvider p) {
    if (_selectedContext == _kGlobal) return p.config.glossary;
    return p.config.langGlossary[_selectedContext] ?? {};
  }

  void _updateGlossary(ConfigProvider p, Map<String, String> updated) {
    if (_selectedContext == _kGlobal) {
      p.update(p.config.copyWith(glossary: updated));
    } else {
      final langG = {
        ...{
          for (final e in p.config.langGlossary.entries)
            e.key: Map<String, String>.from(e.value)
        },
        _selectedContext: updated,
      };
      p.update(p.config.copyWith(langGlossary: langG));
    }
  }

  void _add() {
    final src = _srcCtrl.text.trim();
    final tgt = _tgtCtrl.text.trim();
    if (src.isEmpty) return;
    final p = context.read<ConfigProvider>();
    _updateGlossary(p, {..._currentGlossary(p), src: tgt});
    _srcCtrl.clear();
    _tgtCtrl.clear();
    _srcFocus.requestFocus();
  }

  void _delete(String key) {
    final p = context.read<ConfigProvider>();
    final updated = Map<String, String>.from(_currentGlossary(p))..remove(key);
    _updateGlossary(p, updated);
  }

  Future<void> _addPairDialog() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增語言對'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '例：繁體中文-越南文',
            labelText: '語言對',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('確定')),
        ],
      ),
    );
    if (confirmed != true) return;
    final key = ctrl.text.trim();
    if (key.isEmpty || key == _kGlobal) return;
    if (!mounted) return;
    final p = context.read<ConfigProvider>();
    if (p.config.langGlossary.containsKey(key)) {
      setState(() => _selectedContext = key);
      return;
    }
    final langG = {
      ...{
        for (final e in p.config.langGlossary.entries)
          e.key: Map<String, String>.from(e.value)
      },
      key: <String, String>{},
    };
    p.update(p.config.copyWith(langGlossary: langG));
    setState(() => _selectedContext = key);
  }

  Future<void> _deletePair() async {
    if (_selectedContext == _kGlobal) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除語言對'),
        content: Text('確定刪除「$_selectedContext」的詞彙表？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final p = context.read<ConfigProvider>();
    final langG = Map<String, Map<String, String>>.from(p.config.langGlossary)
      ..remove(_selectedContext);
    p.update(p.config.copyWith(langGlossary: langG));
    setState(() => _selectedContext = _kGlobal);
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
          return MapEntry(parts[0].trim(), parts.length > 1 ? parts[1].trim() : '');
        }),
      );
    }
    if (!mounted) return;
    final s = context.read<LocaleProvider>().strings;
    final p = context.read<ConfigProvider>();
    _updateGlossary(p, {..._currentGlossary(p), ...entries});
    final msg = skipped > 0
        ? '${s.importedEntries(entries.length)} · ${s.skippedLines(skipped)}'
        : s.importedEntries(entries.length);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _export() async {
    final s = context.read<LocaleProvider>().strings;
    final p = context.read<ConfigProvider>();
    final glossary = _currentGlossary(p);
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
      final contextOptions = [
        _kGlobal,
        ...prov.config.langGlossary.keys.toList()..sort(),
      ];
      if (!contextOptions.contains(_selectedContext)) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _selectedContext = _kGlobal));
      }
      final entries = _currentGlossary(prov).entries.toList();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              const Text('語言對：', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: contextOptions.contains(_selectedContext) ? _selectedContext : _kGlobal,
                isDense: true,
                items: contextOptions
                    .map((k) => DropdownMenuItem(
                          value: k,
                          child: Text(k == _kGlobal ? '全域 (Global)' : k,
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedContext = v ?? _kGlobal),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: '新增語言對',
                onPressed: _addPairDialog,
              ),
              if (_selectedContext != _kGlobal)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                  tooltip: '刪除此語言對',
                  onPressed: _deletePair,
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                child: Text('→', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
