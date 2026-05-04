part of 'app_strings.dart';

extension AppStringsLanguage on AppStrings {
  // Language tab
  String get srcLang =>
      switch (locale) { 'en' => 'Source', 'vi' => 'Ngôn ngữ nguồn', _ => '翻譯來源' };
  String get tgtLang =>
      switch (locale) { 'en' => 'Target', 'vi' => 'Ngôn ngữ đích', _ => '翻譯目標' };
  String get secondTgtLang => switch (locale) {
        'en' => 'Alt Target',
        'vi' => 'Đích thay thế',
        _ => '第二目標'
      };
  String get outputFormat => switch (locale) {
        'en' => 'Output Format',
        'vi' => 'Định dạng đầu ra',
        _ => '輸出格式'
      };
  String get availableVars => switch (locale) {
        'en' => 'Variables: {source}  {translation}',
        'vi' => 'Biến có sẵn: {source}  {translation}',
        _ => '可用變數：{source}  {translation}',
      };

  // Rules tab
  String get rulesTitle => switch (locale) {
        'en' => 'Translation Rules (enforced, one per line)',
        'vi' => 'Quy tắc dịch (bắt buộc, mỗi dòng một quy tắc)',
        _ => '翻譯規則（翻譯時強制遵守，每行一條）'
      };
  String get rulesHint => switch (locale) {
        'en' => 'Enter one rule per line…',
        'vi' => 'Nhập một quy tắc mỗi dòng…',
        _ => '每行輸入一條規則…'
      };

  // Auto detect
  String get autoDetect => switch (locale) {
        'en' => 'Auto Detect',
        'vi' => 'Tự động nhận dạng',
        _ => '自動偵測'
      };

  String langName(String code) => switch (code) {
        '繁體中文' => switch (locale) {
            'en' => 'Traditional Chinese',
            'vi' => 'Tiếng Trung phồn thể',
            _ => '繁體中文'
          },
        '簡體中文' => switch (locale) {
            'en' => 'Simplified Chinese',
            'vi' => 'Tiếng Trung giản thể',
            _ => '簡體中文'
          },
        '越南文' => switch (locale) {
            'en' => 'Vietnamese',
            'vi' => 'Tiếng Việt',
            _ => '越南文'
          },
        '英文' => switch (locale) {
            'en' => 'English',
            'vi' => 'Tiếng Anh',
            _ => '英文'
          },
        '日文' => switch (locale) {
            'en' => 'Japanese',
            'vi' => 'Tiếng Nhật',
            _ => '日文'
          },
        '韓文' => switch (locale) {
            'en' => 'Korean',
            'vi' => 'Tiếng Hàn',
            _ => '韓文'
          },
        '泰文' => switch (locale) {
            'en' => 'Thai',
            'vi' => 'Tiếng Thái',
            _ => '泰文'
          },
        '印尼文' => switch (locale) {
            'en' => 'Indonesian',
            'vi' => 'Tiếng Indonesia',
            _ => '印尼文'
          },
        '馬來文' => switch (locale) {
            'en' => 'Malay',
            'vi' => 'Tiếng Malay',
            _ => '馬來文'
          },
        '法文' => switch (locale) {
            'en' => 'French',
            'vi' => 'Tiếng Pháp',
            _ => '法文'
          },
        '德文' => switch (locale) {
            'en' => 'German',
            'vi' => 'Tiếng Đức',
            _ => '德文'
          },
        '西班牙文' => switch (locale) {
            'en' => 'Spanish',
            'vi' => 'Tiếng Tây Ban Nha',
            _ => '西班牙文'
          },
        '葡萄牙文' => switch (locale) {
            'en' => 'Portuguese',
            'vi' => 'Tiếng Bồ Đào Nha',
            _ => '葡萄牙文'
          },
        kAutoDetectLang => autoDetect,
        _ => code,
      };

  // About dialog
  String get aboutDesc => switch (locale) {
        'en' =>
          'Bilingual output translation tool\nCopy text, press hotkey,\nclipboard becomes source + translation format.',
        'vi' =>
          'Công cụ dịch xuất song ngữ\nSao chép văn bản, nhấn phím tắt,\nclipboard tự động thành định dạng gốc + bản dịch.',
        _ => '雙語輸出翻譯工具\n複製文字，按下快捷鍵，\n剪貼簿自動變成原文 + 譯文格式。',
      };
  String get hotkeyLabel =>
      switch (locale) { 'en' => 'Hotkey', 'vi' => 'Phím tắt', _ => '快捷鍵' };
  String get enginesLabel =>
      switch (locale) { 'en' => 'Engines', 'vi' => 'Công cụ hỗ trợ', _ => '支援引擎' };
}
