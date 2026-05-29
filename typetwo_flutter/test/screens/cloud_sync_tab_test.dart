import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:typetwo/models/app_config.dart';
import 'package:typetwo/providers/config_provider.dart';
import 'package:typetwo/providers/locale_provider.dart';
import 'package:typetwo/screens/settings/cloud_sync_tab.dart';
import 'package:typetwo/services/glossary_remote_service.dart';

Future<ConfigProvider> _pumpCloudSyncTab(
  WidgetTester tester,
  AppConfig config,
) async =>
    _pumpCloudSyncTabWithProvider(tester, ConfigProvider()..update(config));

Future<T> _pumpCloudSyncTabWithProvider<T extends ConfigProvider>(
  WidgetTester tester,
  T configProvider,
) async {
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
    final syncButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('cloudSyncButton')),
    );
    expect(syncButton.onPressed, isNull);
  });

  testWidgets('雲端同步頁登入後顯示目前帳號與角色', (tester) async {
    await _pumpCloudSyncTab(
      tester,
      AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
        glossarySyncEmail: 'editor@example.com',
        glossarySyncToken: 'token-1',
        glossarySyncRole: 'editor',
      ),
    );

    expect(find.text('帳號：editor@example.com'), findsOneWidget);
    expect(find.text('角色：editor'), findsOneWidget);
    final importButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('cloudSyncImportPreviewButton')),
    );
    expect(importButton.onPressed, isNotNull);
    final exportButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('cloudSyncExportRemoteButton')),
    );
    expect(exportButton.onPressed, isNotNull);
    final syncButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('cloudSyncButton')),
    );
    expect(syncButton.onPressed, isNotNull);
  });

  testWidgets('雲端同步頁未登入時會提示登入並停用同步', (tester) async {
    await _pumpCloudSyncTab(
      tester,
      AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
        glossarySyncEmail: 'editor@example.com',
      ),
    );

    expect(find.textContaining('需要登入'), findsOneWidget);
    final syncButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('cloudSyncButton')),
    );
    expect(syncButton.onPressed, isNull);
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

  testWidgets('雲端同步頁 pending review 可搜尋並批次核准', (tester) async {
    final provider = _FakeReviewConfigProvider()
      ..update(AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
        glossarySyncEmail: 'editor@example.com',
        glossarySyncToken: 'token-1',
        glossarySyncRole: 'editor',
      ));
    await _pumpCloudSyncTabWithProvider(tester, provider);

    await tester.tap(find.text('審核'));
    await tester.pumpAndSettle();

    expect(find.text('入口網站'), findsOneWidget);
    expect(find.text('採購'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('pendingGlossarySearchField')),
      '入口',
    );
    await tester.pumpAndSettle();

    expect(find.text('入口網站'), findsOneWidget);
    expect(find.text('採購'), findsNothing);

    await tester.tap(find.text('選取篩選結果'));
    await tester.pumpAndSettle();
    expect(find.text('已選取 1 筆'), findsOneWidget);

    await tester.tap(find.text('批次核准'));
    await tester.pumpAndSettle();

    expect(provider.approvedIds, ['term-1']);
    expect(find.text('入口網站'), findsNothing);
  });

  testWidgets('雲端同步頁 pending review 可批次退回', (tester) async {
    final provider = _FakeReviewConfigProvider()
      ..update(AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
        glossarySyncEmail: 'editor@example.com',
        glossarySyncToken: 'token-1',
        glossarySyncRole: 'editor',
      ));
    await _pumpCloudSyncTabWithProvider(tester, provider);

    await tester.tap(find.text('審核'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pendingGlossaryTerm_term-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('批次退回'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('pendingGlossaryRejectReasonField')),
      '內容不適合',
    );
    await tester.tap(
      find.byKey(const ValueKey('pendingGlossaryRejectReasonSaveButton')),
    );
    await tester.pumpAndSettle();

    expect(provider.rejectedIds, ['term-2']);
    expect(provider.rejectedReasons, ['內容不適合']);
    expect(find.text('採購'), findsNothing);
  });

  testWidgets('雲端同步頁 pending review 可查看 history 與退回原因', (tester) async {
    final provider = _FakeReviewConfigProvider()
      ..update(AppConfig.defaults().copyWith(
        glossarySyncUrl: 'https://glossary.example.com',
        glossarySyncEmail: 'editor@example.com',
        glossarySyncToken: 'token-1',
        glossarySyncRole: 'editor',
      ));
    await _pumpCloudSyncTabWithProvider(tester, provider);

    await tester.tap(find.text('審核'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('pendingGlossaryHistory_term-2')),
    );
    await tester.pumpAndSettle();

    expect(provider.historyIds, ['term-2']);
    expect(find.text('紀錄：採購'), findsOneWidget);
    expect(find.textContaining('reject · rejected · v2'), findsOneWidget);
    expect(find.textContaining('原因：內容不適合'), findsOneWidget);

    await tester.tap(find.text('回復').first);
    await tester.pumpAndSettle();

    expect(provider.restoredHistoryIds, ['history-1']);
  });
}

class _FakeReviewConfigProvider extends ConfigProvider {
  _FakeReviewConfigProvider()
      : _pending = [
          const GlossaryRemoteTerm(
            id: 'term-1',
            sourceText: '入口網站',
            targetText: 'Portal',
            contextKey: 'global',
            status: 'pending',
          ),
          const GlossaryRemoteTerm(
            id: 'term-2',
            sourceText: '採購',
            targetText: 'Purchase',
            contextKey: '繁體中文-英文',
            status: 'pending',
          ),
        ];

  final List<GlossaryRemoteTerm> _pending;
  final List<String> approvedIds = [];
  final List<String> rejectedIds = [];
  final List<String?> rejectedReasons = [];
  final List<String> historyIds = [];
  final List<String> restoredHistoryIds = [];

  @override
  Future<List<GlossaryRemoteTerm>> listPendingGlossaryTerms() async =>
      List<GlossaryRemoteTerm>.from(_pending);

  @override
  Future<void> approveGlossaryTerms(Iterable<String> ids) async {
    final uniqueIds = ids.toSet();
    approvedIds.addAll(uniqueIds);
    _pending.removeWhere((term) => uniqueIds.contains(term.id));
  }

  @override
  Future<void> rejectGlossaryTerms(Iterable<String> ids,
      {String? reason}) async {
    final uniqueIds = ids.toSet();
    rejectedIds.addAll(uniqueIds);
    rejectedReasons.addAll(uniqueIds.map((_) => reason));
    _pending.removeWhere((term) => uniqueIds.contains(term.id));
  }

  @override
  Future<List<GlossaryRemoteTermHistory>> listGlossaryTermHistory(
      String id) async {
    historyIds.add(id);
    return [
      GlossaryRemoteTermHistory(
        id: 'history-1',
        termId: id,
        sourceText: '採購',
        targetText: 'Purchase',
        contextKey: '繁體中文-英文',
        status: 'pending',
        version: 1,
        operation: 'create',
        reason: null,
        changedAt: DateTime.utc(2026, 5, 29, 1, 2),
      ),
      GlossaryRemoteTermHistory(
        id: 'history-2',
        termId: id,
        sourceText: '採購',
        targetText: 'Purchase',
        contextKey: '繁體中文-英文',
        status: 'rejected',
        version: 2,
        operation: 'reject',
        reason: '內容不適合',
        changedAt: DateTime.utc(2026, 5, 29, 2, 3),
      ),
    ];
  }

  @override
  Future<void> restoreGlossaryTermHistory({
    required String id,
    required String historyId,
  }) async {
    restoredHistoryIds.add(historyId);
  }
}
