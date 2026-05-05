import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/config_provider.dart';
import '../providers/locale_provider.dart';
import '../services/provider_error.dart';
import '../services/translate_service.dart';
import 'settings/settings_screen.dart';
import 'widgets/about_dialog.dart';
import 'widgets/bridge_status_bar.dart';
import 'widgets/locale_switch.dart';
import 'widgets/translation_panel.dart';
import 'widgets/update_dialog.dart';
import '../services/update_service.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final err = context.read<ConfigProvider>().error;
      if (err == null) {
        _checkForUpdateSilently();
        return;
      }
      final s = context.read<LocaleProvider>().strings;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(s.configErrorTitle),
          content: Text(err),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.close),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _checkForUpdateSilently() async {
    try {
      final info = await UpdateService.checkForUpdate();
      if (info == null || !mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => UpdateDialog(info: info),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final locale = context.read<LocaleProvider>().locale;
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
      setState(() => _error = formatProviderError(e, locale: locale));
    } finally {
      setState(() => _translating = false);
    }
  }

  Future<void> _showCorrectDialog() async {
    final source = _inputCtrl.text.trim();
    if (source.isEmpty) return;
    final s = context.read<LocaleProvider>().strings;
    final tgtCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.correctTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              readOnly: true,
              controller: TextEditingController(text: source),
              decoration: InputDecoration(
                labelText: s.correctSrc,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tgtCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.correctTgt,
                hintText: s.correctHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.save),
          ),
        ],
      ),
    );
    final correction = tgtCtrl.text.trim();
    tgtCtrl.dispose();
    if (confirmed != true || !mounted) return;
    if (correction.isEmpty) return;
    final p = context.read<ConfigProvider>();
    final updated = {...p.config.glossary, source: correction};
    await p.save(p.config.copyWith(glossary: updated));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.addedToGlossary),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copyOutput() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    final s = context.read<LocaleProvider>().strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.copied), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;
    final s = context.watch<LocaleProvider>().strings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TypeTwo'),
        actions: [
          const LocaleSwitch(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: s.about,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AppAboutDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: s.settings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          if (isWindows)
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              tooltip: s.quit,
              onPressed: () => windowManager.destroy(),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              onCorrect: _showCorrectDialog,
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
