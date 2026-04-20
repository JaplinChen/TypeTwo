import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:window_manager/window_manager.dart';
import 'platform/hotkey_service.dart';
import 'providers/bridge_provider.dart';
import 'providers/config_provider.dart';
import 'screens/home_screen.dart';

final _hotkeyService = HotkeyService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
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
    await windowManager.setPreventClose(false);
  }

  final configProvider = ConfigProvider();
  await configProvider.load();

  // Register Flutter hotkey; bridge status changes will unregister/re-register it.
  if (Platform.isWindows) {
    await _hotkeyService.register(() async => configProvider.config);
  }

  final bridgeProvider = BridgeProvider(
    onBridgeStatusChange: Platform.isWindows
        ? (running) => _hotkeyService.setBridgeActive(running)
        : null,
  );

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: configProvider),
        ChangeNotifierProvider.value(value: bridgeProvider),
        if (Platform.isWindows) Provider<HotkeyService>.value(value: _hotkeyService),
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
      home: const HomeScreen(),
    );
  }
}
