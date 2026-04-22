import '../models/app_constants.dart';

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
  String get close =>
      switch (locale) { 'en' => 'Close', 'vi' => 'Đóng', _ => '關閉' };
  String get copied =>
      switch (locale) { 'en' => 'Copied', 'vi' => 'Đã sao chép', _ => '已複製' };
  String get later =>
      switch (locale) { 'en' => 'Later', 'vi' => 'Để sau', _ => '稍後' };
  String get restart =>
      switch (locale) { 'en' => 'Restart', 'vi' => 'Khởi động lại', _ => '重啟' };

  // Bridge status bar
  String get bridgeRunning => switch (locale) {
        'en' => 'TypeTwo: Running',
        'vi' => 'TypeTwo: Đang chạy',
        _ => 'TypeTwo：運行中'
      };
  String get bridgeStopped => switch (locale) {
        'en' => 'TypeTwo: Stopped',
        'vi' => 'TypeTwo: Chưa chạy',
        _ => 'TypeTwo：未啟動'
      };
  String get bridgeDetecting => switch (locale) {
        'en' => 'TypeTwo: Detecting…',
        'vi' => 'TypeTwo: Đang kiểm tra…',
        _ => 'TypeTwo：偵測中…'
      };
  String get bridgeStart =>
      switch (locale) { 'en' => '▶ Start', 'vi' => '▶ Khởi động', _ => '▶ 啟動' };
  String get bridgeStop =>
      switch (locale) { 'en' => '■ Stop', 'vi' => '■ Dừng', _ => '■ 停止' };
  String get bridgeStartFailed => switch (locale) {
        'en' => 'Failed to start: ',
        'vi' => 'Khởi động thất bại: ',
        _ => '啟動失敗：'
      };
  String get bridgeStartTimeout => switch (locale) {
        'en' => 'Bridge startup timed out',
        'vi' => 'Bridge khởi động quá thời gian',
        _ => 'Bridge 啟動逾時'
      };
  String get bridgeExternallyManaged => switch (locale) {
        'en' => 'Managed by an existing TypeTwo process',
        'vi' => 'Được quản lý bởi tiến trình TypeTwo hiện có',
        _ => '目前由既有的 TypeTwo 程序管理'
      };
  String get bridgeStopNotAllowed => switch (locale) {
        'en' => 'Only bridges started from this UI can be stopped here',
        'vi' => 'Chỉ có thể dừng bridge do UI này khởi động',
        _ => '這裡只能停止由目前 UI 啟動的 bridge'
      };
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
  String get restartBridgeTitle => switch (locale) {
        'en' => 'Restart Bridge',
        'vi' => 'Khởi động lại Bridge',
        _ => '重啟 Bridge'
      };
  String get restartBridgeContent => switch (locale) {
        'en' =>
          'Settings saved.\nTypeTwo.exe must restart to apply changes. Restart now?',
        'vi' =>
          'Đã lưu cài đặt.\nCần khởi động lại TypeTwo.exe. Khởi động lại ngay?',
        _ => '設定已儲存。\n需重啟 TypeTwo.exe 才會生效，現在重啟？',
      };
  String get saved => switch (locale) {
        'en' => 'Settings saved',
        'vi' => 'Đã lưu cài đặt',
        _ => '設定已儲存'
      };
  String get syncWarning => switch (locale) {
        'en' =>
          'Settings saved, but failed to sync to TypeTwo.exe directory. Please restart Bridge manually.',
        'vi' =>
          'Đã lưu, nhưng không thể đồng bộ với thư mục TypeTwo.exe. Vui lòng khởi động lại Bridge thủ công.',
        _ => '設定已儲存，但無法同步至 TypeTwo.exe 目錄，請手動重啟 Bridge',
      };

  // Engine tab
  String get engineType => switch (locale) {
        'en' => 'Engine Type',
        'vi' => 'Loại công cụ',
        _ => '引擎類型'
      };
  String get serverAddress => switch (locale) {
        'en' => 'Server Address',
        'vi' => 'Địa chỉ máy chủ',
        _ => '伺服器位址'
      };
  String get testConnection => switch (locale) {
        'en' => 'Test Connection',
        'vi' => 'Kiểm tra kết nối',
        _ => '測試連線'
      };
  String get testing => switch (locale) {
        'en' => 'Testing…',
        'vi' => 'Đang kiểm tra…',
        _ => '測試中…'
      };
  String get connOk =>
      switch (locale) { 'en' => '✓ OK', 'vi' => '✓ Bình thường', _ => '✓ 正常' };
  String get connFailed => switch (locale) {
        'en' => '✗ Failed: ',
        'vi' => '✗ Thất bại: ',
        _ => '✗ 失敗: '
      };
  String get modelName => switch (locale) {
        'en' => 'Model Name',
        'vi' => 'Tên mô hình',
        _ => '模型名稱'
      };
  String get getModels => switch (locale) {
        'en' => 'Get Models',
        'vi' => 'Lấy mô hình',
        _ => '取得模型'
      };
  String get fallbackModels => switch (locale) {
        'en' => 'Fallback Models',
        'vi' => 'Mô hình dự phòng',
        _ => '備援模型'
      };
  String get fallbackModelsHint => switch (locale) {
        'en' =>
          'One per line or comma-separated. Used automatically on quota or temporary failures.',
        'vi' =>
          'Mỗi dòng một mô hình hoặc phân tách bằng dấu phẩy. Tự động dùng khi hết quota hoặc lỗi tạm thời.',
        _ => '每行一個或用逗號分隔。主模型 quota 用盡或暫時失敗時會自動改用。'
      };
  String foundModels(int n) => switch (locale) {
        'en' => 'Found $n models',
        'vi' => 'Tìm thấy $n mô hình',
        _ => '找到 $n 個模型'
      };
  String get apiKey =>
      switch (locale) { 'en' => 'API Key', 'vi' => 'API Key', _ => 'API 金鑰' };
  String get getApiKey => switch (locale) {
        'en' => 'Get API Key',
        'vi' => 'Lấy API Key',
        _ => '申請 API Key'
      };
  String get verify =>
      switch (locale) { 'en' => 'Verify', 'vi' => 'Xác minh', _ => '驗證' };
  String get translationStyle => switch (locale) {
        'en' => 'Translation Style (Precise ↔ Fluent)',
        'vi' => 'Phong cách dịch (Chính xác ↔ Trôi chảy)',
        _ => '翻譯風格（精準 ↔ 流暢）'
      };
  String get precise =>
      switch (locale) { 'en' => 'Precise', 'vi' => 'Chính xác', _ => '精準' };
  String get fluent =>
      switch (locale) { 'en' => 'Fluent', 'vi' => 'Trôi chảy', _ => '流暢' };
  String get getModelsFailed => switch (locale) {
        'en' => 'Failed to get models: ',
        'vi' => 'Không lấy được mô hình: ',
        _ => '取得模型失敗: '
      };
  String get translationMode =>
      switch (locale) { 'en' => 'Mode', 'vi' => 'Chế độ', _ => '翻譯模式' };
  String get modeQuick =>
      switch (locale) { 'en' => 'Quick', 'vi' => 'Nhanh', _ => '快捷' };
  String get modeAuto =>
      switch (locale) { 'en' => 'Auto', 'vi' => 'Tự động', _ => '自動' };
  String get modeThinking =>
      switch (locale) { 'en' => 'Thinking', 'vi' => 'Suy nghĩ', _ => '思考' };

  // Language tab
  String get srcLang =>
      switch (locale) { 'en' => 'Source', 'vi' => 'Nguồn dịch', _ => '翻譯來源' };
  String get tgtLang =>
      switch (locale) { 'en' => 'Target', 'vi' => 'Đích dịch', _ => '翻譯目標' };
  String get srcLabel => switch (locale) {
        'en' => 'Src Label',
        'vi' => 'Nhãn nguồn',
        _ => '來源標題'
      };
  String get tgtLabel =>
      switch (locale) { 'en' => 'Tgt Label', 'vi' => 'Nhãn đích', _ => '目標標題' };
  String get outputFormat => switch (locale) {
        'en' => 'Output Format',
        'vi' => 'Định dạng đầu ra',
        _ => '輸出格式'
      };
  String get availableVars => switch (locale) {
        'en' =>
          'Variables: {source_label}  {source}  {target_label}  {translation}',
        'vi' =>
          'Biến có sẵn: {source_label}  {source}  {target_label}  {translation}',
        _ => '可用變數：{source_label}  {source}  {target_label}  {translation}',
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

  // Glossary tab
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

  // Hotkey tab
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

  // Processes tab
  String get processesTitle => switch (locale) {
        'en' => 'Restrict translation to specific apps (empty = all)',
        'vi' => 'Giới hạn dịch cho ứng dụng cụ thể (trống = tất cả)',
        _ => '限定觸發翻譯的程式（留空 = 全部允許）'
      };
  String processesDesc(String h) => switch (locale) {
        'en' =>
          'Only when a listed app is in focus will $h trigger translation',
        'vi' =>
          'Chỉ khi ứng dụng trong danh sách đang hoạt động, $h mới kích hoạt dịch',
        _ => '只有列表中的程式在前景時，$h 才會觸發翻譯',
      };
  String get processName => switch (locale) {
        'en' => 'Process Name',
        'vi' => 'Tên chương trình',
        _ => '程式名稱'
      };
  String get processHint => switch (locale) {
        'en' => 'e.g. Teams.exe',
        'vi' => 'VD: Teams.exe',
        _ => '例：Teams.exe'
      };
  String get processesEmpty => switch (locale) {
        'en' => 'List is empty — all windows can trigger translation',
        'vi' => 'Danh sách trống, tất cả cửa sổ đều có thể kích hoạt dịch',
        _ => '列表為空，所有視窗均可觸發翻譯'
      };

  // Config error
  String get configErrorTitle => switch (locale) {
        'en' => 'Config Error',
        'vi' => 'Lỗi cấu hình',
        _ => '設定檔錯誤'
      };

  // Hotkey tab
  String get noModifierWarning => switch (locale) {
        'en' => 'Must include Ctrl, Alt, or Shift',
        'vi' => 'Phải có Ctrl, Alt hoặc Shift',
        _ => '需包含 Ctrl、Alt 或 Shift'
      };

  // Glossary import
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

  // Language names (used in dropdowns)
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
      switch (locale) { 'en' => 'Engines', 'vi' => 'Công cụ', _ => '支援引擎' };
  String get exeNotFound => switch (locale) {
        'en' => 'TypeTwo.exe not found',
        'vi' => 'Không tìm thấy TypeTwo.exe',
        _ => '找不到 TypeTwo.exe'
      };
}
