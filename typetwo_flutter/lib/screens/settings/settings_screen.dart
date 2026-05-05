import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../platform/hotkey_service.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';
import '../widgets/locale_switch.dart';
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
    final s = context.read<LocaleProvider>().strings;
    final configProvider = context.read<ConfigProvider>();
    final hotkeyService =
        Platform.isWindows ? context.read<HotkeyService>() : null;
    try {
      await configProvider.save(configProvider.config);
      if (Platform.isWindows) {
        await hotkeyService!.reregister(configProvider.config);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.saved), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('儲存失敗：$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings),
        actions: [
          const LocaleSwitch(),
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(s.save),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: s.tabEngine),
            Tab(text: s.tabLanguage),
            Tab(text: s.tabRules),
            Tab(text: s.tabGlossary),
            if (Platform.isWindows) Tab(text: s.tabProcesses),
            if (Platform.isWindows) Tab(text: s.tabHotkey),
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
