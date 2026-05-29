class GlossaryRemoteBundle {
  const GlossaryRemoteBundle({
    required this.glossary,
    required this.langGlossary,
    required this.syncedAt,
    required this.remoteIds,
  });

  final Map<String, String> glossary;
  final Map<String, Map<String, String>> langGlossary;
  final DateTime syncedAt;
  final Map<String, String> remoteIds;

  factory GlossaryRemoteBundle.fromJson(Map<String, dynamic> json) {
    final rawGlossary = json['glossary'];
    final rawLangGlossary = json['langGlossary'];
    final syncedAtText = json['syncedAt']?.toString();
    return GlossaryRemoteBundle(
      glossary: rawGlossary is Map
          ? rawGlossary.map((k, v) => MapEntry(k.toString(), v.toString()))
          : <String, String>{},
      langGlossary: rawLangGlossary is Map
          ? {
              for (final entry in rawLangGlossary.entries)
                if (entry.value is Map)
                  entry.key.toString(): (entry.value as Map).map(
                    (k, v) => MapEntry(k.toString(), v.toString()),
                  ),
            }
          : <String, Map<String, String>>{},
      syncedAt: DateTime.tryParse(syncedAtText ?? '') ?? DateTime.now().toUtc(),
      remoteIds: <String, String>{},
    );
  }
}

class GlossaryRemoteTerm {
  const GlossaryRemoteTerm({
    required this.id,
    required this.sourceText,
    required this.targetText,
    required this.contextKey,
    required this.status,
  });

  final String id;
  final String sourceText;
  final String targetText;
  final String contextKey;
  final String status;

  factory GlossaryRemoteTerm.fromJson(Map<String, dynamic> json) =>
      GlossaryRemoteTerm(
        id: json['id'].toString(),
        sourceText: json['sourceText']?.toString() ?? '',
        targetText: json['targetText']?.toString() ?? '',
        contextKey: json['contextKey']?.toString() ?? 'global',
        status: json['status']?.toString() ?? 'approved',
      );
}

class GlossaryRemoteTermHistory {
  const GlossaryRemoteTermHistory({
    required this.id,
    required this.termId,
    required this.sourceText,
    required this.targetText,
    required this.contextKey,
    required this.status,
    required this.version,
    required this.operation,
    required this.reason,
    required this.changedAt,
  });

  final String id;
  final String termId;
  final String sourceText;
  final String targetText;
  final String contextKey;
  final String status;
  final int version;
  final String operation;
  final String? reason;
  final DateTime? changedAt;

  factory GlossaryRemoteTermHistory.fromJson(Map<String, dynamic> json) =>
      GlossaryRemoteTermHistory(
        id: json['id'].toString(),
        termId: json['termId']?.toString() ?? '',
        sourceText: json['sourceText']?.toString() ?? '',
        targetText: json['targetText']?.toString() ?? '',
        contextKey: json['contextKey']?.toString() ?? 'global',
        status: json['status']?.toString() ?? '',
        version: int.tryParse(json['version']?.toString() ?? '') ?? 0,
        operation: json['operation']?.toString() ?? '',
        reason: json['reason']?.toString(),
        changedAt: _parseDateTime(json['changedAt']),
      );
}

class GlossaryImportPayload {
  const GlossaryImportPayload({
    required this.glossary,
    required this.langGlossary,
    this.status = 'approved',
    this.conflictStrategy = 'overwrite',
  });

  final Map<String, String> glossary;
  final Map<String, Map<String, String>> langGlossary;
  final String status;
  final String conflictStrategy;

  int get termCount =>
      glossary.length +
      langGlossary.values.fold<int>(0, (sum, entries) => sum + entries.length);

  Map<String, dynamic> toJson() => {
        'glossary': glossary,
        'langGlossary': langGlossary,
        'status': status,
        'conflictStrategy': conflictStrategy,
      };

  factory GlossaryImportPayload.fromJson(
    Map<String, dynamic> json, {
    String status = 'approved',
  }) {
    final glossary = _stringMap(json['glossary']);
    final langGlossary = _nestedStringMap(json['langGlossary']);
    if (glossary.isEmpty && langGlossary.isEmpty) {
      final flat = _stringMap(json);
      if (flat.isNotEmpty) {
        return GlossaryImportPayload(
          glossary: flat,
          langGlossary: const {},
          status: status,
        );
      }
    }
    final rawStatus = json['status']?.toString().trim();
    final parsedStatus = {'approved', 'pending', 'rejected'}.contains(rawStatus)
        ? rawStatus!
        : status;
    final rawStrategy = json['conflictStrategy']?.toString().trim();
    final parsedStrategy = {'overwrite', 'keepExisting'}.contains(rawStrategy)
        ? rawStrategy!
        : 'overwrite';
    return GlossaryImportPayload(
      glossary: glossary,
      langGlossary: langGlossary,
      status: parsedStatus,
      conflictStrategy: parsedStrategy,
    );
  }

  GlossaryImportPayload copyWith({
    String? status,
    String? conflictStrategy,
  }) =>
      GlossaryImportPayload(
        glossary: glossary,
        langGlossary: langGlossary,
        status: status ?? this.status,
        conflictStrategy: conflictStrategy ?? this.conflictStrategy,
      );
}

class GlossaryImportResult {
  const GlossaryImportResult({
    required this.imported,
    required this.updated,
  });

  final int imported;
  final int updated;

  factory GlossaryImportResult.fromJson(Map<String, dynamic> json) =>
      GlossaryImportResult(
        imported: _parseInt(json['imported']),
        updated: _parseInt(json['updated']),
      );
}

class GlossaryImportPreviewResult {
  const GlossaryImportPreviewResult({
    required this.imported,
    required this.updated,
    required this.unchanged,
    required this.skipped,
    required this.items,
  });

  final int imported;
  final int updated;
  final int unchanged;
  final int skipped;
  final List<GlossaryImportPreviewItem> items;

  int get writableCount => imported + updated;

  factory GlossaryImportPreviewResult.fromJson(Map<String, dynamic> json) =>
      GlossaryImportPreviewResult(
        imported: _parseInt(json['imported']),
        updated: _parseInt(json['updated']),
        unchanged: _parseInt(json['unchanged']),
        skipped: _parseInt(json['skipped']),
        items: (json['items'] is List ? json['items'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(GlossaryImportPreviewItem.fromJson)
            .toList(),
      );
}

class GlossaryImportPreviewItem {
  const GlossaryImportPreviewItem({
    required this.action,
    required this.contextKey,
    required this.sourceText,
    required this.targetText,
    required this.status,
    required this.currentTargetText,
    required this.currentStatus,
    required this.message,
  });

  final String action;
  final String contextKey;
  final String sourceText;
  final String targetText;
  final String status;
  final String? currentTargetText;
  final String? currentStatus;
  final String? message;

  factory GlossaryImportPreviewItem.fromJson(Map<String, dynamic> json) =>
      GlossaryImportPreviewItem(
        action: json['action']?.toString() ?? '',
        contextKey: json['contextKey']?.toString() ?? 'global',
        sourceText: json['sourceText']?.toString() ?? '',
        targetText: json['targetText']?.toString() ?? '',
        status: json['status']?.toString() ?? 'approved',
        currentTargetText: json['currentTargetText']?.toString(),
        currentStatus: json['currentStatus']?.toString(),
        message: json['message']?.toString(),
      );
}

class GlossaryLoginResult {
  const GlossaryLoginResult({
    required this.accessToken,
    required this.role,
    required this.mustChangePassword,
  });

  final String accessToken;
  final String role;
  final bool mustChangePassword;
}

class GlossaryRemoteUser {
  const GlossaryRemoteUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
  });

  final String id;
  final String email;
  final String role;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  factory GlossaryRemoteUser.fromJson(Map<String, dynamic> json) =>
      GlossaryRemoteUser(
        id: json['id'].toString(),
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'user',
        isActive: json['isActive'] == true,
        mustChangePassword: json['mustChangePassword'] == true,
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        lastLoginAt: _parseDateTime(json['lastLoginAt']),
      );
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _parseInt(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return {};
  return {
    for (final entry in value.entries)
      if (entry.value is! Map)
        if (!{'status', 'conflictStrategy'}.contains(entry.key.toString()))
          entry.key.toString(): entry.value?.toString() ?? '',
  };
}

Map<String, Map<String, String>> _nestedStringMap(Object? value) {
  if (value is! Map) return {};
  return {
    for (final entry in value.entries)
      if (entry.value is Map)
        entry.key.toString(): (entry.value as Map).map(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
        ),
  };
}

class GlossaryPasswordResetResult {
  const GlossaryPasswordResetResult({
    required this.user,
    required this.temporaryPassword,
  });

  final GlossaryRemoteUser user;
  final String temporaryPassword;

  factory GlossaryPasswordResetResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    if (rawUser is! Map<String, dynamic>) {
      throw const GlossaryRemoteException('重設密碼回應格式錯誤');
    }
    return GlossaryPasswordResetResult(
      user: GlossaryRemoteUser.fromJson(rawUser),
      temporaryPassword: json['temporaryPassword']?.toString() ?? '',
    );
  }
}

class GlossaryRemoteException implements Exception {
  const GlossaryRemoteException(this.message);

  final String message;

  @override
  String toString() => message;
}
