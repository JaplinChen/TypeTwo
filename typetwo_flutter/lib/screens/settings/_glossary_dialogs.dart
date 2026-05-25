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

  Future<void> _reviewPendingTerms() async {
    final s = context.read<LocaleProvider>().strings;
    final provider = context.read<ConfigProvider>();
    try {
      var pending = await provider.listPendingGlossaryTerms();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> approve(String id) async {
              await provider.approveGlossaryTerm(id);
              pending = await provider.listPendingGlossaryTerms();
              if (ctx.mounted) setDialogState(() {});
            }

            Future<void> reject(String id) async {
              await provider.rejectGlossaryTerm(id);
              pending = await provider.listPendingGlossaryTerms();
              if (ctx.mounted) setDialogState(() {});
            }

            return AlertDialog(
              title: Text(s.glossaryPendingTitle),
              content: SizedBox(
                width: 640,
                child: pending.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(s.glossaryNoPending),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: pending.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final term = pending[index];
                            return ListTile(
                              dense: true,
                              title: Text(term.sourceText),
                              subtitle: Text(
                                  '${term.targetText}\n${term.contextKey}'),
                              isThreeLine: true,
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => reject(term.id),
                                    child: Text(s.glossaryReject),
                                  ),
                                  FilledButton(
                                    onPressed: () => approve(term.id),
                                    child: Text(s.glossaryApprove),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.close),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      _showGlossaryError(e);
    }
  }

  Future<void> _manageGlossaryUsers() async {
    final s = context.read<LocaleProvider>().strings;
    final provider = context.read<ConfigProvider>();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    var role = 'user';
    try {
      var users = await provider.listGlossaryUsers();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> reload() async {
              users = await provider.listGlossaryUsers();
              if (ctx.mounted) setDialogState(() {});
            }

            Future<void> create() async {
              await provider.createGlossaryUser(
                email: emailCtrl.text.trim(),
                password: passwordCtrl.text,
                role: role,
              );
              emailCtrl.clear();
              passwordCtrl.clear();
              await reload();
            }

            Future<void> updateRole(String id, String nextRole) async {
              await provider.updateGlossaryUser(id: id, role: nextRole);
              await reload();
            }

            Future<void> toggleActive(String id, bool isActive) async {
              await provider.updateGlossaryUser(id: id, isActive: isActive);
              await reload();
            }

            return AlertDialog(
              title: Text(s.glossaryUsersTitle),
              content: SizedBox(
                width: 720,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: passwordCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: s.glossarySyncPassword,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: role,
                          items: const [
                            DropdownMenuItem(
                                value: 'user', child: Text('user')),
                            DropdownMenuItem(
                                value: 'editor', child: Text('editor')),
                            DropdownMenuItem(
                                value: 'admin', child: Text('admin')),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => role = value ?? 'user'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: create,
                          child: Text(s.glossaryCreateUser),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final user = users[index];
                          return ListTile(
                            dense: true,
                            title: Text(user.email),
                            subtitle:
                                Text('${s.glossaryUserRole}: ${user.role}'),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                DropdownButton<String>(
                                  value: user.role,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'user', child: Text('user')),
                                    DropdownMenuItem(
                                        value: 'editor', child: Text('editor')),
                                    DropdownMenuItem(
                                        value: 'admin', child: Text('admin')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null && value != user.role) {
                                      updateRole(user.id, value);
                                    }
                                  },
                                ),
                                Switch(
                                  value: user.isActive,
                                  onChanged: (value) =>
                                      toggleActive(user.id, value),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.close),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      _showGlossaryError(e);
    } finally {
      emailCtrl.dispose();
      passwordCtrl.dispose();
    }
  }
}
