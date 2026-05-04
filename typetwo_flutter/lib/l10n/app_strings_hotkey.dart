part of 'app_strings.dart';

extension AppStringsHotkey on AppStrings {
  String get hotkeyTitle => switch (locale) {
        'en' => 'Global Translation Hotkey',
        'vi' => 'Phím tắt dịch toàn cục',
        _ => '全域翻譯快捷鍵'
      };
  String get hotkeyDesc => switch (locale) {
        'en' => 'Select text and press the hotkey to translate and paste back.',
        'vi' => 'Chọn văn bản và nhấn phím tắt để dịch và dán lại.',
        _ => '選取文字後按下快捷鍵，即可翻譯並貼回。'
      };
  String get reRecord =>
      switch (locale) { 'en' => 'Re-record', 'vi' => 'Ghi lại', _ => '重新錄製' };
  String get pressHotkey => switch (locale) {
        'en' => 'Press a key combination (must include Ctrl, Alt, or Shift)…',
        'vi' => 'Nhấn tổ hợp phím (phải có Ctrl, Alt hoặc Shift)…',
        _ => '請按下快捷鍵組合（需包含 Ctrl、Alt 或 Shift）…'
      };
  String get hotkeyEffect => switch (locale) {
        'en' => 'New hotkey takes effect after saving.',
        'vi' => 'Phím tắt mới có hiệu lực sau khi lưu.',
        _ => '儲存後新快捷鍵立即生效。'
      };
  String get noModifierWarning => switch (locale) {
        'en' => 'Must include Ctrl, Alt, or Shift',
        'vi' => 'Phải có Ctrl, Alt hoặc Shift',
        _ => '需包含 Ctrl、Alt 或 Shift'
      };

  // Used by HotkeyService
  String get hotkeyNoSelection => switch (locale) {
        'en' => 'Please select text first, then press the hotkey.',
        'vi' => 'Vui lòng chọn văn bản trước, rồi nhấn phím tắt.',
        _ => '請先選取要翻譯的文字，再按快捷鍵。',
      };
  String hotkeyTranslateFailed(String detail) => switch (locale) {
        'en' => 'Translation failed.\n\n$detail',
        'vi' => 'Dịch thất bại.\n\n$detail',
        _ => '翻譯失敗。\n\n$detail',
      };
  String hotkeyRegisterFailed(String combo, Object e) => switch (locale) {
        'en' =>
          'Failed to register hotkey: $combo\n\nTry a different combination.\n\n$e',
        'vi' =>
          'Đăng ký phím tắt thất bại: $combo\n\nHãy thử tổ hợp khác.\n\n$e',
        _ => '快捷鍵註冊失敗：$combo\n\n請換一個組合。\n\n$e',
      };
}
