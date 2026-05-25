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
  String get glossarySyncUrl => switch (locale) {
        'en' => 'Sync URL',
        'vi' => 'URL đồng bộ',
        _ => '同步 URL'
      };
  String get glossarySyncEmail =>
      switch (locale) { 'en' => 'Email', 'vi' => 'Email', _ => 'Email' };
  String get glossarySyncPassword =>
      switch (locale) { 'en' => 'Password', 'vi' => 'Mật khẩu', _ => '密碼' };
  String get glossaryCloudSync => switch (locale) {
        'en' => 'Cloud sync',
        'vi' => 'Đồng bộ đám mây',
        _ => '雲端同步'
      };
  String get glossaryLogin =>
      switch (locale) { 'en' => 'Login', 'vi' => 'Đăng nhập', _ => '登入' };
  String get glossaryLoginDone => switch (locale) {
        'en' => 'Logged in',
        'vi' => 'Đã đăng nhập',
        _ => '已登入'
      };
  String get glossaryLogout =>
      switch (locale) { 'en' => 'Logout', 'vi' => 'Đăng xuất', _ => '登出' };
  String glossaryRole(String role) => switch (locale) {
        'en' => 'Role: $role',
        'vi' => 'Vai trò: $role',
        _ => '角色：$role'
      };
  String get glossaryReviewPending =>
      switch (locale) { 'en' => 'Review', 'vi' => 'Duyệt', _ => '審核' };
  String get glossaryManageUsers =>
      switch (locale) { 'en' => 'Users', 'vi' => 'Người dùng', _ => '使用者' };
  String get glossaryUsersTitle => switch (locale) {
        'en' => 'Glossary users',
        'vi' => 'Người dùng từ điển',
        _ => '詞彙表使用者'
      };
  String get glossaryCreateUser => switch (locale) {
        'en' => 'Create user',
        'vi' => 'Tạo người dùng',
        _ => '建立使用者'
      };
  String get glossaryUserRole =>
      switch (locale) { 'en' => 'Role', 'vi' => 'Vai trò', _ => '角色' };
  String get glossaryUserActive =>
      switch (locale) { 'en' => 'Active', 'vi' => 'Đang dùng', _ => '啟用' };
  String get glossaryPendingTitle => switch (locale) {
        'en' => 'Pending glossary terms',
        'vi' => 'Từ đang chờ duyệt',
        _ => '待審核詞彙'
      };
  String get glossaryNoPending => switch (locale) {
        'en' => 'No pending terms',
        'vi' => 'Không có từ chờ duyệt',
        _ => '沒有待審核詞彙'
      };
  String get glossaryApprove =>
      switch (locale) { 'en' => 'Approve', 'vi' => 'Duyệt', _ => '核准' };
  String get glossaryReject =>
      switch (locale) { 'en' => 'Reject', 'vi' => 'Từ chối', _ => '退回' };
  String get glossarySync =>
      switch (locale) { 'en' => 'Sync', 'vi' => 'Đồng bộ', _ => '同步' };
  String get glossarySyncDone => switch (locale) {
        'en' => 'Glossary synced',
        'vi' => 'Đã đồng bộ từ điển',
        _ => '詞彙表已同步'
      };
  String get glossaryRemoteSaved => switch (locale) {
        'en' => 'Saved to glossary',
        'vi' => 'Đã lưu vào từ điển',
        _ => '詞彙已儲存'
      };
  String get glossaryRemoteDeleted => switch (locale) {
        'en' => 'Deleted from glossary',
        'vi' => 'Đã xoá khỏi từ điển',
        _ => '詞彙已刪除'
      };
  String glossaryLastSynced(String value) => switch (locale) {
        'en' => 'Last synced: $value',
        'vi' => 'Đồng bộ lần cuối: $value',
        _ => '最後同步：$value'
      };
  String get glossaryNeverSynced => switch (locale) {
        'en' => 'Not synced yet',
        'vi' => 'Chưa đồng bộ',
        _ => '尚未同步'
      };
  String glossaryPendingCount(int n) => switch (locale) {
        'en' => '$n pending change(s)',
        'vi' => '$n thay đổi đang chờ',
        _ => '$n 筆待同步'
      };
  String get glossarySavedPending => switch (locale) {
        'en' => 'Saved locally. It will sync when the connection is restored.',
        'vi' => 'Đã lưu cục bộ. Sẽ đồng bộ khi có kết nối.',
        _ => '已先儲存在本機，恢復連線後會同步。'
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
  String get langPairLabel => switch (locale) {
        'en' => 'Language Pair',
        'vi' => 'Cặp ngôn ngữ',
        _ => '語言對'
      };
  String get glossaryGlobalLabel => switch (locale) {
        'en' => 'Global',
        'vi' => 'Toàn cục',
        _ => '全域 (Global)'
      };
  String get glossaryEditTitle =>
      switch (locale) { 'en' => 'Edit Entry', 'vi' => 'Sửa mục', _ => '修改詞彙' };
  String get addLangPairTitle => switch (locale) {
        'en' => 'Add Language Pair',
        'vi' => 'Thêm cặp ngôn ngữ',
        _ => '新增語言對'
      };
  String get addLangPairHint => switch (locale) {
        'en' => 'e.g. Chinese-Vietnamese',
        'vi' => 'vd: Hán ngữ-Việt',
        _ => '例：繁體中文-越南文'
      };
  String get deleteLangPairTitle => switch (locale) {
        'en' => 'Delete Language Pair',
        'vi' => 'Xoá cặp ngôn ngữ',
        _ => '刪除語言對'
      };
  String deleteLangPairConfirm(String ctx) => switch (locale) {
        'en' => 'Delete glossary for "$ctx"?',
        'vi' => 'Xoá từ điển cho "$ctx"?',
        _ => '確定刪除「$ctx」的詞彙表？'
      };
  String get addLangPairTooltip => switch (locale) {
        'en' => 'Add language pair',
        'vi' => 'Thêm cặp ngôn ngữ',
        _ => '新增語言對'
      };
  String get deleteLangPairTooltip => switch (locale) {
        'en' => 'Delete this language pair',
        'vi' => 'Xoá cặp ngôn ngữ này',
        _ => '刪除此語言對'
      };

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
