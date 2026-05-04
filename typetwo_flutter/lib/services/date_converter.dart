// Vietnamese uses D/M/YYYY; Chinese uses YYYY/M/D or M/D.
// Applied as post-processing on translated output.
class DateConverter {
  static const _dateLangs = {'越南文'};

  // Chinese 年月日 characters left untranslated in output
  static final _reYmdZh = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日');
  static final _reMdZh = RegExp(r'(\d{1,2})月(\d{1,2})日');
  // YYYY/M/D → D/M/YYYY
  static final _reYmdSlash =
      RegExp(r'(?<!\d)(\d{4})/(\d{1,2})/(\d{1,2})(?!\d)');
  // YYYY-M-D → D-M-YYYY
  static final _reYmdDash =
      RegExp(r'(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)');
  // M/D where day > 12 (unambiguous)
  static final _reMdSlash = RegExp(r'(?<!\d)(\d{1,2})/(\d{1,2})(?!\d)');

  static String apply(String text, String targetLang) {
    if (!_dateLangs.contains(targetLang)) return text;
    text = text.replaceAllMapped(
        _reYmdZh, (m) => 'Ngày ${m[3]} tháng ${m[2]} năm ${m[1]}');
    text = text.replaceAllMapped(
        _reMdZh, (m) => 'ngày ${m[2]} tháng ${m[1]}');
    text = text.replaceAllMapped(
        _reYmdSlash, (m) => '${m[3]}/${m[2]}/${m[1]}');
    text = text.replaceAllMapped(
        _reYmdDash, (m) => '${m[3]}-${m[2]}-${m[1]}');
    text = text.replaceAllMapped(_reMdSlash, _swapMd);
    return text;
  }

  static String _swapMd(Match m) {
    final mo = int.parse(m[1]!);
    final d = int.parse(m[2]!);
    if (mo >= 1 && mo <= 12 && d >= 13 && d <= 31) return '${m[2]}/${m[1]}';
    return m[0]!;
  }
}
