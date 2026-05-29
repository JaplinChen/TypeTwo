import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_config.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/glossary_sync_health_service.dart';
import '../../services/glossary_remote_service.dart';

class CloudSyncTab extends StatefulWidget {
  const CloudSyncTab({super.key});

  @override
  State<CloudSyncTab> createState() => _CloudSyncTabState();
}

class _CloudSyncTabState extends State<CloudSyncTab> {
  final _urlCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _localPathCtrl = TextEditingController();
  final _webDavUrlCtrl = TextEditingController();
  final _webDavUserCtrl = TextEditingController();
  final _webDavPasswordCtrl = TextEditingController();
  bool _seeded = false;
  bool _loggingIn = false;
  bool _syncing = false;
  bool _testingConnection = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _localPathCtrl.dispose();
    _webDavUrlCtrl.dispose();
    _webDavUserCtrl.dispose();
    _webDavPasswordCtrl.dispose();
    super.dispose();
  }

  void _seed(ConfigProvider provider) {
    if (_seeded) return;
    final sync = provider.config.glossarySync;
    _urlCtrl.text = sync.url;
    _emailCtrl.text = sync.email;
    _localPathCtrl.text = sync.localPath;
    _webDavUrlCtrl.text = sync.webDavUrl;
    _webDavUserCtrl.text = sync.webDavUser;
    _webDavPasswordCtrl.text = sync.webDavPassword;
    _seeded = true;
  }

  Future<void> _chooseFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: context.read<LocaleProvider>().strings.glossarySyncLocalPath,
    );
    if (path == null || !mounted) return;
    _localPathCtrl.text = path;
    final provider = context.read<ConfigProvider>();
    provider.update(
      provider.config.copyWith(glossarySyncLocalPath: path),
    );
  }

  Future<void> _login() async {
    final provider = context.read<ConfigProvider>();
    setState(() => _loggingIn = true);
    try {
      final mustChangePassword = await provider.loginGlossaryRemote(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (mustChangePassword && mounted) {
        final changed = await _showChangePasswordDialog(
          currentPassword: _passwordCtrl.text,
          requiredChange: true,
        );
        if (!changed) return;
      }
      _passwordCtrl.clear();
      if (!mounted) return;
      final s = context.read<LocaleProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.glossaryLoginDone)),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  Future<bool> _showChangePasswordDialog({
    required String currentPassword,
    required bool requiredChange,
  }) async {
    final currentCtrl = TextEditingController(text: currentPassword);
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var saving = false;
    var error = '';
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: !requiredChange,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> submit() async {
              if (newCtrl.text.length < 6) {
                setDialogState(() => error = '新密碼至少需要 6 個字元。');
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                setDialogState(() => error = '兩次輸入的新密碼不一致。');
                return;
              }
              setDialogState(() {
                saving = true;
                error = '';
              });
              try {
                await context
                    .read<ConfigProvider>()
                    .changeGlossaryRemotePassword(
                      currentPassword: currentCtrl.text,
                      newPassword: newCtrl.text,
                    );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (!ctx.mounted) return;
                setDialogState(() {
                  saving = false;
                  error = e.toString();
                });
              }
            }

            return AlertDialog(
              title: const Text('變更密碼'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (requiredChange)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('此帳號必須先變更密碼才能繼續使用。'),
                        ),
                      ),
                    TextField(
                      key: const ValueKey(
                        'cloudSyncChangePasswordCurrentField',
                      ),
                      controller: currentCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '目前密碼',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('cloudSyncChangePasswordNewField'),
                      controller: newCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '新密碼',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey(
                        'cloudSyncChangePasswordConfirmField',
                      ),
                      controller: confirmCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '確認新密碼',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!requiredChange)
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx, false),
                    child: const Text('取消'),
                  ),
                FilledButton(
                  key: const ValueKey('cloudSyncChangePasswordSaveButton'),
                  onPressed: saving ? null : submit,
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('儲存'),
                ),
              ],
            );
          },
        ),
      );
      return result == true;
    } finally {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    }
  }

  Future<void> _logout() async {
    await context.read<ConfigProvider>().logoutGlossaryRemote();
    _passwordCtrl.clear();
  }

  Future<void> _sync() async {
    final provider = context.read<ConfigProvider>();
    setState(() => _syncing = true);
    try {
      await provider.syncGlossaryFromRemote();
      if (!mounted) return;
      final s = context.read<LocaleProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.glossarySyncDone)),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _testConnection() async {
    final provider = context.read<ConfigProvider>();
    setState(() => _testingConnection = true);
    try {
      final result = await GlossarySyncHealthService().check(provider.config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.ok ? null : Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }

  Future<void> _restoreBackupDialog() async {
    final s = context.read<LocaleProvider>().strings;
    final provider = context.read<ConfigProvider>();
    try {
      final backups = await provider.listGlossarySyncBackups();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.glossaryBackupsTitle),
          content: SizedBox(
            width: 640,
            child: backups.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s.glossaryNoBackups),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: backups.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final backup = backups[index];
                        return ListTile(
                          dense: true,
                          title: Text(backup.createdAt),
                          subtitle: Text(s.glossaryBackupTermCount(
                            backup.termCount,
                          )),
                          trailing: FilledButton(
                            onPressed: () async {
                              await provider.restoreGlossarySyncBackup(
                                backup.path,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(s.glossaryRestoreDone)),
                              );
                            },
                            child: Text(s.glossaryRestore),
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
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _importRemoteGlossary() async {
    final s = context.read<LocaleProvider>().strings;
    final provider = context.read<ConfigProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) return;
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw GlossaryRemoteException(s.importJsonInvalid);
      }
      var payload = GlossaryImportPayload.fromJson(decoded);
      if (payload.termCount == 0) {
        throw const GlossaryRemoteException(
          '匯入檔沒有 glossary 或 langGlossary 詞彙。',
        );
      }
      final conflictStrategy = await _showImportConflictStrategyDialog();
      if (conflictStrategy == null) return;
      payload = payload.copyWith(conflictStrategy: conflictStrategy);
      final preview = await provider.previewGlossaryImport(payload);
      if (!mounted) return;
      final confirmed = await _showImportPreviewDialog(preview);
      if (confirmed != true) return;
      final imported = await provider.importGlossaryRemote(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.glossaryImportDone(imported.imported, imported.updated),
          ),
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<String?> _showImportConflictStrategyDialog() {
    final s = context.read<LocaleProvider>().strings;
    var strategy = 'overwrite';
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.glossaryImportConflictStrategyTitle),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'overwrite',
                  groupValue: strategy,
                  title: Text(s.glossaryImportOverwrite),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => strategy = value);
                    }
                  },
                ),
                RadioListTile<String>(
                  value: 'keepExisting',
                  groupValue: strategy,
                  title: Text(s.glossaryImportKeepExisting),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => strategy = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, strategy),
              child: Text(s.confirm),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportRemoteGlossary() async {
    final s = context.read<LocaleProvider>().strings;
    final provider = context.read<ConfigProvider>();
    try {
      final status = await _showExportStatusDialog();
      if (status == null) return;
      final terms = await provider.listGlossaryTermsForExport(
        status: status == 'all' ? null : status,
      );
      if (!mounted) return;
      final path = await FilePicker.platform.saveFile(
        dialogTitle: s.glossaryExportRemoteTitle,
        fileName: 'typetwo_glossary_$status.json',
      );
      if (path == null) return;
      final payload = _remoteExportPayload(status, terms);
      await File(path).writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.savedEntries(terms.length))),
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<String?> _showExportStatusDialog() {
    final s = context.read<LocaleProvider>().strings;
    var status = 'approved';
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.glossaryExportRemoteTitle),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in ['approved', 'pending', 'rejected', 'all'])
                  RadioListTile<String>(
                    value: option,
                    groupValue: status,
                    title: Text(_exportStatusLabel(s, option)),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => status = value);
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, status),
              child: Text(s.exportTsv),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showImportPreviewDialog(
    GlossaryImportPreviewResult preview,
  ) {
    final s = context.read<LocaleProvider>().strings;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.glossaryImportPreviewTitle),
        content: SizedBox(
          width: 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(s.glossaryImportImported(preview.imported))),
                  Chip(label: Text(s.glossaryImportUpdated(preview.updated))),
                  Chip(
                    label: Text(s.glossaryImportUnchanged(preview.unchanged)),
                  ),
                  Chip(label: Text(s.glossaryImportSkipped(preview.skipped))),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: preview.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = preview.items[index];
                    final current = item.currentTargetText?.trim();
                    final message = item.message?.trim();
                    return ListTile(
                      dense: true,
                      leading: _ImportActionIcon(action: item.action),
                      title: Text(
                        '${_importActionLabel(s, item.action)} · '
                        '${item.sourceText}',
                      ),
                      subtitle: Text(
                        [
                          '${item.contextKey} → ${item.targetText}',
                          if (current != null && current.isNotEmpty)
                            '${s.glossaryImportCurrentTarget}：$current',
                          if (item.currentStatus != null)
                            '${s.glossaryImportCurrentStatus}：'
                                '${item.currentStatus}',
                          if (message != null && message.isNotEmpty) message,
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
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
            key: const ValueKey('cloudSyncImportConfirmButton'),
            onPressed: preview.writableCount == 0
                ? null
                : () => Navigator.pop(ctx, true),
            child: Text(s.glossaryImportConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewPendingTerms() async {
    final s = context.read<LocaleProvider>().strings;
    final provider = context.read<ConfigProvider>();
    final searchCtrl = TextEditingController();
    try {
      var pending = await provider.listPendingGlossaryTerms();
      if (!mounted) return;
      var processing = false;
      final selectedIds = <String>{};
      var searchQuery = '';
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            List<GlossaryRemoteTerm> filteredPending() {
              final terms = searchQuery
                  .trim()
                  .toLowerCase()
                  .split(RegExp(r'\s+'))
                  .where((term) => term.isNotEmpty)
                  .toList();
              if (terms.isEmpty) return pending;
              return pending.where((term) {
                final text = '${term.sourceText}\n${term.targetText}\n'
                        '${term.contextKey}'
                    .toLowerCase();
                return terms.every(text.contains);
              }).toList();
            }

            Future<void> reload() async {
              pending = await provider.listPendingGlossaryTerms();
              selectedIds.removeWhere(
                (id) => !pending.any((term) => term.id == id),
              );
              if (ctx.mounted) setDialogState(() {});
            }

            Future<void> approve(String id) async {
              await provider.approveGlossaryTerm(id);
              selectedIds.remove(id);
              await reload();
            }

            Future<void> reject(String id) async {
              final reason = await _showRejectReasonDialog(s);
              if (reason == null) return;
              await provider.rejectGlossaryTerm(id, reason: reason);
              selectedIds.remove(id);
              await reload();
            }

            Future<void> approveSelected() async {
              if (selectedIds.isEmpty) return;
              setDialogState(() => processing = true);
              await provider.approveGlossaryTerms(selectedIds);
              processing = false;
              await reload();
            }

            Future<void> rejectSelected() async {
              if (selectedIds.isEmpty) return;
              final reason = await _showRejectReasonDialog(s);
              if (reason == null) return;
              setDialogState(() => processing = true);
              await provider.rejectGlossaryTerms(selectedIds, reason: reason);
              processing = false;
              await reload();
            }

            final filtered = filteredPending();
            return AlertDialog(
              title: Text(s.glossaryPendingTitle),
              content: SizedBox(
                width: 760,
                child: pending.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(s.glossaryNoPending),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            key: const ValueKey('pendingGlossarySearchField'),
                            controller: searchCtrl,
                            decoration: InputDecoration(
                              labelText: s.glossaryPendingSearch,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        searchCtrl.clear();
                                        setDialogState(
                                          () => searchQuery = '',
                                        );
                                      },
                                    ),
                            ),
                            onChanged: (value) =>
                                setDialogState(() => searchQuery = value),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(s
                                  .glossaryPendingSelected(selectedIds.length)),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: filtered.isEmpty || processing
                                    ? null
                                    : () => setDialogState(() {
                                          selectedIds.addAll(
                                            filtered.map((term) => term.id),
                                          );
                                        }),
                                icon: const Icon(Icons.select_all, size: 16),
                                label: Text(s.glossarySelectFiltered),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: selectedIds.isEmpty || processing
                                    ? null
                                    : () => setDialogState(
                                          selectedIds.clear,
                                        ),
                                icon: const Icon(Icons.clear_all, size: 16),
                                label: Text(s.glossaryClearSelection),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 420),
                            child: filtered.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(s.glossaryNoPending),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (_, index) {
                                      final term = filtered[index];
                                      final selected =
                                          selectedIds.contains(term.id);
                                      return CheckboxListTile(
                                        key: ValueKey(
                                          'pendingGlossaryTerm_${term.id}',
                                        ),
                                        dense: true,
                                        value: selected,
                                        onChanged: processing
                                            ? null
                                            : (value) => setDialogState(() {
                                                  if (value == true) {
                                                    selectedIds.add(term.id);
                                                  } else {
                                                    selectedIds.remove(term.id);
                                                  }
                                                }),
                                        title: Text(term.sourceText),
                                        subtitle: Text(
                                          '${term.targetText}\n'
                                          '${term.contextKey}',
                                        ),
                                        isThreeLine: true,
                                        secondary: Wrap(
                                          spacing: 8,
                                          children: [
                                            OutlinedButton(
                                              onPressed: processing
                                                  ? null
                                                  : () => reject(term.id),
                                              child: Text(s.glossaryReject),
                                            ),
                                            OutlinedButton(
                                              key: ValueKey(
                                                'pendingGlossaryHistory_'
                                                '${term.id}',
                                              ),
                                              onPressed: processing
                                                  ? null
                                                  : () async {
                                                      final restored =
                                                          await _showTermHistory(
                                                        term,
                                                      );
                                                      if (restored) {
                                                        await reload();
                                                      }
                                                    },
                                              child: Text(s.glossaryHistory),
                                            ),
                                            FilledButton(
                                              onPressed: processing
                                                  ? null
                                                  : () => approve(term.id),
                                              child: Text(s.glossaryApprove),
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
                OutlinedButton(
                  onPressed:
                      selectedIds.isEmpty || processing ? null : rejectSelected,
                  child: Text(s.glossaryRejectSelected),
                ),
                FilledButton(
                  onPressed: selectedIds.isEmpty || processing
                      ? null
                      : approveSelected,
                  child: processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(s.glossaryApproveSelected),
                ),
                TextButton(
                  onPressed: processing ? null : () => Navigator.pop(ctx),
                  child: Text(s.close),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      searchCtrl.dispose();
    }
  }

  Future<bool> _showTermHistory(GlossaryRemoteTerm term) async {
    final s = context.read<LocaleProvider>().strings;
    final provider = context.read<ConfigProvider>();
    try {
      final history = await provider.listGlossaryTermHistory(term.id);
      if (!mounted) return false;
      var restored = false;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${s.glossaryHistory}：${term.sourceText}'),
          content: SizedBox(
            width: 680,
            child: history.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s.glossaryNoHistory),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final item = history[index];
                        final reason = item.reason?.trim();
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${item.operation} · ${item.status} · '
                            'v${item.version}',
                          ),
                          subtitle: Text(
                            [
                              '${item.sourceText} → ${item.targetText}',
                              item.contextKey,
                              if (reason != null && reason.isNotEmpty)
                                '${s.glossaryHistoryReason}：$reason',
                              if (item.changedAt != null)
                                _formatDateTime(item.changedAt!),
                            ].join('\n'),
                          ),
                          isThreeLine: true,
                          trailing: TextButton.icon(
                            onPressed: () async {
                              await provider.restoreGlossaryTermHistory(
                                id: term.id,
                                historyId: item.id,
                              );
                              restored = true;
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.restore_outlined, size: 16),
                            label: Text(s.glossaryRestoreHistory),
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
        ),
      );
      return restored;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<String?> _showRejectReasonDialog(AppStrings s) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _RejectReasonDialog(s: s),
    );
  }

  Future<void> _manageUsers() async {
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

            Future<void> resetPassword(String id) async {
              final temporaryPassword =
                  await provider.resetGlossaryUserPassword(id);
              await reload();
              if (!ctx.mounted) return;
              await showDialog<void>(
                context: ctx,
                builder: (passwordCtx) => AlertDialog(
                  title: const Text('重設密碼'),
                  content: SelectableText(
                    '臨時密碼：$temporaryPassword\n\n'
                    '使用者下次登入後需要變更密碼。',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(passwordCtx),
                      child: Text(s.close),
                    ),
                  ],
                ),
              );
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
                              value: 'editor',
                              child: Text('editor'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('admin'),
                            ),
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
                            subtitle: Text(_userSummary(s, user)),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                DropdownButton<String>(
                                  value: user.role,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'user',
                                      child: Text('user'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'editor',
                                      child: Text('editor'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'admin',
                                      child: Text('admin'),
                                    ),
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
                                OutlinedButton(
                                  onPressed: () => resetPassword(user.id),
                                  child: const Text('重設密碼'),
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
      _showError(e);
    } finally {
      emailCtrl.dispose();
      passwordCtrl.dispose();
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('雲端同步失敗：$error'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    return Consumer<ConfigProvider>(
      builder: (_, provider, __) {
        _seed(provider);
        final sync = provider.config.glossarySync;
        final target = GlossarySyncTargets.normalize(sync.target);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              s.glossaryCloudSync,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              s.glossaryCloudSyncHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('cloudSyncTargetField'),
                    value: target,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: s.glossarySyncTarget,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final t in provider.config.glossarySyncTargetOrder)
                        DropdownMenuItem(
                          value: t,
                          child: Text(
                            _targetLabel(s, t),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      provider.update(provider.config.copyWith(
                        glossarySyncTarget: value,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: s.glossaryReorderTargets,
                  icon: const Icon(Icons.sort),
                  onPressed: () => _showReorderDialog(context, provider, s),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (GlossarySyncTargets.usesLocalPath(target))
              _LocalFolderSettings(
                s: s,
                controller: _localPathCtrl,
                onChanged: (value) => provider.updateQuiet(
                  provider.config.copyWith(glossarySyncLocalPath: value.trim()),
                ),
                onChooseFolder: _chooseFolder,
              )
            else if (target == GlossarySyncTargets.webDav)
              _WebDavSettings(
                s: s,
                urlCtrl: _webDavUrlCtrl,
                userCtrl: _webDavUserCtrl,
                passwordCtrl: _webDavPasswordCtrl,
                onUrlChanged: (value) => provider.updateQuiet(
                  provider.config.copyWith(
                    glossarySyncWebDavUrl: value.trim(),
                  ),
                ),
                onUserChanged: (value) => provider.updateQuiet(
                  provider.config.copyWith(
                    glossarySyncWebDavUser: value.trim(),
                  ),
                ),
                onPasswordChanged: (value) => provider.updateQuiet(
                  provider.config.copyWith(glossarySyncWebDavPassword: value),
                ),
              )
            else
              _TypeTwoServerSettings(
                s: s,
                urlCtrl: _urlCtrl,
                emailCtrl: _emailCtrl,
                passwordCtrl: _passwordCtrl,
                isLoggingIn: _loggingIn,
                isLoggedIn: sync.token.trim().isNotEmpty,
                email: sync.email,
                role: sync.role,
                canReview: sync.canReview,
                canManageUsers: sync.canManageUsers,
                onUrlChanged: (value) => provider.updateQuiet(
                  provider.config.copyWith(glossarySyncUrl: value.trim()),
                ),
                onEmailChanged: (value) => provider.updateQuiet(
                  provider.config.copyWith(glossarySyncEmail: value.trim()),
                ),
                onLogin: _login,
                onLogout: _logout,
                onImport: _importRemoteGlossary,
                onExport: _exportRemoteGlossary,
                onReview: _reviewPendingTerms,
                onManageUsers: _manageUsers,
              ),
            const SizedBox(height: 16),
            _SyncStatusAndAction(
              s: s,
              lastSyncedAt: sync.lastSyncedAt,
              pendingCount: sync.pendingChanges.length,
              needsLogin: sync.isTypeTwoServer &&
                  sync.url.trim().isNotEmpty &&
                  sync.token.trim().isEmpty,
              canSync: sync.isEnabled,
              isSyncing: _syncing,
              isTestingConnection: _testingConnection,
              onTestConnection: _testConnection,
              onRestoreBackup: _restoreBackupDialog,
              onSync: _sync,
            ),
          ],
        );
      },
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog({required this.s});

  final AppStrings s;

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AlertDialog(
      title: Text(s.glossaryRejectReasonTitle),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: const ValueKey('pendingGlossaryRejectReasonField'),
          controller: _reasonCtrl,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: s.glossaryRejectReasonHint,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          key: const ValueKey('pendingGlossaryRejectReasonSaveButton'),
          onPressed: () => Navigator.pop(context, _reasonCtrl.text.trim()),
          child: Text(s.glossaryReject),
        ),
      ],
    );
  }
}

class _ImportActionIcon extends StatelessWidget {
  const _ImportActionIcon({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (action) {
      'imported' => (Icons.add_circle_outline, colorScheme.primary),
      'updated' => (Icons.sync_problem_outlined, colorScheme.tertiary),
      'unchanged' => (Icons.check_circle_outline, colorScheme.outline),
      'skipped' => (Icons.error_outline, colorScheme.error),
      _ => (Icons.info_outline, colorScheme.outline),
    };
    return Icon(icon, color: color);
  }
}

String _importActionLabel(AppStrings s, String action) => switch (action) {
      'imported' => s.glossaryImportActionImported,
      'updated' => s.glossaryImportActionUpdated,
      'unchanged' => s.glossaryImportActionUnchanged,
      'skipped' => s.glossaryImportActionSkipped,
      _ => action,
    };

Map<String, Object> _remoteExportPayload(
  String status,
  List<GlossaryRemoteTerm> terms,
) {
  final glossary = <String, String>{};
  final langGlossary = <String, Map<String, String>>{};
  for (final term in terms) {
    if (term.contextKey == 'global') {
      glossary[term.sourceText] = term.targetText;
    } else {
      langGlossary.putIfAbsent(
              term.contextKey, () => <String, String>{})[term.sourceText] =
          term.targetText;
    }
  }
  return {
    'status': status,
    'glossary': glossary,
    'langGlossary': langGlossary,
    'terms': [
      for (final term in terms)
        {
          'id': term.id,
          'contextKey': term.contextKey,
          'sourceText': term.sourceText,
          'targetText': term.targetText,
          'status': term.status,
        },
    ],
  };
}

String _exportStatusLabel(AppStrings s, String status) => switch (status) {
      'approved' => s.glossaryExportApproved,
      'pending' => s.glossaryExportPending,
      'rejected' => s.glossaryExportRejected,
      'all' => s.glossaryExportAll,
      _ => status,
    };

String _targetLabel(AppStrings s, String target) => switch (target) {
      GlossarySyncTargets.typeTwoServer => s.glossarySyncTargetTypeTwo,
      GlossarySyncTargets.webDav => s.glossarySyncTargetWebDav,
      GlossarySyncTargets.oneDrive => s.glossarySyncTargetOneDrive,
      GlossarySyncTargets.dropbox => s.glossarySyncTargetDropbox,
      GlossarySyncTargets.googleDrive => s.glossarySyncTargetGoogleDrive,
      GlossarySyncTargets.synologyDrive => s.glossarySyncTargetSynologyDrive,
      GlossarySyncTargets.fileServer => s.glossarySyncTargetFileServer,
      _ => target,
    };

Future<void> _showReorderDialog(
  BuildContext context,
  ConfigProvider provider,
  AppStrings s,
) async {
  var order = List<String>.from(provider.config.glossarySyncTargetOrder);
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(s.glossaryReorderTargets),
        content: SizedBox(
          width: 320,
          child: ReorderableListView(
            shrinkWrap: true,
            children: [
              for (final t in order)
                ListTile(
                  key: ValueKey(t),
                  title: Text(_targetLabel(s, t)),
                  trailing: const Icon(Icons.drag_handle),
                ),
            ],
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = order.removeAt(oldIndex);
                order.insert(newIndex, item);
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.close),
          ),
          FilledButton(
            onPressed: () {
              provider.update(
                provider.config.copyWith(glossarySyncTargetOrder: order),
              );
              Navigator.pop(ctx);
            },
            child: Text(s.save),
          ),
        ],
      ),
    ),
  );
}

String _userSummary(AppStrings s, GlossaryRemoteUser user) {
  final activeText = user.isActive ? '啟用' : '停用';
  final passwordText = user.mustChangePassword ? '需要改密碼' : '密碼已設定';
  final lastLoginText = user.lastLoginAt == null
      ? '最後登入：尚未登入'
      : '最後登入：${_formatDateTime(user.lastLoginAt!)}';
  return '${s.glossaryUserRole}: ${user.role} · $activeText · '
      '$passwordText · $lastLoginText';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

class _TypeTwoServerSettings extends StatelessWidget {
  const _TypeTwoServerSettings({
    required this.s,
    required this.urlCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.isLoggingIn,
    required this.isLoggedIn,
    required this.email,
    required this.role,
    required this.canReview,
    required this.canManageUsers,
    required this.onUrlChanged,
    required this.onEmailChanged,
    required this.onLogin,
    required this.onLogout,
    required this.onImport,
    required this.onExport,
    required this.onReview,
    required this.onManageUsers,
  });

  final AppStrings s;
  final TextEditingController urlCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool isLoggingIn;
  final bool isLoggedIn;
  final String email;
  final String role;
  final bool canReview;
  final bool canManageUsers;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onReview;
  final VoidCallback onManageUsers;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 12,
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 420,
          child: TextField(
            key: const ValueKey('cloudSyncUrlField'),
            controller: urlCtrl,
            decoration: InputDecoration(
              labelText: s.glossarySyncUrl,
              border: const OutlineInputBorder(),
            ),
            onChanged: onUrlChanged,
          ),
        ),
        SizedBox(
          width: 260,
          child: TextField(
            key: const ValueKey('cloudSyncEmailField'),
            controller: emailCtrl,
            decoration: InputDecoration(
              labelText: s.glossarySyncEmail,
              border: const OutlineInputBorder(),
            ),
            onChanged: onEmailChanged,
          ),
        ),
        SizedBox(
          width: 220,
          child: TextField(
            key: const ValueKey('cloudSyncPasswordField'),
            controller: passwordCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: s.glossarySyncPassword,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => onLogin(),
          ),
        ),
        OutlinedButton.icon(
          onPressed: isLoggingIn ? null : (isLoggedIn ? onLogout : onLogin),
          icon: isLoggingIn
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isLoggedIn ? Icons.logout : Icons.login, size: 16),
          label: Text(isLoggedIn ? s.glossaryLogout : s.glossaryLogin),
        ),
        if (isLoggedIn && role.isNotEmpty) Chip(label: Text('帳號：$email')),
        if (isLoggedIn && role.isNotEmpty)
          Chip(label: Text(s.glossaryRole(role))),
        OutlinedButton.icon(
          onPressed: canReview ? onReview : null,
          icon: const Icon(Icons.fact_check_outlined, size: 16),
          label: Text(s.glossaryReviewPending),
        ),
        OutlinedButton.icon(
          key: const ValueKey('cloudSyncImportPreviewButton'),
          onPressed: canReview ? onImport : null,
          icon: const Icon(Icons.upload_file_outlined, size: 16),
          label: Text(s.glossaryImportPreview),
        ),
        OutlinedButton.icon(
          key: const ValueKey('cloudSyncExportRemoteButton'),
          onPressed: canReview ? onExport : null,
          icon: const Icon(Icons.download_outlined, size: 16),
          label: Text(s.glossaryExportRemote),
        ),
        OutlinedButton.icon(
          onPressed: canManageUsers ? onManageUsers : null,
          icon: const Icon(Icons.group_outlined, size: 16),
          label: Text(s.glossaryManageUsers),
        ),
      ],
    );
  }
}

class _LocalFolderSettings extends StatelessWidget {
  const _LocalFolderSettings({
    required this.s,
    required this.controller,
    required this.onChanged,
    required this.onChooseFolder,
  });

  final AppStrings s;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onChooseFolder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('cloudSyncLocalPathField'),
            controller: controller,
            decoration: InputDecoration(
              labelText: s.glossarySyncLocalPath,
              border: const OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onChooseFolder,
          icon: const Icon(Icons.folder_open_outlined, size: 16),
          label: Text(s.glossaryChooseFolder),
        ),
      ],
    );
  }
}

class _WebDavSettings extends StatelessWidget {
  const _WebDavSettings({
    required this.s,
    required this.urlCtrl,
    required this.userCtrl,
    required this.passwordCtrl,
    required this.onUrlChanged,
    required this.onUserChanged,
    required this.onPasswordChanged,
  });

  final AppStrings s;
  final TextEditingController urlCtrl;
  final TextEditingController userCtrl;
  final TextEditingController passwordCtrl;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onPasswordChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 480,
          child: TextField(
            key: const ValueKey('cloudSyncWebDavUrlField'),
            controller: urlCtrl,
            decoration: InputDecoration(
              labelText: s.glossarySyncWebDavUrl,
              border: const OutlineInputBorder(),
            ),
            onChanged: onUrlChanged,
          ),
        ),
        SizedBox(
          width: 240,
          child: TextField(
            key: const ValueKey('cloudSyncWebDavUserField'),
            controller: userCtrl,
            decoration: InputDecoration(
              labelText: s.glossarySyncWebDavUser,
              border: const OutlineInputBorder(),
            ),
            onChanged: onUserChanged,
          ),
        ),
        SizedBox(
          width: 240,
          child: TextField(
            key: const ValueKey('cloudSyncWebDavPasswordField'),
            controller: passwordCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: s.glossarySyncWebDavPassword,
              border: const OutlineInputBorder(),
            ),
            onChanged: onPasswordChanged,
          ),
        ),
      ],
    );
  }
}

class _SyncStatusAndAction extends StatelessWidget {
  const _SyncStatusAndAction({
    required this.s,
    required this.lastSyncedAt,
    required this.pendingCount,
    required this.needsLogin,
    required this.canSync,
    required this.isSyncing,
    required this.isTestingConnection,
    required this.onTestConnection,
    required this.onRestoreBackup,
    required this.onSync,
  });

  final AppStrings s;
  final String? lastSyncedAt;
  final int pendingCount;
  final bool needsLogin;
  final bool canSync;
  final bool isSyncing;
  final bool isTestingConnection;
  final VoidCallback onTestConnection;
  final VoidCallback onRestoreBackup;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final baseStatus = lastSyncedAt == null
        ? s.glossaryNeverSynced
        : s.glossaryLastSynced(lastSyncedAt!);
    final statusParts = [
      baseStatus,
      if (needsLogin) s.glossaryLoginRequired,
      if (pendingCount > 0) s.glossaryPendingCount(pendingCount),
    ];
    final status = statusParts.join(' · ');
    return Row(
      children: [
        Expanded(child: Text(status)),
        OutlinedButton.icon(
          key: const ValueKey('cloudSyncRestoreBackupButton'),
          onPressed: onRestoreBackup,
          icon: const Icon(Icons.restore_outlined, size: 16),
          label: Text(s.glossaryRestoreBackup),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          key: const ValueKey('cloudSyncTestConnectionButton'),
          onPressed: isTestingConnection ? null : onTestConnection,
          icon: isTestingConnection
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering_outlined, size: 16),
          label: Text(s.glossaryTestConnection),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          key: const ValueKey('cloudSyncButton'),
          onPressed: isSyncing || !canSync ? null : onSync,
          icon: isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, size: 16),
          label: Text(s.glossarySync),
        ),
      ],
    );
  }
}
