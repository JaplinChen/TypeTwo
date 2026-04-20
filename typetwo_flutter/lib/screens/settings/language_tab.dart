import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_constants.dart';
import '../../providers/config_provider.dart';

class LanguageTab extends StatefulWidget {
  const LanguageTab({super.key});

  @override
  State<LanguageTab> createState() => _LanguageTabState();
}

class _LanguageTabState extends State<LanguageTab> {
  late String _srcLang;
  late String _tgtLang;
  late TextEditingController _srcLabel, _tgtLabel, _tmpl;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<ConfigProvider>().config;
    _srcLang = cfg.sourceLang;
    _tgtLang = cfg.targetLang;
    _srcLabel = TextEditingController(text: cfg.sourceLabel);
    _tgtLabel = TextEditingController(text: cfg.targetLabel);
    _tmpl = TextEditingController(text: cfg.template);
  }

  @override
  void dispose() {
    for (final c in [_srcLabel, _tgtLabel, _tmpl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _commit() {
    final p = context.read<ConfigProvider>();
    p.updateQuiet(p.config.copyWith(
      sourceLang: _srcLang,
      targetLang: _tgtLang,
      sourceLabel: _srcLabel.text.trim(),
      targetLabel: _tgtLabel.text.trim(),
      template: _tmpl.text,
    ));
  }

  bool _isKnownSrc(String v) => kSrcLanguages.any((e) => e.$1 == v);
  bool _isKnownTgt(String v) => kTgtLanguages.any((e) => e.$1 == v);

  @override
  Widget build(BuildContext context) {
    final srcItems = [
      ...kSrcLanguages,
      if (!_isKnownSrc(_srcLang)) (_srcLang, _srcLang),
    ];
    final tgtItems = [
      ...kTgtLanguages,
      if (!_isKnownTgt(_tgtLang)) (_tgtLang, _tgtLang),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _dropRow('翻譯來源', _srcLang, srcItems, (v) {
          if (v == null) return;
          setState(() {
            _srcLang = v;
            if (kDefaultLabels.containsKey(v)) {
              _srcLabel.text = kDefaultLabels[v]!;
            }
          });
          _commit();
        }),
        _dropRow('翻譯目標', _tgtLang, tgtItems, (v) {
          if (v == null) return;
          setState(() {
            _tgtLang = v;
            if (kDefaultLabels.containsKey(v)) {
              _tgtLabel.text = kDefaultLabels[v]!;
            }
          });
          _commit();
        }),
        _textRow('來源標題', _srcLabel),
        _textRow('目標標題', _tgtLabel),
        const SizedBox(height: 16),
        _sectionLabel('輸出格式'),
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
        const Text(
          '可用變數：{source_label}  {source}  {target_label}  {translation}',
          style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _textRow(String label, TextEditingController ctrl) {
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
            child: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (_) => _commit(),
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
