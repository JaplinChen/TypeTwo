import 'package:flutter/material.dart';

class AppAboutDialog extends StatelessWidget {
  const AppAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AppLogo(),
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
          const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 14),
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
