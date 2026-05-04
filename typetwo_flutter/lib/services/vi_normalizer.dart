// Post-processing for Chinese→Vietnamese: fix patterns that LLMs commonly miss.
class ViNormalizer {
  static const _viLangs = {'越南文'};

  // ── Punctuation ─────────────────────────────────────────────────────────────

  static const _punctPairs = [
    ('《', '"'), ('》', '"'), ('〈', '"'), ('〉', '"'),
    ('「', '"'), ('」', '"'), ('『', "'"), ('』', "'"),
    ('【', '['), ('】', ']'), ('〔', '('), ('〕', ')'),
  ];

  static const _punctSingles = {
    '。': '.', '，': ',', '、': ',',
    '；': ';', '：': ':', '！': '!', '？': '?', '　': ' ',
  };

  static final _reDoubleEllipsis = RegExp('……');
  static final _reDoubleDash = RegExp('——');

  // ── Time ────────────────────────────────────────────────────────────────────

  static const _todMap = {
    '凌晨': 'rạng sáng', '早上': 'sáng', '上午': 'sáng',
    '中午': 'trưa', '下午': 'chiều', '傍晚': 'chiều tối',
    '晚上': 'tối', '深夜': 'khuya', '半夜': 'nửa đêm',
  };

  static final _todPat =
      _todMap.keys.map(RegExp.escape).join('|');

  static final _reTodHm =
      RegExp('($_todPat)(\\d+)點(\\d+)分');
  static final _reTodHalf =
      RegExp('($_todPat)(\\d+)點半');
  static final _reTodH =
      RegExp('($_todPat)(\\d+)點(?!半|\\d)');

  static final _reTimeHm = RegExp(r'(\d+)點(\d+)分');
  static final _reTimeHalf = RegExp(r'(\d+)點半');
  static final _reTimeH = RegExp(r'(\d+)點整?(?!半|\d|分)');

  // ── Weekdays ─────────────────────────────────────────────────────────────────

  static const _weekdayMap = {
    '星期一': 'thứ Hai', '星期二': 'thứ Ba', '星期三': 'thứ Tư',
    '星期四': 'thứ Năm', '星期五': 'thứ Sáu', '星期六': 'thứ Bảy',
    '星期日': 'Chủ nhật', '星期天': 'Chủ nhật',
    '週一': 'thứ Hai', '週二': 'thứ Ba', '週三': 'thứ Tư',
    '週四': 'thứ Năm', '週五': 'thứ Sáu', '週六': 'thứ Bảy',
    '週日': 'Chủ nhật', '週天': 'Chủ nhật',
    '禮拜一': 'thứ Hai', '禮拜二': 'thứ Ba', '禮拜三': 'thứ Tư',
    '禮拜四': 'thứ Năm', '禮拜五': 'thứ Sáu', '禮拜六': 'thứ Bảy',
    '禮拜日': 'Chủ nhật', '禮拜天': 'Chủ nhật',
  };

  // ── Months ───────────────────────────────────────────────────────────────────

  // Ordered longer-first: 十二月 before 十月 before 二月, etc.
  static const _monthPairs = [
    ('十二月', 'tháng 12'), ('十一月', 'tháng 11'), ('十月', 'tháng 10'),
    ('九月', 'tháng 9'), ('八月', 'tháng 8'), ('七月', 'tháng 7'),
    ('六月', 'tháng 6'), ('五月', 'tháng 5'), ('四月', 'tháng 4'),
    ('三月', 'tháng 3'), ('二月', 'tháng 2'), ('一月', 'tháng 1'),
  ];

  static final _reMonthFen = RegExp(r'(\d{1,2})月份');
  static final _reMonthStandalone = RegExp(r'(\d{1,2})月(?!\d|份|日)');

  // ── Ordinals ─────────────────────────────────────────────────────────────────

  static const _ordinalMap = {
    '第一': 'thứ nhất', '第二': 'thứ hai', '第三': 'thứ ba',
    '第四': 'thứ tư', '第五': 'thứ năm', '第六': 'thứ sáu',
    '第七': 'thứ bảy', '第八': 'thứ tám', '第九': 'thứ chín',
    '第十': 'thứ mười',
  };

  static final _reOrdinalNum = RegExp(r'第(\d+)');

  // ── Percentages & fractions ──────────────────────────────────────────────────

  static final _rePercent =
      RegExp(r'百分之(\d+(?:[.,]\d+)?)');
  static final _reFraction = RegExp(r'(\d+)分之(\d+)');

  // ── Units ────────────────────────────────────────────────────────────────────

  static final _unitSubs = <(RegExp, String)>[
    (RegExp(r'(\d+(?:\.\d+)?)\s*平方公里'), r'\1 km²'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*平方公尺'), r'\1 m²'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*公里'), r'\1 km'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*公斤'), r'\1 kg'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*公尺'), r'\1 m'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*公分'), r'\1 cm'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*毫米'), r'\1 mm'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*毫升'), r'\1 ml'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*升'), r'\1 lít'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*克'), r'\1 g'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*度(?![CF°])'), r'\1 độ'),
    (RegExp(r'(\d+(?:\.\d+)?)\s*歲'), r'\1 tuổi'),
  ];

  // ── Honorifics ───────────────────────────────────────────────────────────────

  static const _honorificPairs = [
    ('醫生', 'bác sĩ'), ('教授', 'giáo sư'), ('同學', 'bạn học'),
    ('先生', 'ông'), ('女士', 'bà'), ('太太', 'bà'),
    ('夫人', 'bà'), ('小姐', 'cô'),
  ];

  // ── Formal / business terms ──────────────────────────────────────────────────

  static const _formalPairs = [
    ('特此通知', 'Đặc biệt thông báo'),
    ('敬啟者', 'Kính gửi'), ('敬禮', 'Kính trọng'), ('此致', 'Trân trọng'),
    ('貴公司', 'quý công ty'), ('貴單位', 'quý đơn vị'),
    ('貴校', 'quý trường'), ('貴方', 'quý vị'),
    ('本公司', 'công ty chúng tôi'), ('本單位', 'đơn vị chúng tôi'),
    ('本校', 'trường chúng tôi'), ('敝公司', 'công ty chúng tôi'),
    ('本人', 'tôi'), ('各位', 'quý vị'), ('諸位', 'quý vị'),
  ];

  static String apply(String text, String targetLang) {
    if (!_viLangs.contains(targetLang)) return text;

    // Punctuation
    for (final (zh, vi) in _punctPairs) {
      text = text.replaceAll(zh, vi);
    }
    _punctSingles.forEach((zh, vi) => text = text.replaceAll(zh, vi));
    text = text.replaceAll(_reDoubleEllipsis, '…');
    text = text.replaceAll(_reDoubleDash, '—');

    // Time: combined period+clock first (correct Vietnamese word order)
    text = text.replaceAllMapped(_reTodHm,
        (m) => '${m[2]} giờ ${m[3]} phút ${_todMap[m[1]]}');
    text = text.replaceAllMapped(_reTodHalf,
        (m) => '${m[2]} giờ rưỡi ${_todMap[m[1]]}');
    text = text.replaceAllMapped(_reTodH,
        (m) => '${m[2]} giờ ${_todMap[m[1]]}');
    text = text.replaceAllMapped(
        _reTimeHm, (m) => '${m[1]} giờ ${m[2]} phút');
    text = text.replaceAllMapped(
        _reTimeHalf, (m) => '${m[1]} giờ rưỡi');
    text = text.replaceAllMapped(_reTimeH, (m) => '${m[1]} giờ');
    // Standalone time-of-day words (no clock time following)
    _todMap.forEach((zh, vi) => text = text.replaceAll(zh, vi));

    // Weekdays
    _weekdayMap.forEach((zh, vi) => text = text.replaceAll(zh, vi));

    // Months
    for (final (zh, vi) in _monthPairs) {
      text = text.replaceAll(zh, vi);
    }
    text = text.replaceAllMapped(
        _reMonthFen, (m) => 'tháng ${m[1]}');
    text = text.replaceAllMapped(
        _reMonthStandalone, (m) => 'tháng ${m[1]}');

    // Ordinals
    _ordinalMap.forEach((zh, vi) => text = text.replaceAll(zh, vi));
    text = text.replaceAllMapped(
        _reOrdinalNum, (m) => 'thứ ${m[1]}');

    // Percentages & fractions
    text = text.replaceAllMapped(_rePercent, (m) => '${m[1]}%');
    text = text.replaceAllMapped(
        _reFraction, (m) => '${m[2]}/${m[1]}');

    // Units
    for (final (pat, repl) in _unitSubs) {
      text = text.replaceAllMapped(
          pat, (m) => repl.replaceFirst(r'\1', m[1]!));
    }

    // Honorifics
    for (final (zh, vi) in _honorificPairs) {
      text = text.replaceAll(zh, vi);
    }

    // Formal/business terms
    for (final (zh, vi) in _formalPairs) {
      text = text.replaceAll(zh, vi);
    }

    return text;
  }
}
