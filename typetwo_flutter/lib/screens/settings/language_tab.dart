import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';

class LanguageTab extends StatefulWidget {
  const LanguageTab({super.key});

  @override
  State<LanguageTab> createState() => _LanguageTabState();
}

class _LanguageTabState extends State<LanguageTab> {
  late TextEditingController _srcLang, _tgtLang, _srcLabel, _tgtLabel, _tmpl;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<ConfigProvider>().config;
    _srcLang = TextEditingController(text: cfg.sourceLang);
    _tgtLang = TextEditingController(text: cfg.targetLang);
    _srcLabel = TextEditingController(text: cfg.sourceLabel);
    _tgtLabel = TextEditingController(text: cfg.targetLabel);
    _tmpl = TextEditingController(text: cfg.template);
  }

  @override
  void dispose() {
    for (final c in [_srcLang, _tgtLang, _srcLabel, _tgtLabel, _tmpl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _commit() {
    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(
      sourceLang: _srcLang.text.trim(),
      targetLang: _tgtLang.text.trim(),
      sourceLabel: _srcLabel.text.trim(),
      targetLabel: _tgtLabel.text.trim(),
      template: _tmpl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row('翻譯來源', _srcLang, '例：繁體中文'),
        _row('翻譯目標', _tgtLang, '例：越南文'),
        _row('來源標題', _srcLabel, '例：中文'),
        _row('目標標題', _tgtLabel, '例：Tiếng Việt'),
        const SizedBox(height: 16),
        _label('輸出格式'),
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

  Widget _row(String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (_) => _commit(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
