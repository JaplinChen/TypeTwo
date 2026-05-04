from vi_normalizer import apply_vi_normalization

VI = "越南文"
ZH = "繁體中文"


def norm(text):
    return apply_vi_normalization(text, VI)


# ── No-op ─────────────────────────────────────────────────────────────────────

def test_no_op_for_non_vietnamese():
    assert apply_vi_normalization("你好。", ZH) == "你好。"


# ── Punctuation ───────────────────────────────────────────────────────────────

def test_sentence_punctuation():
    assert norm("Xin chào。") == "Xin chào."
    assert norm("Sao vậy？") == "Sao vậy?"
    assert norm("Tuyệt！") == "Tuyệt!"
    assert norm("Cảm ơn，bạn") == "Cảm ơn,bạn"
    assert norm("táo、cam、chuối") == "táo,cam,chuối"


def test_book_title_marks():
    assert norm("《Tam Quốc》") == '"Tam Quốc"'
    assert norm("「Xin chào」") == '"Xin chào"'
    assert norm("【Thông báo】") == "[Thông báo]"


def test_double_ellipsis():
    assert norm("Xin chờ……") == "Xin chờ…"


def test_double_dash():
    assert norm("Hà Nội——thủ đô") == "Hà Nội—thủ đô"


def test_fullwidth_space():
    assert norm("Xin　chào") == "Xin chào"


# ── Time ──────────────────────────────────────────────────────────────────────

def test_time_hm():
    assert norm("10點30分") == "10 giờ 30 phút"
    assert norm("8點05分") == "8 giờ 05 phút"


def test_time_half():
    assert norm("10點半") == "10 giờ rưỡi"


def test_time_hour_only():
    assert norm("10點") == "10 giờ"
    assert norm("9點整") == "9 giờ"  # 整 = "on the dot", consumed


def test_time_with_period():
    assert norm("上午10點30分") == "10 giờ 30 phút sáng"
    assert norm("下午3點半") == "3 giờ rưỡi chiều"
    assert norm("凌晨2點") == "2 giờ rạng sáng"


def test_time_of_day_standalone():
    assert norm("下午 3:00 họp") == "chiều 3:00 họp"
    assert norm("晚上 8:00") == "tối 8:00"


# ── Weekdays ──────────────────────────────────────────────────────────────────

def test_weekdays_xingqi():
    assert norm("星期一") == "thứ Hai"
    assert norm("星期三") == "thứ Tư"
    assert norm("星期日") == "Chủ nhật"


def test_weekdays_zhou():
    assert norm("週五") == "thứ Sáu"
    assert norm("週日") == "Chủ nhật"


def test_weekdays_libai():
    assert norm("禮拜天") == "Chủ nhật"
    assert norm("禮拜四") == "thứ Năm"


# ── Months ────────────────────────────────────────────────────────────────────

def test_months_chinese_chars():
    assert norm("一月") == "tháng 1"
    assert norm("十月") == "tháng 10"
    assert norm("十一月") == "tháng 11"
    assert norm("十二月") == "tháng 12"


def test_month_fen():
    assert norm("5月份") == "tháng 5"
    assert norm("12月份") == "tháng 12"


def test_month_standalone_numeric():
    assert norm("5月開始") == "tháng 5開始"


def test_month_not_converted_when_followed_by_day():
    # Date converter handles X月X日; vi_normalizer should not double-convert
    assert norm("3月25日") == "3月25日"


# ── Ordinals ──────────────────────────────────────────────────────────────────

def test_ordinals_1_to_10():
    assert norm("第一") == "thứ nhất"
    assert norm("第四") == "thứ tư"
    assert norm("第十") == "thứ mười"


def test_ordinals_numeric():
    assert norm("第11") == "thứ 11"
    assert norm("第25") == "thứ 25"


# ── Percentages & fractions ───────────────────────────────────────────────────

def test_percent():
    assert norm("百分之50") == "50%"
    assert norm("百分之12.5") == "12.5%"
    assert norm("百分之100") == "100%"


def test_fraction():
    assert norm("4分之3") == "3/4"
    assert norm("3分之1") == "1/3"
    assert norm("2分之1") == "1/2"


# ── Units ─────────────────────────────────────────────────────────────────────

def test_units():
    assert norm("25歲") == "25 tuổi"
    assert norm("10公里") == "10 km"
    assert norm("5公斤") == "5 kg"
    assert norm("170公分") == "170 cm"
    assert norm("1.5升") == "1.5 lít"
    assert norm("36度") == "36 độ"
    assert norm("100平方公尺") == "100 m²"
    assert norm("5平方公里") == "5 km²"


def test_unit_longer_first():
    # 平方公尺 must not be partially matched as 公尺
    assert norm("100平方公尺") == "100 m²"
    assert norm("100公尺") == "100 m"


# ── Honorifics ────────────────────────────────────────────────────────────────

def test_honorifics():
    assert norm("先生") == "ông"
    assert norm("女士") == "bà"
    assert norm("小姐") == "cô"
    assert norm("醫生") == "bác sĩ"
    assert norm("教授") == "giáo sư"
    assert norm("同學") == "bạn học"


# ── Formal terms ─────────────────────────────────────────────────────────────

def test_formal_terms():
    assert norm("貴公司") == "quý công ty"
    assert norm("本公司") == "công ty chúng tôi"
    assert norm("本人") == "tôi"
    assert norm("各位") == "quý vị"
    assert norm("此致") == "Trân trọng"
    assert norm("敬啟者") == "Kính gửi"


# ── Combined ──────────────────────────────────────────────────────────────────

def test_mixed():
    assert norm("Họp《dự án》lúc 下午 3:00，mời tham dự。") == \
        'Họp"dự án"lúc chiều 3:00,mời tham dự.'
    # 各位→quý vị, 先生→ông (no space between since none in source), ，→,, 。→.
    assert norm("各位先生，會議於星期三下午2點30分開始。") == \
        "quý vịông,會議於thứ Tư2 giờ 30 phút chiều開始."
