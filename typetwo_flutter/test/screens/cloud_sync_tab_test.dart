import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/providers/config_provider.dart';
import 'package:typetwo/providers/locale_provider.dart';
import 'package:typetwo/screens/settings/cloud_sync_tab.dart';

Future<ConfigProvider> _pumpCloudSyncTab(
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
            width: 1000,
            height: 700,
            child: CloudSyncTab(),
          ),
        ),
      ),
    ),
  );

  return configProvider;
}

void main() {
  testWidgets('雲端同步頁預設顯示 TypeTwo Server 設定', (tester) async {
    await _pumpCloudSyncTab(
      tester,
      AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
        glossarySyncEmail: 'editor@example.com',
      ),
    );

    expect(find.text('雲端同步'), findsOneWidget);
    expect(find.byKey(const ValueKey('cloudSyncTargetField')), findsOneWidget);
    expect(find.byKey(const ValueKey('cloudSyncUrlField')), findsOneWidget);
    expect(find.byKey(const ValueKey('cloudSyncEmailField')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cloudSyncPasswordField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cloudSyncTestConnectionButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cloudSyncRestoreBackupButton')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('cloudSyncButton')), findsOneWidget);
  });

  testWidgets('雲端同步頁可顯示本機雲端資料夾設定', (tester) async {
    final configProvider = await _pumpCloudSyncTab(
      tester,
      AppConfig.defaults().copyWith(
        glossarySyncTarget: GlossarySyncTargets.dropbox,
        glossarySyncLocalPath: 'D:\\Cloud\\TypeTwo',
      ),
    );

    expect(
      find.byKey(const ValueKey('cloudSyncLocalPathField')),
      findsOneWidget,
    );
    expect(find.text('選擇'), findsOneWidget);
    expect(configProvider.config.glossarySync.isCloudFolder, isTrue);
  });

  testWidgets('雲端同步頁可顯示 WebDAV 設定', (tester) async {
    final configProvider = await _pumpCloudSyncTab(
      tester,
      AppConfig.defaults().copyWith(
        glossarySyncTarget: GlossarySyncTargets.webDav,
        glossarySyncWebDavUrl:
            'https://cloud.example.com/remote.php/dav/files/me/TypeTwo',
        glossarySyncWebDavUser: 'me',
      ),
    );

    expect(
        find.byKey(const ValueKey('cloudSyncWebDavUrlField')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('cloudSyncWebDavUserField')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cloudSyncWebDavPasswordField')),
      findsOneWidget,
    );
    expect(configProvider.config.glossarySync.isWebDav, isTrue);
  });
}
