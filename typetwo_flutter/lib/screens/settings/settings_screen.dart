import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../platform/hotkey_service.dart';
import '../../providers/bridge_provider.dart';
import '../../providers/config_provider.dart';
import 'engine_tab.dart';
import 'hotkey_tab.dart';
import 'language_tab.dart';
import 'rules_tab.dart';
import 'glossary_tab.dart';
import 'processes_tab.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tabCount = Platform.isWindows ? 6 : 4;
    _tabs = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final configProvider = context.read<ConfigProvider>();
    final hotkeyService = Platform.isWindows ? context.read<HotkeyService>() : null;
    try {
      final synced = await configProvider.save(configProvider.config);
      if (Platform.isWindows) {
        await hotkeyService!.reregister(configProvider.config);
      }
      if (!mounted) return;
      final bridge = context.read<BridgeProvider>();
      if (bridge.isRunning) {
        final restart = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('重啟 Bridge'),
            content: const Text('設定已儲存。\n需重啟 TypeTwo.exe 才會生效，現在重啟？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('稍後')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('重啟')),
            ],
          ),
        );
        if (!mounted) return;
        if (restart == true) {
          await bridge.stop();
          await Future.delayed(const Duration(milliseconds: 800));
          if (!mounted) return;
          await bridge.start();
        }
      }
      if (!mounted) return;
      if (Platform.isWindows && !synced) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('設定已儲存，但無法同步至 TypeTwo.exe 目錄，請手動重啟 Bridge'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定已儲存'), duration: Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('儲存'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            const Tab(text: '翻譯引擎'),
            const Tab(text: '語言設定'),
            const Tab(text: '翻譯規則'),
            const Tab(text: '詞彙表'),
            if (Platform.isWindows) const Tab(text: '限定程式'),
            if (Platform.isWindows) const Tab(text: '快捷鍵'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const EngineTab(),
          const LanguageTab(),
          const RulesTab(),
          const GlossaryTab(),
          if (Platform.isWindows) const ProcessesTab(),
          if (Platform.isWindows) const HotkeyTab(),
        ],
      ),
    );
  }
}
