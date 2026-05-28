import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import '../services/config_service.dart';
import '../services/glossary_sync_backup_service.dart';
import '../services/glossary_mutation_service.dart';
import '../services/glossary_remote_service.dart';
import '../services/glossary_sync_service.dart';

class ConfigProvider extends ChangeNotifier {
  ConfigProvider({GlossaryMutationService? glossaryMutation})
      : _glossaryMutation = glossaryMutation ?? const GlossaryMutationService();

  final GlossaryMutationService _glossaryMutation;
  AppConfig _config = AppConfig.defaults();
  bool _loading = true;
  String? _error;

  AppConfig get config => _config;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _config = await ConfigService.load();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Returns true if config was also synced to the TypeTwo.exe directory.
  Future<bool> save(AppConfig cfg) async {
    final synced = await ConfigService.save(cfg);
    _config = cfg;
    notifyListeners();
    return synced;
  }

  void update(AppConfig cfg) {
    _config = cfg;
    notifyListeners();
  }

  /// Update in-memory config without triggering Consumer/watch rebuilds.
  /// Use for per-keystroke text field changes. Save button reads _config directly,
  /// so quieted changes are still persisted when the user clicks 儲存.
  void updateQuiet(AppConfig cfg) {
    _config = cfg;
  }

  Future<void> syncGlossaryFromRemote() async {
    await const GlossarySyncBackupService().backup(_config);
    if (GlossaryMutationService.remoteEnabled(_config)) {
      await save(await _glossaryMutation.flushPendingChanges(_config));
    }
    final synced = await GlossarySyncService.sync(_config);
    await save(synced);
  }

  Future<void> loginGlossaryRemote(String email, String password) async {
    final sync = _config.glossarySync;
    final remote = GlossaryRemoteService();
    final result = await remote.login(
      baseUrl: sync.url,
      email: email,
      password: password,
    );
    await save(
      _config.copyWith(
        glossarySyncEmail: email.trim(),
        glossarySyncToken: result.accessToken,
        glossarySyncRole: result.role,
      ),
    );
  }

  Future<void> logoutGlossaryRemote() async {
    await save(
      _config.copyWith(
        glossarySyncToken: '',
        glossarySyncRole: '',
        glossaryRemoteIds: {},
        glossaryPendingChanges: [],
      ),
    );
  }

  Future<List<GlossaryRemoteTerm>> listPendingGlossaryTerms() =>
      GlossaryRemoteService().listTerms(
        baseUrl: _config.glossarySync.url,
        token: _config.glossarySync.token,
        status: 'pending',
      );

  Future<List<GlossaryRemoteUser>> listGlossaryUsers() =>
      GlossaryRemoteService().listUsers(
        baseUrl: _config.glossarySync.url,
        token: _config.glossarySync.token,
      );

  Future<void> createGlossaryUser({
    required String email,
    required String password,
    required String role,
  }) async {
    final sync = _config.glossarySync;
    await GlossaryRemoteService().createUser(
      baseUrl: sync.url,
      token: sync.token,
      email: email,
      password: password,
      role: role,
    );
  }

  Future<void> updateGlossaryUser({
    required String id,
    String? role,
    bool? isActive,
  }) async {
    final sync = _config.glossarySync;
    await GlossaryRemoteService().updateUser(
      baseUrl: sync.url,
      token: sync.token,
      id: id,
      role: role,
      isActive: isActive,
    );
  }

  Future<void> approveGlossaryTerm(String id) async {
    final sync = _config.glossarySync;
    await GlossaryRemoteService().approveTerm(
      baseUrl: sync.url,
      token: sync.token,
      id: id,
    );
    await syncGlossaryFromRemote();
  }

  Future<void> rejectGlossaryTerm(String id) async {
    final sync = _config.glossarySync;
    await GlossaryRemoteService().rejectTerm(
      baseUrl: sync.url,
      token: sync.token,
      id: id,
    );
  }

  Future<List<GlossarySyncBackupInfo>> listGlossarySyncBackups() =>
      const GlossarySyncBackupService().listBackups();

  Future<void> restoreGlossarySyncBackup(String path) async {
    const backupService = GlossarySyncBackupService();
    await backupService.backup(_config);
    final restored = await backupService.restore(_config, path);
    await save(restored);
  }

  Future<void> saveGlossaryEntry({
    required String contextKey,
    required String sourceText,
    required String targetText,
    String? oldSourceText,
  }) async {
    final updated = _updatedGlossaryMap(contextKey, sourceText, targetText,
        oldSourceText: oldSourceText);
    final remoteEnabled = GlossaryMutationService.remoteEnabled(_config);
    if (!remoteEnabled) {
      update(updated);
      return;
    }

    try {
      final remoteIds = await _glossaryMutation.pushUpsert(
        config: _config,
        contextKey: contextKey,
        sourceText: sourceText,
        targetText: targetText,
        oldSourceText: oldSourceText,
      );
      await save(updated.copyWith(glossaryRemoteIds: remoteIds));
    } catch (e) {
      await save(
        updated.copyWith(
          glossaryPendingChanges: [
            ..._config.glossarySync.pendingChanges,
            GlossaryMutationService.pendingChange(
              op: 'upsert',
              contextKey: contextKey,
              sourceText: sourceText,
              targetText: targetText,
              oldSourceText: oldSourceText,
            ),
          ],
        ),
      );
      throw GlossaryPendingException('已先儲存在本機，恢復連線後會同步。');
    }
  }

  Future<void> deleteGlossaryEntry({
    required String contextKey,
    required String sourceText,
  }) async {
    final updated = _deleteGlossaryMap(contextKey, sourceText);
    final remoteEnabled = GlossaryMutationService.remoteEnabled(_config);
    if (!remoteEnabled) {
      update(updated);
      return;
    }

    try {
      final remoteIds = await _glossaryMutation.pushDelete(
        config: _config,
        contextKey: contextKey,
        sourceText: sourceText,
      );
      await save(updated.copyWith(glossaryRemoteIds: remoteIds));
    } catch (e) {
      await save(
        updated.copyWith(
          glossaryPendingChanges: [
            ..._config.glossarySync.pendingChanges,
            GlossaryMutationService.pendingChange(
              op: 'delete',
              contextKey: contextKey,
              sourceText: sourceText,
            ),
          ],
        ),
      );
      throw GlossaryPendingException('已先從本機移除，恢復連線後會同步。');
    }
  }

  AppConfig _updatedGlossaryMap(
    String contextKey,
    String sourceText,
    String targetText, {
    String? oldSourceText,
  }) {
    if (contextKey == 'global') {
      final glossary = Map<String, String>.from(_config.glossary)
        ..remove(oldSourceText ?? sourceText)
        ..[sourceText] = targetText;
      return _config.copyWith(glossary: glossary);
    }
    final current = Map<String, String>.from(
      _config.langGlossary[contextKey] ?? {},
    )
      ..remove(oldSourceText ?? sourceText)
      ..[sourceText] = targetText;
    final langGlossary = {
      for (final e in _config.langGlossary.entries)
        e.key: Map<String, String>.from(e.value),
      contextKey: current,
    };
    return _config.copyWith(langGlossary: langGlossary);
  }

  AppConfig _deleteGlossaryMap(String contextKey, String sourceText) {
    if (contextKey == 'global') {
      final glossary = Map<String, String>.from(_config.glossary)
        ..remove(sourceText);
      return _config.copyWith(glossary: glossary);
    }
    final current = Map<String, String>.from(
      _config.langGlossary[contextKey] ?? {},
    )..remove(sourceText);
    final langGlossary = {
      for (final e in _config.langGlossary.entries)
        e.key: Map<String, String>.from(e.value),
      contextKey: current,
    };
    return _config.copyWith(langGlossary: langGlossary);
  }
}

class GlossaryPendingException implements Exception {
  const GlossaryPendingException(this.message);

  final String message;

  @override
  String toString() => message;
}
