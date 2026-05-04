part of 'app_strings.dart';

extension AppStringsGlossary on AppStrings {
  String get glossarySrc =>
      switch (locale) { 'en' => 'Source', 'vi' => 'Nguyên văn', _ => '原文' };
  String get glossaryTgt =>
      switch (locale) { 'en' => 'Translation', 'vi' => 'Bản dịch', _ => '譯文' };
  String get importTsv => switch (locale) {
        'en' => 'Import TSV/JSON',
        'vi' => 'Nhập TSV/JSON',
        _ => '匯入 TSV/JSON'
      };
  String get exportTsv => switch (locale) {
        'en' => 'Export TSV',
        'vi' => 'Xuất TSV',
        _ => '匯出 TSV'
      };
  String glossaryCount(int n) =>
      switch (locale) { 'en' => '$n entries', 'vi' => '$n mục', _ => '共 $n 筆' };
  String glossaryFilteredCount(int shown, int total) => switch (locale) {
        'en' => '$shown of $total entries',
        'vi' => '$shown/$total mục',
        _ => '顯示 $shown / $total 筆'
      };
  String get searchGlossary => switch (locale) {
        'en' => 'Search glossary',
        'vi' => 'Tìm từ điển',
        _ => '搜尋詞彙'
      };
  String get glossaryEmpty => switch (locale) {
        'en' => 'No glossary entries yet',
        'vi' => 'Chưa có mục từ điển',
        _ => '尚無詞彙'
      };
  String get glossaryNoMatches => switch (locale) {
        'en' => 'No matching glossary entries',
        'vi' => 'Không có mục phù hợp',
        _ => '沒有符合的詞彙'
      };
  String get saveGlossaryDialog => switch (locale) {
        'en' => 'Save Glossary',
        'vi' => 'Lưu từ điển',
        _ => '儲存詞彙表'
      };
  String importedEntries(int n) => switch (locale) {
        'en' => 'Imported $n entries',
        'vi' => 'Đã nhập $n mục',
        _ => '已匯入 $n 筆詞彙'
      };
  String savedEntries(int n) => switch (locale) {
        'en' => 'Saved $n entries',
        'vi' => 'Đã lưu $n mục',
        _ => '已儲存 $n 筆詞彙'
      };

  // Lang-pair management
  String get langPairLabel =>
      switch (locale) { 'en' => 'Language Pair', 'vi' => 'Cặp ngôn ngữ', _ => '語言對' };
  String get glossaryGlobalLabel =>
      switch (locale) { 'en' => 'Global', 'vi' => 'Toàn cục', _ => '全域 (Global)' };
  String get glossaryEditTitle =>
      switch (locale) { 'en' => 'Edit Entry', 'vi' => 'Sửa mục', _ => '修改詞彙' };
  String get addLangPairTitle =>
      switch (locale) { 'en' => 'Add Language Pair', 'vi' => 'Thêm cặp ngôn ngữ', _ => '新增語言對' };
  String get addLangPairHint => switch (locale) {
        'en' => 'e.g. Chinese-Vietnamese',
        'vi' => 'vd: Hán ngữ-Việt',
        _ => '例：繁體中文-越南文'
      };
  String get deleteLangPairTitle =>
      switch (locale) { 'en' => 'Delete Language Pair', 'vi' => 'Xoá cặp ngôn ngữ', _ => '刪除語言對' };
  String deleteLangPairConfirm(String ctx) => switch (locale) {
        'en' => 'Delete glossary for "$ctx"?',
        'vi' => 'Xoá từ điển cho "$ctx"?',
        _ => '確定刪除「$ctx」的詞彙表？'
      };
  String get addLangPairTooltip =>
      switch (locale) { 'en' => 'Add language pair', 'vi' => 'Thêm cặp ngôn ngữ', _ => '新增語言對' };
  String get deleteLangPairTooltip =>
      switch (locale) { 'en' => 'Delete this language pair', 'vi' => 'Xoá cặp ngôn ngữ này', _ => '刪除此語言對' };

  // Import
  String get importJsonInvalid => switch (locale) {
        'en' => 'Invalid JSON: expected an object, not an array',
        'vi' => 'JSON không hợp lệ: cần là object, không phải array',
        _ => 'JSON 格式錯誤：須為物件，不能為陣列'
      };
  String skippedLines(int n) => switch (locale) {
        'en' => '$n line(s) skipped (no tab)',
        'vi' => 'Đã bỏ qua $n dòng (không có tab)',
        _ => '已跳過 $n 行（無 tab）'
      };
}
