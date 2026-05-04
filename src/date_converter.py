import re

# Vietnamese uses D/M/YYYY; Chinese uses YYYY/M/D or M/D.
# Applied as post-processing on translated output.

_DATE_LANGS = {"越南文"}

# YYYY/M/D or YYYY-M-D → D/M/YYYY or D-M-YYYY
_RE_YMD_SLASH = re.compile(r'(?<!\d)(\d{4})/(\d{1,2})/(\d{1,2})(?!\d)')
_RE_YMD_DASH = re.compile(r'(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)')

# M/D where day > 12 (unambiguous: day can't be a month)
_RE_MD_SLASH = re.compile(r'(?<!\d)(\d{1,2})/(\d{1,2})(?!\d)')

# Chinese 年月日 characters left untranslated in output
_RE_YMD_ZH = re.compile(r'(\d{4})年(\d{1,2})月(\d{1,2})日')
_RE_MD_ZH = re.compile(r'(\d{1,2})月(\d{1,2})日')


def _swap_md(m: re.Match) -> str:
    mo, d = int(m.group(1)), int(m.group(2))
    if 1 <= mo <= 12 and 13 <= d <= 31:
        return f"{m.group(2)}/{m.group(1)}"
    return m.group(0)


def apply_date_conversion(text: str, target_lang: str) -> str:
    if target_lang not in _DATE_LANGS:
        return text
    text = _RE_YMD_ZH.sub(lambda m: f"Ngày {m.group(3)} tháng {m.group(2)} năm {m.group(1)}", text)
    text = _RE_MD_ZH.sub(lambda m: f"ngày {m.group(2)} tháng {m.group(1)}", text)
    text = _RE_YMD_SLASH.sub(lambda m: f"{m.group(3)}/{m.group(2)}/{m.group(1)}", text)
    text = _RE_YMD_DASH.sub(lambda m: f"{m.group(3)}-{m.group(2)}-{m.group(1)}", text)
    text = _RE_MD_SLASH.sub(_swap_md, text)
    return text
