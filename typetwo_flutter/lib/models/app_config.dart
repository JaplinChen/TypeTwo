import 'dart:convert';
import 'app_constants.dart';

const _keep = Object();

class AppConfig {
  final String provider;
  final String model;
  final List<String> fallbackModels;
  final String endpoint;
  final String apiKey;
  final double temperature;
  final String sourceLang;
  final String targetLang;
  final String? secondTargetLang;
  final String template;
  final List<String> extraInstructions;
  final Map<String, String> glossary;
  final Map<String, Map<String, String>> langGlossary;
  final String glossarySyncUrl;
  final String glossarySyncToken;
  final String glossarySyncEmail;
  final String glossarySyncRole;
  final String glossarySyncTarget;
  final String glossarySyncLocalPath;
  final String glossarySyncWebDavUrl;
  final String glossarySyncWebDavUser;
  final String glossarySyncWebDavPassword;
  final String? glossaryLastSyncedAt;
  final Map<String, String> glossaryRemoteIds;
  final List<Map<String, dynamic>> glossaryPendingChanges;
  final bool restrictToAllowedProcesses;
  final List<String> allowedProcesses;
  final List<String> hotkeyModifiers;
  final String hotkeyKey;
  final String thinkingMode;
  final List<String> providerOrder;
  final Map<String, Map<String, dynamic>> providerConfigs;
  final int schemaVersion;

  GlossarySyncConfig get glossarySync => GlossarySyncConfig(
        url: glossarySyncUrl,
        token: glossarySyncToken,
        email: glossarySyncEmail,
        role: glossarySyncRole,
        target: glossarySyncTarget,
        localPath: glossarySyncLocalPath,
        webDavUrl: glossarySyncWebDavUrl,
        webDavUser: glossarySyncWebDavUser,
        webDavPassword: glossarySyncWebDavPassword,
        lastSyncedAt: glossaryLastSyncedAt,
        remoteIds: glossaryRemoteIds,
        pendingChanges: glossaryPendingChanges,
      );

  ProviderRuntimeConfig get providerRuntime => ProviderRuntimeConfig(
        provider: provider,
        model: model,
        fallbackModels: fallbackModels,
        endpoint: endpoint,
        apiKey: apiKey,
        temperature: temperature,
        thinkingMode: thinkingMode,
        providerOrder: providerOrder,
        providerConfigs: providerConfigs,
      );

  AppConfig({
    required this.provider,
    required this.model,
    required this.fallbackModels,
    required this.endpoint,
    required this.apiKey,
    required this.temperature,
    required this.sourceLang,
    required this.targetLang,
    this.secondTargetLang,
    required this.template,
    required this.extraInstructions,
    required this.glossary,
    Map<String, Map<String, String>>? langGlossary,
    this.glossarySyncUrl = '',
    this.glossarySyncToken = '',
    this.glossarySyncEmail = '',
    this.glossarySyncRole = '',
    this.glossarySyncTarget = GlossarySyncTargets.typeTwoServer,
    this.glossarySyncLocalPath = '',
    this.glossarySyncWebDavUrl = '',
    this.glossarySyncWebDavUser = '',
    this.glossarySyncWebDavPassword = '',
    this.glossaryLastSyncedAt,
    Map<String, String>? glossaryRemoteIds,
    List<Map<String, dynamic>>? glossaryPendingChanges,
    required this.restrictToAllowedProcesses,
    required this.allowedProcesses,
    required this.hotkeyModifiers,
    required this.hotkeyKey,
    this.thinkingMode = 'quick',
    List<String>? providerOrder,
    Map<String, Map<String, dynamic>>? providerConfigs,
    this.schemaVersion = 0,
  })  : langGlossary = langGlossary ?? {},
        glossaryRemoteIds = glossaryRemoteIds ?? {},
        glossaryPendingChanges = glossaryPendingChanges ?? [],
        providerOrder = providerOrder ?? List<String>.from(kProviders),
        providerConfigs = providerConfigs ?? {};

  factory AppConfig.defaults() => AppConfig(
        provider: 'Ollama',
        model: 'qwen3:8b',
        fallbackModels: const [
          'qwen3:14b',
          'translategemma:4b',
          'translategemma:12b',
        ],
        endpoint: 'http://127.0.0.1:11434/api/chat',
        apiKey: '',
        temperature: 0.0,
        sourceLang: kAutoDetectLang,
        targetLang: '繁體中文',
        secondTargetLang: '越南文',
        template: '{source}\n{translation}',
        extraInstructions: [],
        glossary: {},
        langGlossary: {},
        glossarySyncUrl: '',
        glossarySyncToken: '',
        glossarySyncEmail: '',
        glossarySyncRole: '',
        glossarySyncTarget: GlossarySyncTargets.typeTwoServer,
        glossarySyncLocalPath: '',
        glossarySyncWebDavUrl: '',
        glossarySyncWebDavUser: '',
        glossarySyncWebDavPassword: '',
        glossaryLastSyncedAt: null,
        glossaryRemoteIds: {},
        glossaryPendingChanges: [],
        restrictToAllowedProcesses: false,
        allowedProcesses: [],
        hotkeyModifiers: ['ctrl', 'alt'],
        hotkeyKey: 't',
        schemaVersion: 1,
      );

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        provider: j['provider'] as String? ?? 'Ollama',
        model: j['model'] as String? ?? 'qwen3:14b',
        fallbackModels: _parseFallbackModels(j['fallbackModels']),
        endpoint: j['endpoint'] as String? ?? 'http://127.0.0.1:11434/api/chat',
        apiKey: j['apiKey'] as String? ?? '',
        temperature: (j['temperature'] as num?)?.toDouble() ?? 0.0,
        sourceLang: j['sourceLang'] as String? ?? kAutoDetectLang,
        targetLang: j['targetLang'] as String? ?? '繁體中文',
        secondTargetLang: j['secondTargetLang'] as String?,
        template: j['template'] as String? ?? '{source}\n{translation}',
        extraInstructions: (j['extraInstructions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        glossary: (j['glossary'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
        langGlossary: _parseLangGlossary(j['langGlossary']),
        glossarySyncUrl: j['glossarySyncUrl'] as String? ?? '',
        glossarySyncToken: j['glossarySyncToken'] as String? ?? '',
        glossarySyncEmail: j['glossarySyncEmail'] as String? ?? '',
        glossarySyncRole: j['glossarySyncRole'] as String? ?? '',
        glossarySyncTarget: GlossarySyncTargets.normalize(
          j['glossarySyncTarget'] as String?,
        ),
        glossarySyncLocalPath: j['glossarySyncLocalPath'] as String? ?? '',
        glossarySyncWebDavUrl: j['glossarySyncWebDavUrl'] as String? ?? '',
        glossarySyncWebDavUser: j['glossarySyncWebDavUser'] as String? ?? '',
        glossarySyncWebDavPassword:
            j['glossarySyncWebDavPassword'] as String? ?? '',
        glossaryLastSyncedAt: j['glossaryLastSyncedAt'] as String?,
        glossaryRemoteIds: (j['glossaryRemoteIds'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
        glossaryPendingChanges:
            _parsePendingChanges(j['glossaryPendingChanges']),
        restrictToAllowedProcesses:
            j['restrictToAllowedProcesses'] as bool? ?? false,
        allowedProcesses: (j['allowedProcesses'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        hotkeyModifiers: (j['hotkeyModifiers'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            ['ctrl', 'alt'],
        hotkeyKey: j['hotkeyKey'] as String? ?? 't',
        thinkingMode: j['thinkingMode'] as String? ?? 'quick',
        providerOrder: _parseProviderOrder(j['providerOrder']),
        providerConfigs: _parseProviderConfigs(j['providerConfigs']),
        schemaVersion: j['schemaVersion'] as int? ?? 0,
      );

  factory AppConfig.fromJsonString(String s) =>
      AppConfig.fromJson(jsonDecode(s) as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'model': model,
        'fallbackModels': fallbackModels,
        'endpoint': endpoint,
        'apiKey': apiKey,
        'temperature': temperature,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        if (secondTargetLang != null) 'secondTargetLang': secondTargetLang,
        'template': template,
        'extraInstructions': extraInstructions,
        'glossary': glossary,
        if (langGlossary.isNotEmpty) 'langGlossary': langGlossary,
        if (glossarySyncUrl.isNotEmpty) 'glossarySyncUrl': glossarySyncUrl,
        if (glossarySyncToken.isNotEmpty)
          'glossarySyncToken': glossarySyncToken,
        if (glossarySyncEmail.isNotEmpty)
          'glossarySyncEmail': glossarySyncEmail,
        if (glossarySyncRole.isNotEmpty) 'glossarySyncRole': glossarySyncRole,
        if (glossarySyncTarget != GlossarySyncTargets.typeTwoServer)
          'glossarySyncTarget': glossarySyncTarget,
        if (glossarySyncLocalPath.isNotEmpty)
          'glossarySyncLocalPath': glossarySyncLocalPath,
        if (glossarySyncWebDavUrl.isNotEmpty)
          'glossarySyncWebDavUrl': glossarySyncWebDavUrl,
        if (glossarySyncWebDavUser.isNotEmpty)
          'glossarySyncWebDavUser': glossarySyncWebDavUser,
        if (glossarySyncWebDavPassword.isNotEmpty)
          'glossarySyncWebDavPassword': glossarySyncWebDavPassword,
        if (glossaryLastSyncedAt != null)
          'glossaryLastSyncedAt': glossaryLastSyncedAt,
        if (glossaryRemoteIds.isNotEmpty)
          'glossaryRemoteIds': glossaryRemoteIds,
        if (glossaryPendingChanges.isNotEmpty)
          'glossaryPendingChanges': glossaryPendingChanges,
        'restrictToAllowedProcesses': restrictToAllowedProcesses,
        'allowedProcesses': allowedProcesses,
        'schemaVersion': schemaVersion,
        'hotkeyModifiers': hotkeyModifiers,
        'hotkeyKey': hotkeyKey,
        'thinkingMode': thinkingMode,
        'providerOrder': providerOrder,
        if (providerConfigs.isNotEmpty) 'providerConfigs': providerConfigs,
      };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  AppConfig copyWith({
    String? provider,
    String? model,
    List<String>? fallbackModels,
    String? endpoint,
    String? apiKey,
    double? temperature,
    String? sourceLang,
    String? targetLang,
    Object? secondTargetLang = _keep,
    String? template,
    List<String>? extraInstructions,
    Map<String, String>? glossary,
    Map<String, Map<String, String>>? langGlossary,
    String? glossarySyncUrl,
    String? glossarySyncToken,
    String? glossarySyncEmail,
    String? glossarySyncRole,
    String? glossarySyncTarget,
    String? glossarySyncLocalPath,
    String? glossarySyncWebDavUrl,
    String? glossarySyncWebDavUser,
    String? glossarySyncWebDavPassword,
    Object? glossaryLastSyncedAt = _keep,
    Map<String, String>? glossaryRemoteIds,
    List<Map<String, dynamic>>? glossaryPendingChanges,
    bool? restrictToAllowedProcesses,
    List<String>? allowedProcesses,
    List<String>? hotkeyModifiers,
    String? hotkeyKey,
    String? thinkingMode,
    List<String>? providerOrder,
    Map<String, Map<String, dynamic>>? providerConfigs,
    int? schemaVersion,
  }) =>
      AppConfig(
        provider: provider ?? this.provider,
        model: model ?? this.model,
        fallbackModels: fallbackModels ?? this.fallbackModels,
        endpoint: endpoint ?? this.endpoint,
        apiKey: apiKey ?? this.apiKey,
        temperature: temperature ?? this.temperature,
        sourceLang: sourceLang ?? this.sourceLang,
        targetLang: targetLang ?? this.targetLang,
        secondTargetLang: identical(secondTargetLang, _keep)
            ? this.secondTargetLang
            : secondTargetLang as String?,
        template: template ?? this.template,
        extraInstructions: extraInstructions ?? this.extraInstructions,
        glossary: glossary ?? this.glossary,
        langGlossary: langGlossary ??
            {
              for (final e in this.langGlossary.entries)
                e.key: Map<String, String>.from(e.value)
            },
        glossarySyncUrl: glossarySyncUrl ?? this.glossarySyncUrl,
        glossarySyncToken: glossarySyncToken ?? this.glossarySyncToken,
        glossarySyncEmail: glossarySyncEmail ?? this.glossarySyncEmail,
        glossarySyncRole: glossarySyncRole ?? this.glossarySyncRole,
        glossarySyncTarget: glossarySyncTarget ?? this.glossarySyncTarget,
        glossarySyncLocalPath:
            glossarySyncLocalPath ?? this.glossarySyncLocalPath,
        glossarySyncWebDavUrl:
            glossarySyncWebDavUrl ?? this.glossarySyncWebDavUrl,
        glossarySyncWebDavUser:
            glossarySyncWebDavUser ?? this.glossarySyncWebDavUser,
        glossarySyncWebDavPassword:
            glossarySyncWebDavPassword ?? this.glossarySyncWebDavPassword,
        glossaryLastSyncedAt: identical(glossaryLastSyncedAt, _keep)
            ? this.glossaryLastSyncedAt
            : glossaryLastSyncedAt as String?,
        glossaryRemoteIds: glossaryRemoteIds ??
            Map<String, String>.from(this.glossaryRemoteIds),
        glossaryPendingChanges: glossaryPendingChanges ??
            this
                .glossaryPendingChanges
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
        restrictToAllowedProcesses:
            restrictToAllowedProcesses ?? this.restrictToAllowedProcesses,
        allowedProcesses: allowedProcesses ?? this.allowedProcesses,
        hotkeyModifiers: hotkeyModifiers ?? this.hotkeyModifiers,
        hotkeyKey: hotkeyKey ?? this.hotkeyKey,
        thinkingMode: thinkingMode ?? this.thinkingMode,
        providerOrder: providerOrder ?? List<String>.from(this.providerOrder),
        providerConfigs: providerConfigs ??
            {
              for (final e in this.providerConfigs.entries)
                e.key: Map<String, dynamic>.from(e.value)
            },
        schemaVersion: schemaVersion ?? this.schemaVersion,
      );

  static List<String> _parseProviderOrder(Object? value) {
    if (value is! List) return List<String>.from(kProviders);
    final saved =
        value.map((e) => e.toString()).where(kProviders.contains).toList();
    for (final p in kProviders) {
      if (!saved.contains(p)) saved.add(p);
    }
    return saved;
  }

  static Map<String, Map<String, dynamic>> _parseProviderConfigs(
      Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.value is Map)
          entry.key.toString(): Map<String, dynamic>.from(entry.value as Map),
    };
  }

  static Map<String, Map<String, String>> _parseLangGlossary(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.value is Map)
          entry.key.toString(): (entry.value as Map).map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          ),
    };
  }

  static List<Map<String, dynamic>> _parsePendingChanges(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  static List<String> _parseFallbackModels(Object? value) {
    if (value is! List) return const [];
    final seen = <String>{};
    final models = <String>[];
    for (final item in value) {
      final model = item.toString().trim();
      if (model.isEmpty || !seen.add(model)) continue;
      models.add(model);
    }
    return models;
  }
}

class GlossarySyncConfig {
  const GlossarySyncConfig({
    required this.url,
    required this.token,
    required this.email,
    required this.role,
    required this.target,
    required this.localPath,
    required this.webDavUrl,
    required this.webDavUser,
    required this.webDavPassword,
    required this.lastSyncedAt,
    required this.remoteIds,
    required this.pendingChanges,
  });

  final String url;
  final String token;
  final String email;
  final String role;
  final String target;
  final String localPath;
  final String webDavUrl;
  final String webDavUser;
  final String webDavPassword;
  final String? lastSyncedAt;
  final Map<String, String> remoteIds;
  final List<Map<String, dynamic>> pendingChanges;

  bool get isTypeTwoServer => target == GlossarySyncTargets.typeTwoServer;
  bool get isLocalFolder => target == GlossarySyncTargets.localFolder;
  bool get isCloudFolder => GlossarySyncTargets.usesLocalPath(target);
  bool get isWebDav => target == GlossarySyncTargets.webDav;
  bool get isEnabled => switch (target) {
        GlossarySyncTargets.typeTwoServer =>
          url.trim().isNotEmpty && token.trim().isNotEmpty,
        GlossarySyncTargets.webDav => webDavUrl.trim().isNotEmpty,
        _ => isCloudFolder && localPath.trim().isNotEmpty,
      };
  bool get canReview => {'admin', 'editor'}.contains(role);
  bool get canManageUsers => role == 'admin';
}

class GlossarySyncTargets {
  const GlossarySyncTargets._();

  static const typeTwoServer = 'typeTwoServer';
  static const localFolder = 'localFolder';
  static const webDav = 'webDav';
  static const oneDrive = 'oneDrive';
  static const dropbox = 'dropbox';
  static const googleDrive = 'googleDrive';
  static const synologyDrive = 'synologyDrive';
  static const values = [
    typeTwoServer,
    webDav,
    oneDrive,
    dropbox,
    googleDrive,
    synologyDrive,
    localFolder,
  ];
  static const localPathTargets = [
    localFolder,
    oneDrive,
    dropbox,
    googleDrive,
    synologyDrive,
  ];

  static String normalize(String? value) =>
      values.contains(value) ? value! : typeTwoServer;

  static bool usesLocalPath(String target) => localPathTargets.contains(target);
}

class ProviderRuntimeConfig {
  const ProviderRuntimeConfig({
    required this.provider,
    required this.model,
    required this.fallbackModels,
    required this.endpoint,
    required this.apiKey,
    required this.temperature,
    required this.thinkingMode,
    required this.providerOrder,
    required this.providerConfigs,
  });

  final String provider;
  final String model;
  final List<String> fallbackModels;
  final String endpoint;
  final String apiKey;
  final double temperature;
  final String thinkingMode;
  final List<String> providerOrder;
  final Map<String, Map<String, dynamic>> providerConfigs;

  double get clampedTemperature => temperature.clamp(0.0, 2.0);

  int get geminiThinkingBudget => switch (thinkingMode) {
        'auto' => -1,
        'thinking' => 8192,
        _ => 0,
      };

  List<String> get modelAttempts {
    final seen = <String>{};
    return [model, ...fallbackModels]
        .map((model) => model.trim())
        .where((model) => model.isNotEmpty && seen.add(model))
        .toList();
  }
}
