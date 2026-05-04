import unittest
from date_converter import apply_date_conversion

VI = "越南文"
ZH = "繁體中文"


def conv(text):
    return apply_date_conversion(text, VI)


class DateConverterTest(unittest.TestCase):
    def test_no_op_for_non_vietnamese(self):
        self.assertEqual(apply_date_conversion("5/25", ZH), "5/25")

    def test_chinese_ymd_characters(self):
        self.assertEqual(conv("2024年5月25日"), "Ngày 25 tháng 5 năm 2024")
        self.assertEqual(conv("2024年12月1日"), "Ngày 1 tháng 12 năm 2024")

    def test_chinese_md_characters(self):
        self.assertEqual(conv("5月25日"), "ngày 25 tháng 5")
        self.assertEqual(conv("12月1日"), "ngày 1 tháng 12")

    def test_year_first_slash(self):
        self.assertEqual(conv("2024/5/25"), "25/5/2024")
        self.assertEqual(conv("2024/12/1"), "1/12/2024")

    def test_year_first_dash(self):
        self.assertEqual(conv("2024-5-25"), "25-5-2024")

    def test_md_unambiguous(self):
        self.assertEqual(conv("5/25"), "25/5")
        self.assertEqual(conv("10/31"), "31/10")
        self.assertEqual(conv("vào ngày 5/25 họp"), "vào ngày 25/5 họp")

    def test_md_ambiguous_unchanged(self):
        self.assertEqual(conv("3/5"), "3/5")
        self.assertEqual(conv("12/1"), "12/1")

    def test_already_dmy_unchanged(self):
        self.assertEqual(conv("25/5"), "25/5")
        self.assertEqual(conv("25/5/2024"), "25/5/2024")

    def test_not_in_larger_number(self):
        self.assertEqual(conv("310/25/2024"), "310/25/2024")

    def test_multiline(self):
        self.assertEqual(
            conv("CIO mới đến vào 5/25\nHọp lúc 2024/6/1"),
            "CIO mới đến vào 25/5\nHọp lúc 1/6/2024",
        )


if __name__ == '__main__':
    unittest.main()
