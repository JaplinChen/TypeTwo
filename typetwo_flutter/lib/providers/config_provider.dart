import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import '../services/config_service.dart';
import '../services/glossary_remote_service.dart';
import '../services/glossary_sync_service.dart';

class ConfigProvider extends ChangeNotifier {
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
    if (_remoteEnabled(_config)) {
      await _flushPendingGlossaryChanges();
    }
    final synced = await GlossarySyncService.sync(_config);
    await save(synced);
  }

  Future<void> loginGlossaryRemote(String email, String password) async {
    final remote = GlossaryRemoteService();
    final result = await remote.login(
      baseUrl: _config.glossarySyncUrl,
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
        baseUrl: _config.glossarySyncUrl,
        token: _config.glossarySyncToken,
        status: 'pending',
      );

  Future<List<GlossaryRemoteUser>> listGlossaryUsers() =>
      GlossaryRemoteService().listUsers(
        baseUrl: _config.glossarySyncUrl,
        token: _config.glossarySyncToken,
      );

  Future<void> createGlossaryUser({
    required String email,
    required String password,
    required String role,
  }) async {
    await GlossaryRemoteService().createUser(
      baseUrl: _config.glossarySyncUrl,
      token: _config.glossarySyncToken,
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
    await GlossaryRemoteService().updateUser(
      baseUrl: _config.glossarySyncUrl,
      token: _config.glossarySyncToken,
      id: id,
      role: role,
      isActive: isActive,
    );
  }

  Future<void> approveGlossaryTerm(String id) async {
    await GlossaryRemoteService().approveTerm(
      baseUrl: _config.glossarySyncUrl,
      token: _config.glossarySyncToken,
      id: id,
    );
    await syncGlossaryFromRemote();
  }

  Future<void> rejectGlossaryTerm(String id) async {
    await GlossaryRemoteService().rejectTerm(
      baseUrl: _config.glossarySyncUrl,
      token: _config.glossarySyncToken,
      id: id,
    );
  }

  Future<void> saveGlossaryEntry({
    required String contextKey,
    required String sourceText,
    required String targetText,
    String? oldSourceText,
  }) async {
    final updated = _updatedGlossaryMap(contextKey, sourceText, targetText,
        oldSourceText: oldSourceText);
    final remoteEnabled = _remoteEnabled(_config);
    if (!remoteEnabled) {
      update(updated);
      return;
    }

    try {
      final remoteIds = await _pushUpsert(
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
            ..._config.glossaryPendingChanges,
            _pendingChange(
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
    final remoteEnabled = _remoteEnabled(_config);
    if (!remoteEnabled) {
      update(updated);
      return;
    }

    try {
      final remoteIds = await _pushDelete(
        config: _config,
        contextKey: contextKey,
        sourceText: sourceText,
      );
      await save(updated.copyWith(glossaryRemoteIds: remoteIds));
    } catch (e) {
      await save(
        updated.copyWith(
          glossaryPendingChanges: [
            ..._config.glossaryPendingChanges,
            _pendingChange(
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

  Future<void> _flushPendingGlossaryChanges() async {
    var working = _config;
    var remoteIds = Map<String, String>.from(working.glossaryRemoteIds);
    for (final change in working.glossaryPendingChanges) {
      final op = change['op']?.toString() ?? '';
      final contextKey = change['contextKey']?.toString() ?? 'global';
      final sourceText = change['sourceText']?.toString() ?? '';
      if (op == 'delete') {
        remoteIds = await _pushDelete(
          config: working.copyWith(glossaryRemoteIds: remoteIds),
          contextKey: contextKey,
          sourceText: sourceText,
        );
        continue;
      }
      remoteIds = await _pushUpsert(
        config: working.copyWith(glossaryRemoteIds: remoteIds),
        contextKey: contextKey,
        sourceText: sourceText,
        targetText: change['targetText']?.toString() ?? '',
        oldSourceText: change['oldSourceText']?.toString(),
      );
    }
    await save(
      _config.copyWith(
        glossaryRemoteIds: remoteIds,
        glossaryPendingChanges: [],
      ),
    );
  }

  Future<Map<String, String>> _pushUpsert({
    required AppConfig config,
    required String contextKey,
    required String sourceText,
    required String targetText,
    String? oldSourceText,
  }) async {
    final remote = GlossaryRemoteService();
    final remoteIds = Map<String, String>.from(config.glossaryRemoteIds);
    final oldKey = GlossaryRemoteService.remoteKey(
      contextKey,
      oldSourceText ?? sourceText,
    );
    final existingId = remoteIds[oldKey];
    final term = existingId == null
        ? await remote.createTerm(
            baseUrl: config.glossarySyncUrl,
            token: config.glossarySyncToken,
            contextKey: contextKey,
            sourceText: sourceText,
            targetText: targetText,
          )
        : await remote.updateTerm(
            baseUrl: config.glossarySyncUrl,
            token: config.glossarySyncToken,
            id: existingId,
            contextKey: contextKey,
            sourceText: sourceText,
            targetText: targetText,
          );
    remoteIds.remove(oldKey);
    remoteIds[GlossaryRemoteService.remoteKey(contextKey, sourceText)] =
        term.id;
    return remoteIds;
  }

  Future<Map<String, String>> _pushDelete({
    required AppConfig config,
    required String contextKey,
    required String sourceText,
  }) async {
    final remoteIds = Map<String, String>.from(config.glossaryRemoteIds);
    final key = GlossaryRemoteService.remoteKey(contextKey, sourceText);
    final id = remoteIds[key];
    if (id != null) {
      await GlossaryRemoteService().deleteTerm(
        baseUrl: config.glossarySyncUrl,
        token: config.glossarySyncToken,
        id: id,
      );
      remoteIds.remove(key);
    }
    return remoteIds;
  }

  static bool _remoteEnabled(AppConfig config) =>
      config.glossarySyncUrl.trim().isNotEmpty &&
      config.glossarySyncToken.trim().isNotEmpty;

  static Map<String, dynamic> _pendingChange({
    required String op,
    required String contextKey,
    required String sourceText,
    String? targetText,
    String? oldSourceText,
  }) =>
      {
        'op': op,
        'contextKey': contextKey,
        'sourceText': sourceText,
        if (targetText != null) 'targetText': targetText,
        if (oldSourceText != null) 'oldSourceText': oldSourceText,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

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
