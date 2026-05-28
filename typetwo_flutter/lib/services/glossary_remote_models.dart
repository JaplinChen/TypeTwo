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
