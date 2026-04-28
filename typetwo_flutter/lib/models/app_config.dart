import 'dart:convert';
import 'app_constants.dart';

const _keep = Object();

class AppConfig {
  String provider;
  String model;
  List<String> fallbackModels;
  String endpoint;
  String apiKey;
  double temperature;
  String sourceLang;
  String targetLang;
  String? secondTargetLang;
  String template;
  List<String> extraInstructions;
  Map<String, String> glossary;
  bool restrictToAllowedProcesses;
  List<String> allowedProcesses;
  List<String> hotkeyModifiers;
  String hotkeyKey;
  String thinkingMode;
  List<String> providerOrder;

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
    required this.restrictToAllowedProcesses,
    required this.allowedProcesses,
    required this.hotkeyModifiers,
    required this.hotkeyKey,
    this.thinkingMode = 'quick',
    List<String>? providerOrder,
  }) : providerOrder = providerOrder ?? List<String>.from(kProviders);

  factory AppConfig.defaults() => AppConfig(
        provider: 'Ollama',
        model: 'qwen3:14b',
        fallbackModels: const [
          'translategemma:4b',
          'translategemma:12b',
          'qwen3:8b',
        ],
        endpoint: 'http://127.0.0.1:11434/api/chat',
        apiKey: '',
        temperature: 0.0,
        sourceLang: '繁體中文',
        targetLang: '越南文',
        template: '{source}\n{translation}',
        extraInstructions: [],
        glossary: {},
        restrictToAllowedProcesses: false,
        allowedProcesses: [],
        hotkeyModifiers: ['ctrl', 'alt'],
        hotkeyKey: 't',
      );

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        provider: j['provider'] as String? ?? 'Ollama',
        model: j['model'] as String? ?? 'qwen3:14b',
        fallbackModels: _parseFallbackModels(j['fallbackModels']),
        endpoint: j['endpoint'] as String? ?? 'http://127.0.0.1:11434/api/chat',
        apiKey: j['apiKey'] as String? ?? '',
        temperature: (j['temperature'] as num?)?.toDouble() ?? 0.0,
        sourceLang: j['sourceLang'] as String? ?? '繁體中文',
        targetLang: j['targetLang'] as String? ?? '越南文',
        secondTargetLang: j['secondTargetLang'] as String?,
        template: j['template'] as String? ?? '{source}\n{translation}',
        extraInstructions: (j['extraInstructions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        glossary: (j['glossary'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
        restrictToAllowedProcesses: j['restrictToAllowedProcesses'] as bool? ??
            ((j['allowedProcesses'] as List<dynamic>?)?.isNotEmpty ?? false),
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
        'restrictToAllowedProcesses': restrictToAllowedProcesses,
        'allowedProcesses': allowedProcesses,
        'hotkeyModifiers': hotkeyModifiers,
        'hotkeyKey': hotkeyKey,
        'thinkingMode': thinkingMode,
        'providerOrder': providerOrder,
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
    bool? restrictToAllowedProcesses,
    List<String>? allowedProcesses,
    List<String>? hotkeyModifiers,
    String? hotkeyKey,
    String? thinkingMode,
    List<String>? providerOrder,
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
        restrictToAllowedProcesses:
            restrictToAllowedProcesses ?? this.restrictToAllowedProcesses,
        allowedProcesses: allowedProcesses ?? this.allowedProcesses,
        hotkeyModifiers: hotkeyModifiers ?? this.hotkeyModifiers,
        hotkeyKey: hotkeyKey ?? this.hotkeyKey,
        thinkingMode: thinkingMode ?? this.thinkingMode,
        providerOrder: providerOrder ?? List<String>.from(this.providerOrder),
      );

  static List<String> _parseProviderOrder(Object? value) {
    if (value is! List) return List<String>.from(kProviders);
    final saved = value
        .map((e) => e.toString())
        .where(kProviders.contains)
        .toList();
    for (final p in kProviders) {
      if (!saved.contains(p)) saved.add(p);
    }
    return saved;
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
