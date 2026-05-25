import '../models/app_config.dart';
import 'glossary_remote_service.dart';

class GlossarySyncService {
  static Future<AppConfig> sync(
    AppConfig config, {
    GlossaryRemoteService? remote,
  }) async {
    final bundle = await (remote ?? GlossaryRemoteService()).fetchApproved(
      baseUrl: config.glossarySyncUrl,
      token: config.glossarySyncToken,
    );
    return config.copyWith(
      glossary: bundle.glossary,
      langGlossary: bundle.langGlossary,
      glossaryLastSyncedAt: bundle.syncedAt.toUtc().toIso8601String(),
      glossaryRemoteIds: bundle.remoteIds,
    );
  }
}
