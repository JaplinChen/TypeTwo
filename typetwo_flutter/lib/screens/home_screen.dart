import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../services/translate_service.dart';
import 'settings/settings_screen.dart';
import 'widgets/about_dialog.dart';
import 'widgets/bridge_status_bar.dart';
import 'widgets/translation_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _inputCtrl = TextEditingController();
  String _output = '';
  bool _translating = false;
  String? _error;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _translating = true;
      _error = null;
      _output = '';
    });
    try {
      final cfg = context.read<ConfigProvider>().config;
      final result = await TranslateService.translate(text, cfg);
      setState(() => _output = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _translating = false);
    }
  }

  Future<void> _copyOutput() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已複製'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TypeTwo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '關於',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AppAboutDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWindows) const BridgeStatusBar(),
            if (isWindows) const WindowsHint(),
            TranslationInputArea(
              controller: _inputCtrl,
              onTranslate: _translate,
              translating: _translating,
            ),
            const SizedBox(height: 12),
            TranslationActionRow(
              translating: _translating,
              hasOutput: _output.isNotEmpty,
              onTranslate: _translate,
              onCopy: _copyOutput,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TranslationOutputArea(
                output: _output,
                error: _error,
                translating: _translating,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
