part of 'glossary_tab.dart';

extension _GlossaryDialogsExt on _GlossaryTabState {
  Future<void> _edit(String oldSrc, String oldTgt) async {
    final s = context.read<LocaleProvider>().strings;
    final srcCtrl = TextEditingController(text: oldSrc);
    final tgtCtrl = TextEditingController(text: oldTgt);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.glossaryEditTitle),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('editGlossarySourceField'),
                controller: srcCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: s.glossarySrc,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('editGlossaryTargetField'),
                controller: tgtCtrl,
                decoration: InputDecoration(
                  labelText: s.glossaryTgt,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.save),
          ),
        ],
      ),
    );
    final src = srcCtrl.text.trim();
    final tgt = tgtCtrl.text.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      srcCtrl.dispose();
      tgtCtrl.dispose();
    });
    if (confirmed != true) return;
    if (src.isEmpty || !mounted) return;
    try {
      await context.read<ConfigProvider>().saveGlossaryEntry(
            contextKey: _selectedContext,
            sourceText: src,
            targetText: tgt,
            oldSourceText: oldSrc,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.glossaryRemoteSaved)),
      );
    } catch (e) {
      _showGlossaryError(e);
    }
  }

  Future<void> _addPairDialog() async {
    final s = context.read<LocaleProvider>().strings;
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addLangPairTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.addLangPairHint,
            labelText: s.langPairLabel,
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.confirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    final key = ctrl.text.trim();
    if (key.isEmpty || key == _kGlobal) return;
    if (!mounted) return;
    final p = context.read<ConfigProvider>();
    if (p.config.langGlossary.containsKey(key)) {
      // ignore: invalid_use_of_protected_member
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
    // ignore: invalid_use_of_protected_member
    setState(() => _selectedContext = key);
  }

  Future<void> _deletePair() async {
    if (_selectedContext == _kGlobal) return;
    final s = context.read<LocaleProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteLangPairTitle),
        content: Text(s.deleteLangPairConfirm(_selectedContext)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
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
    // ignore: invalid_use_of_protected_member
    setState(() => _selectedContext = _kGlobal);
  }
}
