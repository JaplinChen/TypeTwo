import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/providers/config_provider.dart';
import 'package:typetwo/providers/locale_provider.dart';
import 'package:typetwo/screens/settings/glossary_tab.dart';

Future<ConfigProvider> _pumpGlossaryTab(
  WidgetTester tester,
  Map<String, String> glossary, {
  AppConfig? config,
}) async {
  final baseConfig = (config ?? AppConfig.defaults()).copyWith(
    glossary: glossary,
  );
  final configProvider = ConfigProvider()..update(baseConfig);

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
            height: 640,
            child: GlossaryTab(),
          ),
        ),
      ),
    ),
  );

  return configProvider;
}

void main() {
  testWidgets('詞彙表搜尋會依原文與譯文篩選清單', (tester) async {
    await _pumpGlossaryTab(tester, {
      '一般': 'Thong thuong',
      '入口網站': 'Portal',
      '上傳': 'Tai len',
    });

    expect(find.text('一般'), findsOneWidget);
    expect(find.text('入口網站'), findsOneWidget);
    expect(find.text('上傳'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('glossarySearchField')),
      'portal',
    );
    await tester.pump();

    expect(find.text('一般'), findsNothing);
    expect(find.text('入口網站'), findsOneWidget);
    expect(find.text('上傳'), findsNothing);
    expect(find.text('顯示 1 / 3 筆'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('glossarySearchField')),
      '沒有',
    );
    await tester.pump();

    expect(find.text('沒有符合的詞彙'), findsOneWidget);
  });

  testWidgets('詞彙表可修改既有原文與譯文', (tester) async {
    final configProvider = await _pumpGlossaryTab(tester, {
      '業務': 'Kinh doanh',
      '採購': 'Thu mua',
    });

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.edit_outlined).first,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('editGlossarySourceField')),
      '業務部',
    );
    await tester.enterText(
      find.byKey(const ValueKey('editGlossaryTargetField')),
      'Phong kinh doanh',
    );
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('業務'), findsNothing);
    expect(find.text('業務部'), findsOneWidget);
    expect(find.text('Phong kinh doanh'), findsOneWidget);
    expect(configProvider.config.glossary.containsKey('業務'), isFalse);
    expect(configProvider.config.glossary['業務部'], 'Phong kinh doanh');
    expect(configProvider.config.glossary['採購'], 'Thu mua');
  });

  testWidgets('詞彙表只顯示精簡同步列', (tester) async {
    await _pumpGlossaryTab(tester, {'申請': 'Nộp đơn'});

    expect(find.text('同步空間'), findsOneWidget);
    expect(find.text('尚未同步'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('glossarySyncTargetField')), findsOneWidget);
    expect(find.byKey(const ValueKey('glossarySyncUrlField')), findsNothing);
    expect(find.text('同步'), findsOneWidget);
  });

  testWidgets('詞彙表同步列未登入時會停用同步並提示登入', (tester) async {
    await _pumpGlossaryTab(
      tester,
      {'申請': 'Nộp đơn'},
      config: AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
        glossarySyncEmail: 'editor@example.com',
      ),
    );

    expect(find.textContaining('需要登入'), findsOneWidget);
    final syncButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('glossarySyncButton')),
    );
    expect(syncButton.onPressed, isNull);
  });
}
