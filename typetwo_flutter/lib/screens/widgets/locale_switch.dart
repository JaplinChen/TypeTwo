import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

class LocaleSwitch extends StatelessWidget {
  const LocaleSwitch({super.key});

  static const _locales = [('zh', '中'), ('en', 'EN'), ('vi', 'VI')];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LocaleProvider>();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _locales.length; i++) ...[
              if (i > 0)
                Container(width: 1, height: 20, color: cs.outlineVariant),
              _LangBtn(
                label: _locales[i].$2,
                active: prov.locale == _locales[i].$1,
                onTap: () => prov.setLocale(_locales[i].$1),
                isFirst: i == 0,
                isLast: i == _locales.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  const _LangBtn({
    required this.label,
    required this.active,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(7) : Radius.zero,
      right: isLast ? const Radius.circular(7) : Radius.zero,
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: radius,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
