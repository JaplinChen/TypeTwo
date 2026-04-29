import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/providers/config_provider.dart';
import 'package:typetwo/providers/locale_provider.dart';
import 'package:typetwo/screens/settings/glossary_tab.dart';

void main() {
  testWidgets('詞彙表搜尋會依原文與譯文篩選清單', (tester) async {
    final configProvider = ConfigProvider()
      ..update(
        AppConfig.defaults().copyWith(
          glossary: {
            '一般': 'Thong thuong',
            '入口網站': 'Portal',
            '上傳': 'Tai len',
          },
        ),
      );

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
}
