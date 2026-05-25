import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';
part '_glossary_dialogs.dart';
part '_glossary_io.dart';
part '_glossary_sync_panel.dart';
part '_glossary_toolbar.dart';

const _kGlobal = 'global';

class GlossaryTab extends StatefulWidget {
  const GlossaryTab({super.key});

  @override
  State<GlossaryTab> createState() => _GlossaryTabState();
}

class _GlossaryTabState extends State<GlossaryTab> {
  final _srcCtrl = TextEditingController();
  final _tgtCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _syncUrlCtrl = TextEditingController();
  final _syncEmailCtrl = TextEditingController();
  final _syncPasswordCtrl = TextEditingController();
  final _srcFocus = FocusNode();
  final _tgtFocus = FocusNode();
  String _selectedContext = _kGlobal;
  String _searchQuery = '';
  bool _syncControllersSeeded = false;
  bool _syncing = false;
  bool _loggingIn = false;

  @override
  void dispose() {
    _srcCtrl.dispose();
    _tgtCtrl.dispose();
    _searchCtrl.dispose();
    _syncUrlCtrl.dispose();
    _syncEmailCtrl.dispose();
    _syncPasswordCtrl.dispose();
    _srcFocus.dispose();
    _tgtFocus.dispose();
    super.dispose();
  }

  void _seedSyncControllers(ConfigProvider p) {
    if (_syncControllersSeeded) return;
    _syncUrlCtrl.text = p.config.glossarySyncUrl;
    _syncEmailCtrl.text = p.config.glossarySyncEmail;
    _syncControllersSeeded = true;
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

  Future<void> _add() async {
    final src = _srcCtrl.text.trim();
    final tgt = _tgtCtrl.text.trim();
    if (src.isEmpty) return;
    final p = context.read<ConfigProvider>();
    try {
      await p.saveGlossaryEntry(
        contextKey: _selectedContext,
        sourceText: src,
        targetText: tgt,
      );
      _srcCtrl.clear();
      _tgtCtrl.clear();
      _srcFocus.requestFocus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                context.read<LocaleProvider>().strings.glossaryRemoteSaved)),
      );
    } catch (e) {
      _showGlossaryError(e);
    }
  }

  Future<void> _delete(String key) async {
    try {
      await context.read<ConfigProvider>().deleteGlossaryEntry(
            contextKey: _selectedContext,
            sourceText: key,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                context.read<LocaleProvider>().strings.glossaryRemoteDeleted)),
      );
    } catch (e) {
      _showGlossaryError(e);
    }
  }

  List<MapEntry<String, String>> _filterEntries(
    List<MapEntry<String, String>> entries,
  ) {
    final terms = _searchQuery
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    if (terms.isEmpty) return entries;
    return entries.where((entry) {
      final text = '${entry.key}\n${entry.value}'.toLowerCase();
      return terms.every(text.contains);
    }).toList();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _syncRemoteGlossary() async {
    final p = context.read<ConfigProvider>();
    setState(() => _syncing = true);
    try {
      await p.syncGlossaryFromRemote();
      if (!mounted) return;
      final s = context.read<LocaleProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.glossarySyncDone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('同步失敗：$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _loginGlossaryRemote() async {
    final p = context.read<ConfigProvider>();
    setState(() => _loggingIn = true);
    try {
      await p.loginGlossaryRemote(
        _syncEmailCtrl.text.trim(),
        _syncPasswordCtrl.text,
      );
      _syncPasswordCtrl.clear();
      if (!mounted) return;
      final s = context.read<LocaleProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.glossaryLoginDone)),
      );
    } catch (e) {
      _showGlossaryError(e);
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  Future<void> _logoutGlossaryRemote() async {
    await context.read<ConfigProvider>().logoutGlossaryRemote();
    _syncPasswordCtrl.clear();
  }

  void _showGlossaryError(Object error) {
    if (!mounted) return;
    final s = context.read<LocaleProvider>().strings;
    final isPending = error is GlossaryPendingException;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPending ? s.glossarySavedPending : '詞彙表操作失敗：$error'),
        backgroundColor: isPending ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    return Consumer<ConfigProvider>(builder: (_, prov, __) {
      _seedSyncControllers(prov);
      final contextOptions = [
        _kGlobal,
        ...prov.config.langGlossary.keys.toList()..sort(),
      ];
      if (!contextOptions.contains(_selectedContext)) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _selectedContext = _kGlobal));
      }
      final entries = _currentGlossary(prov).entries.toList();
      final visibleEntries = _filterEntries(entries);
      final isSearching = _searchQuery.trim().isNotEmpty;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Text('${s.langPairLabel}：', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: contextOptions.contains(_selectedContext)
                    ? _selectedContext
                    : _kGlobal,
                isDense: true,
                items: contextOptions
                    .map((k) => DropdownMenuItem(
                          value: k,
                          child: Text(k == _kGlobal ? s.glossaryGlobalLabel : k,
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedContext = v ?? _kGlobal),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: s.addLangPairTooltip,
                onPressed: _addPairDialog,
              ),
              if (_selectedContext != _kGlobal)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 20, color: Colors.red),
                  tooltip: s.deleteLangPairTooltip,
                  onPressed: _deletePair,
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _GlossarySyncPanel(
              s: s,
              syncUrlCtrl: _syncUrlCtrl,
              syncEmailCtrl: _syncEmailCtrl,
              syncPasswordCtrl: _syncPasswordCtrl,
              isSyncing: _syncing,
              isLoggingIn: _loggingIn,
              isLoggedIn: prov.config.glossarySyncToken.trim().isNotEmpty,
              role: prov.config.glossarySyncRole,
              canReview:
                  {'admin', 'editor'}.contains(prov.config.glossarySyncRole),
              canManageUsers: prov.config.glossarySyncRole == 'admin',
              lastSyncedAt: prov.config.glossaryLastSyncedAt,
              pendingCount: prov.config.glossaryPendingChanges.length,
              onUrlChanged: (value) => prov.updateQuiet(
                prov.config.copyWith(glossarySyncUrl: value.trim()),
              ),
              onEmailChanged: (value) => prov.updateQuiet(
                prov.config.copyWith(glossarySyncEmail: value.trim()),
              ),
              onLogin: _loginGlossaryRemote,
              onLogout: _logoutGlossaryRemote,
              onSync: _syncRemoteGlossary,
              onReview: _reviewPendingTerms,
              onManageUsers: _manageGlossaryUsers,
            ),
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
          _GlossaryToolbar(
            s: s,
            searchCtrl: _searchCtrl,
            isSearching: isSearching,
            searchQuery: _searchQuery,
            totalCount: entries.length,
            visibleCount: visibleEntries.length,
            exportEnabled: entries.isNotEmpty,
            onImport: _import,
            onExport: _export,
            onClearSearch: _clearSearch,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: visibleEntries.isEmpty
                ? Center(
                    child: Text(
                      isSearching ? s.glossaryNoMatches : s.glossaryEmpty,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleEntries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = visibleEntries[i];
                      return ListTile(
                        dense: true,
                        title: Text(e.key),
                        subtitle: Text(e.value),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: s.glossaryEditTitle,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _edit(e.key, e.value),
                            ),
                            IconButton(
                              tooltip: s.delete,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _delete(e.key),
                            ),
                          ],
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
