import unittest
from vi_normalizer import apply_vi_normalization

VI = "越南文"
ZH = "繁體中文"


def norm(text):
    return apply_vi_normalization(text, VI)


class ViNormalizerTest(unittest.TestCase):
    # ── No-op ─────────────────────────────────────────────────────────────────

    def test_no_op_for_non_vietnamese(self):
        self.assertEqual(apply_vi_normalization("你好。", ZH), "你好。")

    # ── Punctuation ───────────────────────────────────────────────────────────

    def test_sentence_punctuation(self):
        self.assertEqual(norm("Xin chào。"), "Xin chào.")
        self.assertEqual(norm("Sao vậy？"), "Sao vậy?")
        self.assertEqual(norm("Tuyệt！"), "Tuyệt!")
        self.assertEqual(norm("Cảm ơn，bạn"), "Cảm ơn,bạn")
        self.assertEqual(norm("táo、cam、chuối"), "táo,cam,chuối")

    def test_book_title_marks(self):
        self.assertEqual(norm("《Tam Quốc》"), '"Tam Quốc"')
        self.assertEqual(norm("「Xin chào」"), '"Xin chào"')
        self.assertEqual(norm("【Thông báo】"), "[Thông báo]")

    def test_double_ellipsis(self):
        self.assertEqual(norm("Xin chờ……"), "Xin chờ…")

    def test_double_dash(self):
        self.assertEqual(norm("Hà Nội——thủ đô"), "Hà Nội—thủ đô")

    def test_fullwidth_space(self):
        self.assertEqual(norm("Xin　chào"), "Xin chào")

    # ── Time ──────────────────────────────────────────────────────────────────

    def test_time_hm(self):
        self.assertEqual(norm("10點30分"), "10 giờ 30 phút")
        self.assertEqual(norm("8點05分"), "8 giờ 05 phút")

    def test_time_half(self):
        self.assertEqual(norm("10點半"), "10 giờ rưỡi")

    def test_time_hour_only(self):
        self.assertEqual(norm("10點"), "10 giờ")
        self.assertEqual(norm("9點整"), "9 giờ")

    def test_time_with_period(self):
        self.assertEqual(norm("上午10點30分"), "10 giờ 30 phút sáng")
        self.assertEqual(norm("下午3點半"), "3 giờ rưỡi chiều")
        self.assertEqual(norm("凌晨2點"), "2 giờ rạng sáng")

    def test_time_of_day_standalone(self):
        self.assertEqual(norm("下午 3:00 họp"), "chiều 3:00 họp")
        self.assertEqual(norm("晚上 8:00"), "tối 8:00")

    # ── Weekdays ──────────────────────────────────────────────────────────────

    def test_weekdays_xingqi(self):
        self.assertEqual(norm("星期一"), "thứ Hai")
        self.assertEqual(norm("星期三"), "thứ Tư")
        self.assertEqual(norm("星期日"), "Chủ nhật")

    def test_weekdays_zhou(self):
        self.assertEqual(norm("週五"), "thứ Sáu")
        self.assertEqual(norm("週日"), "Chủ nhật")

    def test_weekdays_libai(self):
        self.assertEqual(norm("禮拜天"), "Chủ nhật")
        self.assertEqual(norm("禮拜四"), "thứ Năm")

    # ── Months ────────────────────────────────────────────────────────────────

    def test_months_chinese_chars(self):
        self.assertEqual(norm("一月"), "tháng 1")
        self.assertEqual(norm("十月"), "tháng 10")
        self.assertEqual(norm("十一月"), "tháng 11")
        self.assertEqual(norm("十二月"), "tháng 12")

    def test_month_fen(self):
        self.assertEqual(norm("5月份"), "tháng 5")
        self.assertEqual(norm("12月份"), "tháng 12")

    def test_month_standalone_numeric(self):
        self.assertEqual(norm("5月開始"), "tháng 5開始")

    def test_month_not_converted_when_followed_by_day(self):
        self.assertEqual(norm("3月25日"), "3月25日")

    # ── Ordinals ──────────────────────────────────────────────────────────────

    def test_ordinals_1_to_10(self):
        self.assertEqual(norm("第一"), "thứ nhất")
        self.assertEqual(norm("第四"), "thứ tư")
        self.assertEqual(norm("第十"), "thứ mười")

    def test_ordinals_numeric(self):
        self.assertEqual(norm("第11"), "thứ 11")
        self.assertEqual(norm("第25"), "thứ 25")

    # ── Percentages & fractions ───────────────────────────────────────────────

    def test_percent(self):
        self.assertEqual(norm("百分之50"), "50%")
        self.assertEqual(norm("百分之12.5"), "12.5%")
        self.assertEqual(norm("百分之100"), "100%")

    def test_fraction(self):
        self.assertEqual(norm("4分之3"), "3/4")
        self.assertEqual(norm("3分之1"), "1/3")
        self.assertEqual(norm("2分之1"), "1/2")

    # ── Units ─────────────────────────────────────────────────────────────────

    def test_units(self):
        self.assertEqual(norm("25歲"), "25 tuổi")
        self.assertEqual(norm("10公里"), "10 km")
        self.assertEqual(norm("5公斤"), "5 kg")
        self.assertEqual(norm("170公分"), "170 cm")
        self.assertEqual(norm("1.5升"), "1.5 lít")
        self.assertEqual(norm("36度"), "36 độ")
        self.assertEqual(norm("100平方公尺"), "100 m²")
        self.assertEqual(norm("5平方公里"), "5 km²")

    def test_unit_longer_first(self):
        self.assertEqual(norm("100平方公尺"), "100 m²")
        self.assertEqual(norm("100公尺"), "100 m")

    # ── Honorifics ────────────────────────────────────────────────────────────

    def test_honorifics(self):
        self.assertEqual(norm("先生"), "ông")
        self.assertEqual(norm("女士"), "bà")
        self.assertEqual(norm("小姐"), "cô")
        self.assertEqual(norm("醫生"), "bác sĩ")
        self.assertEqual(norm("教授"), "giáo sư")
        self.assertEqual(norm("同學"), "bạn học")

    # ── Formal terms ──────────────────────────────────────────────────────────

    def test_formal_terms(self):
        self.assertEqual(norm("貴公司"), "quý công ty")
        self.assertEqual(norm("本公司"), "công ty chúng tôi")
        self.assertEqual(norm("本人"), "tôi")
        self.assertEqual(norm("各位"), "quý vị")
        self.assertEqual(norm("此致"), "Trân trọng")
        self.assertEqual(norm("敬啟者"), "Kính gửi")

    # ── Combined ──────────────────────────────────────────────────────────────

    def test_mixed(self):
        self.assertEqual(
            norm("Họp《dự án》lúc 下午 3:00，mời tham dự。"),
            'Họp"dự án"lúc chiều 3:00,mời tham dự.',
        )
        self.assertEqual(
            norm("各位先生，會議於星期三下午2點30分開始。"),
            "quý vịông,會議於thứ Tư2 giờ 30 phút chiều開始.",
        )


if __name__ == '__main__':
    unittest.main()
