import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_constants.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';

class LanguageTab extends StatefulWidget {
  const LanguageTab({super.key});

  @override
  State<LanguageTab> createState() => _LanguageTabState();
}

class _LanguageTabState extends State<LanguageTab> {
  late String _srcLang;
  late String _tgtLang;
  String? _secondTgtLang;
  late TextEditingController _tmpl;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<ConfigProvider>().config;
    _srcLang = cfg.sourceLang;
    _tgtLang = cfg.targetLang;
    _secondTgtLang = cfg.secondTargetLang;
    _tmpl = TextEditingController(text: cfg.template);
  }

  @override
  void dispose() {
    _tmpl.dispose();
    super.dispose();
  }

  void _commit() {
    final p = context.read<ConfigProvider>();
    p.updateQuiet(p.config.copyWith(
      sourceLang: _srcLang,
      targetLang: _tgtLang,
      secondTargetLang: _secondTgtLang,
      template: _tmpl.text,
    ));
  }

  bool _isKnownSrc(String v) => kSrcLanguages.any((e) => e.$1 == v);
  bool _isKnownTgt(String v) => kTgtLanguages.any((e) => e.$1 == v);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    final srcItems = [
      ...kSrcLanguages.map((e) => (e.$1, s.langName(e.$1))),
      if (!_isKnownSrc(_srcLang)) (_srcLang, _srcLang),
    ];
    final tgtItems = [
      ...kTgtLanguages.map((e) => (e.$1, s.langName(e.$1))),
      if (!_isKnownTgt(_tgtLang)) (_tgtLang, _tgtLang),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _dropRow(s.srcLang, _srcLang, srcItems, (v) {
          if (v == null) return;
          setState(() => _srcLang = v);
          _commit();
        }),
        _dropRow(s.tgtLang, _tgtLang, tgtItems, (v) {
          if (v == null) return;
          setState(() => _tgtLang = v);
          _commit();
        }),
        if (_srcLang == kAutoDetectLang)
          _dropRow(
            s.secondTgtLang,
            _secondTgtLang ?? '',
            [('', '—'), ...tgtItems],
            (v) {
              setState(() => _secondTgtLang = (v == null || v.isEmpty) ? null : v);
              _commit();
            },
          ),
        const SizedBox(height: 16),
        _sectionLabel(s.outputFormat),
        TextField(
          controller: _tmpl,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          onChanged: (_) => _commit(),
        ),
        const SizedBox(height: 6),
        Text(
          s.availableVars,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _dropRow(
    String label,
    String value,
    List<(String, String)> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: items
                  .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
