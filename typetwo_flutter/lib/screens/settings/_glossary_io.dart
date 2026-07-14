part of 'glossary_tab.dart';

extension _GlossaryIoExt on _GlossaryTabState {
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
            SnackBar(
                content: Text(s.importJsonInvalid),
                backgroundColor: Colors.red),
          );
        }
        return;
      }
      entries =
          decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    } else {
      final lines = text.split('\n');
      skipped =
          lines.where((l) => l.trim().isNotEmpty && !l.contains('\t')).length;
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
    final current = _currentGlossary(p);
    final conflicts = entries.entries
        .where((e) => current.containsKey(e.key) && current[e.key] != e.value)
        .length;
    _updateGlossary(p, {...current, ...entries});
    final parts = [s.importedEntries(entries.length)];
    if (skipped > 0) parts.add(s.skippedLines(skipped));
    if (conflicts > 0) parts.add(s.glossaryConflicts(conflicts));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(parts.join(' · '))));
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
}
