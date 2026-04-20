import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../services/translate_service.dart';
import 'settings/settings_screen.dart';
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

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _AboutDialog(),
    );
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
            onPressed: () => _showAbout(context),
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

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.translate, size: 36, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text('TypeTwo', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('v1.0.0', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline)),
          const SizedBox(height: 16),
          Text(
            '雙語輸出翻譯工具\n複製文字，按下快捷鍵，\n剪貼簿自動變成原文 + 譯文格式。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 8),
          _InfoRow(label: '快捷鍵', value: 'Ctrl + Alt + Enter'),
          const SizedBox(height: 4),
          _InfoRow(label: '支援引擎', value: 'Ollama · OpenAI · Azure · Gemini'),
          const SizedBox(height: 12),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: scheme.outline, fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
