import 'dart:convert';

class AppConfig {
  String provider;
  String model;
  List<String> fallbackModels;
  String endpoint;
  String apiKey;
  double temperature;
  String sourceLang;
  String targetLang;
  String sourceLabel;
  String targetLabel;
  String template;
  List<String> extraInstructions;
  Map<String, String> glossary;
  List<String> allowedProcesses;
  List<String> hotkeyModifiers;
  String hotkeyKey;
  String thinkingMode;

  AppConfig({
    required this.provider,
    required this.model,
    required this.fallbackModels,
    required this.endpoint,
    required this.apiKey,
    required this.temperature,
    required this.sourceLang,
    required this.targetLang,
    required this.sourceLabel,
    required this.targetLabel,
    required this.template,
    required this.extraInstructions,
    required this.glossary,
    required this.allowedProcesses,
    required this.hotkeyModifiers,
    required this.hotkeyKey,
    this.thinkingMode = 'quick',
  });

  factory AppConfig.defaults() => AppConfig(
        provider: 'Ollama',
        model: 'translategemma',
        fallbackModels: const [],
        endpoint: 'http://127.0.0.1:11434/api/chat',
        apiKey: '',
        temperature: 0.0,
        sourceLang: '繁體中文',
        targetLang: '越南文',
        sourceLabel: '中文',
        targetLabel: 'Tiếng Việt',
        template: '{source}\n{translation}',
        extraInstructions: [],
        glossary: {},
        allowedProcesses: [],
        hotkeyModifiers: ['ctrl', 'alt'],
        hotkeyKey: 'enter',
      );

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        provider: j['provider'] as String? ?? 'Ollama',
        model: j['model'] as String? ?? 'translategemma',
        fallbackModels: _parseFallbackModels(j['fallbackModels']),
        endpoint: j['endpoint'] as String? ?? 'http://127.0.0.1:11434/api/chat',
        apiKey: j['apiKey'] as String? ?? '',
        temperature: (j['temperature'] as num?)?.toDouble() ?? 0.0,
        sourceLang: j['sourceLang'] as String? ?? '繁體中文',
        targetLang: j['targetLang'] as String? ?? '越南文',
        sourceLabel: j['sourceLabel'] as String? ?? '中文',
        targetLabel: j['targetLabel'] as String? ?? 'Tiếng Việt',
        template: j['template'] as String? ?? '{source}\n{translation}',
        extraInstructions: (j['extraInstructions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        glossary: (j['glossary'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
        allowedProcesses: (j['allowedProcesses'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        hotkeyModifiers: (j['hotkeyModifiers'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            ['ctrl', 'alt'],
        hotkeyKey: j['hotkeyKey'] as String? ?? 'enter',
        thinkingMode: j['thinkingMode'] as String? ?? 'quick',
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
        'sourceLabel': sourceLabel,
        'targetLabel': targetLabel,
        'template': template,
        'extraInstructions': extraInstructions,
        'glossary': glossary,
        'allowedProcesses': allowedProcesses,
        'hotkeyModifiers': hotkeyModifiers,
        'hotkeyKey': hotkeyKey,
        'thinkingMode': thinkingMode,
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
    String? sourceLabel,
    String? targetLabel,
    String? template,
    List<String>? extraInstructions,
    Map<String, String>? glossary,
    List<String>? allowedProcesses,
    List<String>? hotkeyModifiers,
    String? hotkeyKey,
    String? thinkingMode,
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
        sourceLabel: sourceLabel ?? this.sourceLabel,
        targetLabel: targetLabel ?? this.targetLabel,
        template: template ?? this.template,
        extraInstructions: extraInstructions ?? this.extraInstructions,
        glossary: glossary ?? this.glossary,
        allowedProcesses: allowedProcesses ?? this.allowedProcesses,
        hotkeyModifiers: hotkeyModifiers ?? this.hotkeyModifiers,
        hotkeyKey: hotkeyKey ?? this.hotkeyKey,
        thinkingMode: thinkingMode ?? this.thinkingMode,
      );

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
