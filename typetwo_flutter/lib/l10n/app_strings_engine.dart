part of 'app_strings.dart';

extension AppStringsEngine on AppStrings {
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
}
