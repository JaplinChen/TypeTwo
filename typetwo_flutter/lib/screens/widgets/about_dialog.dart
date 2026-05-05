import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/update_service.dart';
import 'update_dialog.dart';

class AppAboutDialog extends StatefulWidget {
  const AppAboutDialog({super.key});

  @override
  State<AppAboutDialog> createState() => _AppAboutDialogState();
}

class _AppAboutDialogState extends State<AppAboutDialog> {
  bool _checking = false;

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    final s = context.read<LocaleProvider>().strings;
    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;
      if (info != null) {
        Navigator.pop(context);
        showDialog<void>(
          context: context,
          builder: (_) => UpdateDialog(info: info),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.alreadyLatest),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.updateCheckFailed),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AppLogo(),
          const SizedBox(height: 16),
          Text('TypeTwo',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('v1.0.13',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline)),
          const SizedBox(height: 16),
          Text(
            s.aboutDesc,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 8),
          _InfoRow(
            label: s.hotkeyLabel,
            value: context.select<ConfigProvider, String>(
              (p) => [...p.config.hotkeyModifiers, p.config.hotkeyKey]
                  .map((k) => k[0].toUpperCase() + k.substring(1))
                  .join('+'),
            ),
          ),
          const SizedBox(height: 4),
          _InfoRow(
            label: s.enginesLabel,
            value: 'Ollama · OpenAI · Azure · Gemini · Groq',
          ),
          const SizedBox(height: 12),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : _checkForUpdates,
          child: _checking
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(s.checkForUpdates),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.close),
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
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B6AF0), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B6AF0).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _bubble(rightAligned: false),
          const Icon(Icons.arrow_forward_rounded,
              color: Colors.white70, size: 14),
          _bubble(rightAligned: true),
        ],
      ),
    );
  }

  Widget _bubble({required bool rightAligned}) {
    return Row(
      children: [
        if (rightAligned) const Spacer(),
        Container(
          width: 36,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: rightAligned ? 0.4 : 0.9),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        if (!rightAligned) const Spacer(),
      ],
    );
  }
}
