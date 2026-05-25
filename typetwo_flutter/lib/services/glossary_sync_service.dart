import '../models/app_config.dart';
import 'glossary_remote_service.dart';

class GlossarySyncService {
  static Future<AppConfig> sync(
    AppConfig config, {
    GlossaryRemoteService? remote,
  }) async {
    final sync = config.glossarySync;
    final bundle = await (remote ?? GlossaryRemoteService()).fetchApproved(
      baseUrl: sync.url,
      token: sync.token,
    );
    return config.copyWith(
      glossary: bundle.glossary,
      langGlossary: bundle.langGlossary,
      glossaryLastSyncedAt: bundle.syncedAt.toUtc().toIso8601String(),
      glossaryRemoteIds: bundle.remoteIds,
    );
  }
}
