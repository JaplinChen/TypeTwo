import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:window_manager/window_manager.dart';
import 'platform/hotkey_service.dart';
import 'platform/tray_service.dart';
import 'providers/config_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'services/instance_manager.dart';

final _hotkeyService = HotkeyService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    if (!InstanceManager.acquire()) {
      // Another instance is running; it has been signalled to show. Exit.
      exit(0);
    }

    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();

    const opts = WindowOptions(
      size: Size(960, 660),
      minimumSize: Size(720, 560),
      center: true,
      title: 'TypeTwo',
    );
    await windowManager.waitUntilReadyToShow(opts, () async {
      await windowManager.show();
    });
    await windowManager.setPreventClose(true);
  }

  final configProvider = ConfigProvider();
  await configProvider.load();

  final localeProvider = LocaleProvider();
  await localeProvider.load();

  if (Platform.isWindows) {
    await TrayService().init(localeProvider.locale);

    await _hotkeyService.register(
      () async => configProvider.config,
      getLocale: () => localeProvider.locale,
    );
  }

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: configProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        if (Platform.isWindows)
          Provider<HotkeyService>.value(value: _hotkeyService),
      ],
      child: const TypeTwoApp(),
    ),
  );
}

class TypeTwoApp extends StatelessWidget {
  const TypeTwoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TypeTwo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6AF0),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6AF0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) windowManager.addListener(this);
  }

  @override
  void dispose() {
    if (Platform.isWindows) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
