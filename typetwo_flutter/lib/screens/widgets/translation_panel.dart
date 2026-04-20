import 'package:flutter/material.dart';

class TranslationInputArea extends StatelessWidget {
  const TranslationInputArea({
    super.key,
    required this.controller,
    required this.onTranslate,
    required this.translating,
  });
  final TextEditingController controller;
  final VoidCallback onTranslate;
  final bool translating;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        enabled: !translating,
        decoration: const InputDecoration(
          hintText: '貼上或輸入要翻譯的文字…',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(12),
        ),
        textAlignVertical: TextAlignVertical.top,
        onSubmitted: (_) => onTranslate(),
      ),
    );
  }
}

class TranslationActionRow extends StatelessWidget {
  const TranslationActionRow({
    super.key,
    required this.translating,
    required this.hasOutput,
    required this.onTranslate,
    required this.onCopy,
  });
  final bool translating;
  final bool hasOutput;
  final VoidCallback onTranslate;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: translating ? null : onTranslate,
          icon: translating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.translate),
          label: Text(translating ? '翻譯中…' : '翻譯'),
        ),
        const SizedBox(width: 8),
        if (hasOutput)
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('複製結果'),
          ),
      ],
    );
  }
}

class TranslationOutputArea extends StatelessWidget {
  const TranslationOutputArea({
    super.key,
    required this.output,
    required this.error,
    required this.translating,
  });
  final String output;
  final String? error;
  final bool translating;

  @override
  Widget build(BuildContext context) {
    if (translating) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.error),
        ),
        child: SelectableText(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      );
    }
    if (output.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('翻譯結果將顯示在此', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        output,
        style: const TextStyle(height: 1.6),
      ),
    );
  }
}
