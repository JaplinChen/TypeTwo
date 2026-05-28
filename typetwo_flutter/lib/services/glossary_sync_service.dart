import '../models/app_config.dart';
import 'glossary_sync_provider.dart';

class GlossarySyncService {
  static Future<AppConfig> sync(
    AppConfig config, {
    GlossarySyncProvider? provider,
  }) async {
    final sync = config.glossarySync;
    final resolved = provider ?? _providerFor(sync.target);
    return resolved.sync(config);
  }

  static GlossarySyncProvider _providerFor(String target) {
    if (GlossarySyncTargets.usesLocalPath(target)) {
      return const LocalFolderSyncProvider();
    }
    if (target == GlossarySyncTargets.webDav) {
      return WebDavSyncProvider();
    }
    return const TypeTwoServerSyncProvider();
  }
}
