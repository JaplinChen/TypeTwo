import '../models/app_constants.dart';
part 'app_strings_engine.dart';
part 'app_strings_language.dart';
part 'app_strings_glossary.dart';
part 'app_strings_processes.dart';
part 'app_strings_hotkey.dart';

class AppStrings {
  final String locale;
  const AppStrings(this.locale);

  // General
  String get about =>
      switch (locale) { 'en' => 'About', 'vi' => 'Giới thiệu', _ => '關於' };
  String get settings =>
      switch (locale) { 'en' => 'Settings', 'vi' => 'Cài đặt', _ => '設定' };
  String get save =>
      switch (locale) { 'en' => 'Save', 'vi' => 'Lưu', _ => '儲存' };
  String get cancel =>
      switch (locale) { 'en' => 'Cancel', 'vi' => 'Huỷ', _ => '取消' };
  String get add =>
      switch (locale) { 'en' => 'Add', 'vi' => 'Thêm', _ => '新增' };
  String get clear =>
      switch (locale) { 'en' => 'Clear', 'vi' => 'Xoá hết', _ => '清空' };
  String get close =>
      switch (locale) { 'en' => 'Close', 'vi' => 'Đóng', _ => '關閉' };
  String get copied =>
      switch (locale) { 'en' => 'Copied', 'vi' => 'Đã sao chép', _ => '已複製' };
  String get later =>
      switch (locale) { 'en' => 'Later', 'vi' => 'Để sau', _ => '稍後' };
  String get restart =>
      switch (locale) { 'en' => 'Restart', 'vi' => 'Khởi động lại', _ => '重啟' };
  String get quit =>
      switch (locale) { 'en' => 'Quit', 'vi' => 'Thoát', _ => '退出' };
  String get confirm =>
      switch (locale) { 'en' => 'Confirm', 'vi' => 'Xác nhận', _ => '確定' };
  String get delete =>
      switch (locale) { 'en' => 'Delete', 'vi' => 'Xoá', _ => '刪除' };

  String windowsHint(String h) => switch (locale) {
        'en' =>
          'Select text in any window and press $h to translate and paste back',
        'vi' => 'Chọn văn bản trong bất kỳ cửa sổ, nhấn $h để dịch và dán lại',
        _ => '任意視窗選取文字後按 $h 直接翻譯並貼回',
      };

  // Translation panel
  String get pasteHint => switch (locale) {
        'en' => 'Paste or type text to translate…',
        'vi' => 'Dán hoặc nhập văn bản cần dịch…',
        _ => '貼上或輸入要翻譯的文字…'
      };
  String get translating => switch (locale) {
        'en' => 'Translating…',
        'vi' => 'Đang dịch…',
        _ => '翻譯中…'
      };
  String get translate =>
      switch (locale) { 'en' => 'Translate', 'vi' => 'Dịch', _ => '翻譯' };
  String get copyResult => switch (locale) {
        'en' => 'Copy Result',
        'vi' => 'Sao chép kết quả',
        _ => '複製結果'
      };
  String get resultPlaceholder => switch (locale) {
        'en' => 'Translation result will appear here',
        'vi' => 'Kết quả dịch sẽ hiển thị ở đây',
        _ => '翻譯結果將顯示在此'
      };

  // Settings screen
  String get tabEngine =>
      switch (locale) { 'en' => 'Engine', 'vi' => 'Công cụ dịch', _ => '翻譯引擎' };
  String get tabLanguage =>
      switch (locale) { 'en' => 'Language', 'vi' => 'Ngôn ngữ', _ => '語言設定' };
  String get tabRules =>
      switch (locale) { 'en' => 'Rules', 'vi' => 'Quy tắc', _ => '翻譯規則' };
  String get tabGlossary =>
      switch (locale) { 'en' => 'Glossary', 'vi' => 'Từ điển', _ => '詞彙表' };
  String get tabProcesses => switch (locale) {
        'en' => 'Processes',
        'vi' => 'Chương trình',
        _ => '限定程式'
      };
  String get tabHotkey =>
      switch (locale) { 'en' => 'Hotkey', 'vi' => 'Phím tắt', _ => '快捷鍵' };
  String get saved => switch (locale) {
        'en' => 'Settings saved',
        'vi' => 'Đã lưu cài đặt',
        _ => '設定已儲存'
      };

  // Config error
  String get configErrorTitle => switch (locale) {
        'en' => 'Config Error',
        'vi' => 'Lỗi cấu hình',
        _ => '設定檔錯誤'
      };

  // Correction dialog
  String get correctTitle => switch (locale) {
        'en' => 'Correct Translation',
        'vi' => 'Sửa bản dịch',
        _ => '糾正翻譯'
      };
  String get correctSrc => switch (locale) {
        'en' => 'Source Text',
        'vi' => 'Văn bản gốc',
        _ => '原文'
      };
  String get correctTgt => switch (locale) {
        'en' => 'Correct Translation',
        'vi' => 'Bản dịch đúng',
        _ => '正確翻譯'
      };
  String get correctHint => switch (locale) {
        'en' => 'Enter the correct translation…',
        'vi' => 'Nhập bản dịch đúng…',
        _ => '輸入正確翻譯…'
      };
  String get addedToGlossary => switch (locale) {
        'en' => 'Added to glossary',
        'vi' => 'Đã thêm vào từ điển',
        _ => '已加入詞彙表'
      };
}
