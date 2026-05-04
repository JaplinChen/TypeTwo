import re

# Post-processing for Chinese→Vietnamese: fix patterns that LLMs commonly miss.
# All rules are applied only when target language is Vietnamese.

_VI_LANGS = {"越南文"}

# ── Punctuation ───────────────────────────────────────────────────────────────

_PUNCT_PAIRS = [
    ('《', '"'), ('》', '"'),
    ('〈', '"'), ('〉', '"'),
    ('「', '"'), ('」', '"'),
    ('『', "'"), ('』', "'"),
    ('【', '['), ('】', ']'),
    ('〔', '('), ('〕', ')'),
]

_PUNCT_SINGLES = {
    '。': '.', '，': ',', '、': ',',
    '；': ';', '：': ':', '！': '!', '？': '?',
    '　': ' ',
}

_RE_DOUBLE_ELLIPSIS = re.compile('……')
_RE_DOUBLE_DASH = re.compile('——')

# ── Time ──────────────────────────────────────────────────────────────────────

_TOD_MAP = {
    '凌晨': 'rạng sáng', '早上': 'sáng', '上午': 'sáng',
    '中午': 'trưa', '下午': 'chiều', '傍晚': 'chiều tối',
    '晚上': 'tối', '深夜': 'khuya', '半夜': 'nửa đêm',
}
_TOD_PAT = '|'.join(re.escape(k) for k in _TOD_MAP)

# Combined: period + clock → Vietnamese word order (H giờ M phút period)
_RE_TOD_HM = re.compile(rf'({_TOD_PAT})(\d+)點(\d+)分')
_RE_TOD_HALF = re.compile(rf'({_TOD_PAT})(\d+)點半')
_RE_TOD_H = re.compile(rf'({_TOD_PAT})(\d+)點(?!半|\d)')

# Standalone clock time
_RE_TIME_HM = re.compile(r'(\d+)點(\d+)分')
_RE_TIME_HALF = re.compile(r'(\d+)點半')
_RE_TIME_H = re.compile(r'(\d+)點整?(?!半|\d|分)')

# ── Weekdays ──────────────────────────────────────────────────────────────────

_WEEKDAY_MAP = {
    '星期一': 'thứ Hai', '星期二': 'thứ Ba', '星期三': 'thứ Tư',
    '星期四': 'thứ Năm', '星期五': 'thứ Sáu', '星期六': 'thứ Bảy',
    '星期日': 'Chủ nhật', '星期天': 'Chủ nhật',
    '週一': 'thứ Hai', '週二': 'thứ Ba', '週三': 'thứ Tư',
    '週四': 'thứ Năm', '週五': 'thứ Sáu', '週六': 'thứ Bảy',
    '週日': 'Chủ nhật', '週天': 'Chủ nhật',
    '禮拜一': 'thứ Hai', '禮拜二': 'thứ Ba', '禮拜三': 'thứ Tư',
    '禮拜四': 'thứ Năm', '禮拜五': 'thứ Sáu', '禮拜六': 'thứ Bảy',
    '禮拜日': 'Chủ nhật', '禮拜天': 'Chủ nhật',
}

# ── Months ────────────────────────────────────────────────────────────────────

# Longer strings first: 十二月 before 十月 before 二月 etc.
_MONTH_PAIRS = [
    ('十二月', 'tháng 12'), ('十一月', 'tháng 11'), ('十月', 'tháng 10'),
    ('九月', 'tháng 9'), ('八月', 'tháng 8'), ('七月', 'tháng 7'),
    ('六月', 'tháng 6'), ('五月', 'tháng 5'), ('四月', 'tháng 4'),
    ('三月', 'tháng 3'), ('二月', 'tháng 2'), ('一月', 'tháng 1'),
]

# Numeric month still in Chinese output: 5月份 or 5月 (not followed by digit/份/日)
_RE_MONTH_FEN = re.compile(r'(\d{1,2})月份')
_RE_MONTH_STANDALONE = re.compile(r'(\d{1,2})月(?!\d|份|日)')

# ── Ordinals ──────────────────────────────────────────────────────────────────

# Hardcoded for 1–10 (Vietnamese has irregular forms: nhất, tư, etc.)
_ORDINAL_MAP = {
    '第一': 'thứ nhất', '第二': 'thứ hai', '第三': 'thứ ba',
    '第四': 'thứ tư', '第五': 'thứ năm', '第六': 'thứ sáu',
    '第七': 'thứ bảy', '第八': 'thứ tám', '第九': 'thứ chín',
    '第十': 'thứ mười',
}
# Numeric ordinals 第11+ → thứ N (digit form, acceptable in modern Vietnamese)
_RE_ORDINAL_NUM = re.compile(r'第(\d+)')

# ── Percentages & fractions ───────────────────────────────────────────────────

_RE_PERCENT = re.compile(r'百分之(\d+(?:[.,]\d+)?)')
_RE_FRACTION = re.compile(r'(\d+)分之(\d+)')

# ── Units ─────────────────────────────────────────────────────────────────────

# Longer patterns first (平方公里 before 公里, etc.)
_UNIT_SUBS = [
    (re.compile(r'(\d+(?:\.\d+)?)\s*平方公里'), r'\1 km²'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*平方公尺'), r'\1 m²'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*公里'), r'\1 km'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*公斤'), r'\1 kg'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*公尺'), r'\1 m'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*公分'), r'\1 cm'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*毫米'), r'\1 mm'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*毫升'), r'\1 ml'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*升'), r'\1 lít'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*克'), r'\1 g'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*度(?![CF°])'), r'\1 độ'),
    (re.compile(r'(\d+(?:\.\d+)?)\s*歲'), r'\1 tuổi'),
]

# ── Honorifics ────────────────────────────────────────────────────────────────

# Longer strings first to avoid partial matches
_HONORIFIC_PAIRS = sorted([
    ('先生', 'ông'), ('女士', 'bà'), ('太太', 'bà'), ('夫人', 'bà'),
    ('小姐', 'cô'), ('醫生', 'bác sĩ'), ('教授', 'giáo sư'),
    ('同學', 'bạn học'),
], key=lambda x: -len(x[0]))

# ── Formal / business terms ───────────────────────────────────────────────────

# Longer strings first
_FORMAL_PAIRS = sorted([
    ('特此通知', 'Đặc biệt thông báo'),
    ('貴公司', 'quý công ty'), ('貴單位', 'quý đơn vị'),
    ('貴校', 'quý trường'), ('貴方', 'quý vị'),
    ('本公司', 'công ty chúng tôi'), ('本單位', 'đơn vị chúng tôi'),
    ('本校', 'trường chúng tôi'), ('本人', 'tôi'),
    ('敝公司', 'công ty chúng tôi'),
    ('敬啟者', 'Kính gửi'), ('此致', 'Trân trọng'), ('敬禮', 'Kính trọng'),
    ('各位', 'quý vị'), ('諸位', 'quý vị'),
], key=lambda x: -len(x[0]))


def apply_vi_normalization(text: str, target_lang: str) -> str:
    if target_lang not in _VI_LANGS:
        return text

    # Punctuation
    for zh, vi in _PUNCT_PAIRS:
        text = text.replace(zh, vi)
    for zh, vi in _PUNCT_SINGLES.items():
        text = text.replace(zh, vi)
    text = _RE_DOUBLE_ELLIPSIS.sub('…', text)
    text = _RE_DOUBLE_DASH.sub('—', text)

    # Time (combined period+clock first to get correct word order)
    text = _RE_TOD_HM.sub(
        lambda m: f"{m.group(2)} giờ {m.group(3)} phút {_TOD_MAP[m.group(1)]}", text)
    text = _RE_TOD_HALF.sub(
        lambda m: f"{m.group(2)} giờ rưỡi {_TOD_MAP[m.group(1)]}", text)
    text = _RE_TOD_H.sub(
        lambda m: f"{m.group(2)} giờ {_TOD_MAP[m.group(1)]}", text)
    text = _RE_TIME_HM.sub(lambda m: f"{m.group(1)} giờ {m.group(2)} phút", text)
    text = _RE_TIME_HALF.sub(lambda m: f"{m.group(1)} giờ rưỡi", text)
    text = _RE_TIME_H.sub(lambda m: f"{m.group(1)} giờ", text)
    # Standalone time-of-day words (no clock time following)
    for zh, vi in _TOD_MAP.items():
        text = text.replace(zh, vi)

    # Weekdays
    for zh, vi in _WEEKDAY_MAP.items():
        text = text.replace(zh, vi)

    # Months
    for zh, vi in _MONTH_PAIRS:
        text = text.replace(zh, vi)
    text = _RE_MONTH_FEN.sub(lambda m: f"tháng {m.group(1)}", text)
    text = _RE_MONTH_STANDALONE.sub(lambda m: f"tháng {m.group(1)}", text)

    # Ordinals
    for zh, vi in _ORDINAL_MAP.items():
        text = text.replace(zh, vi)
    text = _RE_ORDINAL_NUM.sub(lambda m: f"thứ {m.group(1)}", text)

    # Percentages & fractions
    text = _RE_PERCENT.sub(lambda m: f"{m.group(1)}%", text)
    text = _RE_FRACTION.sub(lambda m: f"{m.group(2)}/{m.group(1)}", text)

    # Units
    for pat, repl in _UNIT_SUBS:
        text = pat.sub(repl, text)

    # Honorifics
    for zh, vi in _HONORIFIC_PAIRS:
        text = text.replace(zh, vi)

    # Formal/business terms
    for zh, vi in _FORMAL_PAIRS:
        text = text.replace(zh, vi)

    return text
