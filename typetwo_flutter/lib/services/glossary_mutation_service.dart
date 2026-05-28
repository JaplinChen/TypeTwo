import '../models/app_config.dart';
import 'glossary_remote_service.dart';

class GlossaryMutationService {
  const GlossaryMutationService({GlossaryRemoteService? remote})
      : _remote = remote;

  final GlossaryRemoteService? _remote;

  Future<AppConfig> flushPendingChanges(AppConfig config) async {
    final sync = config.glossarySync;
    var remoteIds = Map<String, String>.from(sync.remoteIds);
    for (final change in sync.pendingChanges) {
      final op = change['op']?.toString() ?? '';
      final contextKey = change['contextKey']?.toString() ?? 'global';
      final sourceText = change['sourceText']?.toString() ?? '';
      final working = config.copyWith(glossaryRemoteIds: remoteIds);

      if (op == 'delete') {
        remoteIds = await pushDelete(
          config: working,
          contextKey: contextKey,
          sourceText: sourceText,
        );
        continue;
      }

      remoteIds = await pushUpsert(
        config: working,
        contextKey: contextKey,
        sourceText: sourceText,
        targetText: change['targetText']?.toString() ?? '',
        oldSourceText: change['oldSourceText']?.toString(),
      );
    }

    return config.copyWith(
      glossaryRemoteIds: remoteIds,
      glossaryPendingChanges: [],
    );
  }

  Future<Map<String, String>> pushUpsert({
    required AppConfig config,
    required String contextKey,
    required String sourceText,
    required String targetText,
    String? oldSourceText,
  }) async {
    final remote = _remote ?? GlossaryRemoteService();
    final sync = config.glossarySync;
    final remoteIds = Map<String, String>.from(sync.remoteIds);
    final oldKey = GlossaryRemoteService.remoteKey(
      contextKey,
      oldSourceText ?? sourceText,
    );
    final existingId = remoteIds[oldKey];
    final term = existingId == null
        ? await remote.createTerm(
            baseUrl: sync.url,
            token: sync.token,
            contextKey: contextKey,
            sourceText: sourceText,
            targetText: targetText,
          )
        : await remote.updateTerm(
            baseUrl: sync.url,
            token: sync.token,
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

  Future<Map<String, String>> pushDelete({
    required AppConfig config,
    required String contextKey,
    required String sourceText,
  }) async {
    final sync = config.glossarySync;
    final remoteIds = Map<String, String>.from(sync.remoteIds);
    final key = GlossaryRemoteService.remoteKey(contextKey, sourceText);
    final id = remoteIds[key];
    if (id != null) {
      await (_remote ?? GlossaryRemoteService()).deleteTerm(
        baseUrl: sync.url,
        token: sync.token,
        id: id,
      );
      remoteIds.remove(key);
    }
    return remoteIds;
  }

  static bool remoteEnabled(AppConfig config) =>
      config.glossarySync.isTypeTwoServer && config.glossarySync.isEnabled;

  static Map<String, dynamic> pendingChange({
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
}
