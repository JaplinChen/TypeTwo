import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

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
    final s = context.watch<LocaleProvider>().strings;
    return SizedBox(
      height: 160,
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        enabled: !translating,
        decoration: InputDecoration(
          hintText: s.pasteHint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
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
    final s = context.watch<LocaleProvider>().strings;
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
          label: Text(translating ? s.translating : s.translate),
        ),
        const SizedBox(width: 8),
        if (hasOutput)
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, size: 16),
            label: Text(s.copyResult),
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
    final s = context.watch<LocaleProvider>().strings;
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
        child: Center(
          child: Text(s.resultPlaceholder, style: const TextStyle(color: Colors.grey)),
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
