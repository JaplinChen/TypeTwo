import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/providers/config_provider.dart';
import 'package:typetwo/providers/locale_provider.dart';
import 'package:typetwo/screens/settings/engine_tab.dart';

Future<ConfigProvider> _pumpEngineTab(
  WidgetTester tester,
  AppConfig config,
) async {
  final configProvider = ConfigProvider()..update(config);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConfigProvider>.value(value: configProvider),
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 1200,
            child: EngineTab(),
          ),
        ),
      ),
    ),
  );

  return configProvider;
}

void main() {
  testWidgets('引擎頁切換 provider 前會保存目前表單草稿', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final configProvider = await _pumpEngineTab(
      tester,
      AppConfig.defaults().copyWith(
        provider: 'OpenAI',
        endpoint: 'https://api.openai.com/v1/chat/completions',
        model: 'gpt-4o',
        apiKey: 'old-openai-key',
        fallbackModels: ['gpt-4o-mini'],
        providerConfigs: {
          'Gemini': {
            'endpoint': '',
            'model': 'gemini-2.0-flash',
            'apiKey': 'gemini-key',
            'fallbackModels': <String>['gemini-1.5-flash'],
            'thinkingMode': 'thinking',
          },
        },
      ),
    );

    final fields = find.byType(TextField, skipOffstage: false);
    await tester.enterText(fields.at(0), ' https://openai.example/chat ');
    await tester.enterText(fields.at(1), ' gpt-4.1-mini ');
    await tester.enterText(fields.at(2), ' sk-new ');
    await tester.pump();

    await tester.tap(find.widgetWithText(ListTile, 'Gemini'));
    await tester.pumpAndSettle();

    final config = configProvider.config;
    final openAI = config.providerConfigs['OpenAI'];

    expect(config.provider, 'Gemini');
    expect(config.model, 'gemini-2.0-flash');
    expect(config.apiKey, 'gemini-key');
    expect(config.fallbackModels, ['gemini-1.5-flash']);
    expect(config.thinkingMode, 'thinking');
    expect(openAI?['endpoint'], 'https://openai.example/chat');
    expect(openAI?['model'], 'gpt-4.1-mini');
    expect(openAI?['apiKey'], 'sk-new');
    expect(openAI?['fallbackModels'], ['gpt-4o-mini']);
  });
}
