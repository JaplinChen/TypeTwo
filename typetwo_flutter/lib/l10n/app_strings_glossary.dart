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
  String get glossarySyncTarget => switch (locale) {
        'en' => 'Sync space',
        'vi' => 'Không gian đồng bộ',
        _ => '同步空間'
      };
  String get glossarySyncTargetTypeTwo => switch (locale) {
        'en' => 'TypeTwo Server',
        'vi' => 'TypeTwo Server',
        _ => 'TypeTwo Server'
      };
  String get glossarySyncTargetLocalFolder => switch (locale) {
        'en' => 'Local cloud folder',
        'vi' => 'Thư mục đám mây cục bộ',
        _ => '本機雲端資料夾'
      };
  String get glossarySyncTargetWebDav => switch (locale) {
        'en' => 'WebDAV / Nextcloud',
        'vi' => 'WebDAV / Nextcloud',
        _ => 'WebDAV / Nextcloud'
      };
  String get glossarySyncTargetOneDrive => switch (locale) {
        'en' => 'OneDrive',
        'vi' => 'OneDrive',
        _ => 'OneDrive'
      };
  String get glossarySyncTargetDropbox =>
      switch (locale) { 'en' => 'Dropbox', 'vi' => 'Dropbox', _ => 'Dropbox' };
  String get glossarySyncTargetGoogleDrive => switch (locale) {
        'en' => 'Google Drive',
        'vi' => 'Google Drive',
        _ => 'Google Drive'
      };
  String get glossarySyncTargetSynologyDrive => switch (locale) {
        'en' => 'Synology Drive',
        'vi' => 'Synology Drive',
        _ => 'Synology Drive'
      };
  String get glossarySyncTargetFileServer => switch (locale) {
        'en' => 'Local or Company File Server',
        'vi' => 'Máy chủ tệp nội bộ hoặc công ty',
        _ => '本機或公司檔案伺服器'
      };
  String get glossaryReorderTargets => switch (locale) {
        'en' => 'Reorder sync targets',
        'vi' => 'Sắp xếp đích đồng bộ',
        _ => '調整同步空間順序'
      };
  String get glossarySyncLocalPath => switch (locale) {
        'en' => 'Sync folder',
        'vi' => 'Thư mục đồng bộ',
        _ => '同步資料夾'
      };
  String get glossarySyncWebDavUrl => switch (locale) {
        'en' => 'WebDAV folder URL',
        'vi' => 'URL thư mục WebDAV',
        _ => 'WebDAV 資料夾 URL'
      };
  String get glossarySyncWebDavUser => switch (locale) {
        'en' => 'WebDAV username',
        'vi' => 'Tên người dùng WebDAV',
        _ => 'WebDAV 帳號'
      };
  String get glossarySyncWebDavPassword => switch (locale) {
        'en' => 'WebDAV password',
        'vi' => 'Mật khẩu WebDAV',
        _ => 'WebDAV 密碼'
      };
  String get glossaryChooseFolder =>
      switch (locale) { 'en' => 'Choose', 'vi' => 'Chọn', _ => '選擇' };
  String get glossaryTestConnection => switch (locale) {
        'en' => 'Test connection',
        'vi' => 'Kiểm tra kết nối',
        _ => '測試連線'
      };
  String get glossaryRestoreBackup => switch (locale) {
        'en' => 'Restore backup',
        'vi' => 'Khôi phục sao lưu',
        _ => '還原備份'
      };
  String get glossaryBackupsTitle => switch (locale) {
        'en' => 'Glossary sync backups',
        'vi' => 'Bản sao lưu đồng bộ từ điển',
        _ => '詞彙同步備份'
      };
  String get glossaryNoBackups => switch (locale) {
        'en' => 'No backups yet',
        'vi' => 'Chưa có bản sao lưu',
        _ => '尚無備份'
      };
  String glossaryBackupTermCount(int n) =>
      switch (locale) { 'en' => '$n term(s)', 'vi' => '$n mục', _ => '$n 筆詞彙' };
  String get glossaryRestore =>
      switch (locale) { 'en' => 'Restore', 'vi' => 'Khôi phục', _ => '還原' };
  String get glossaryRestoreDone => switch (locale) {
        'en' => 'Glossary backup restored',
        'vi' => 'Đã khôi phục sao lưu từ điển',
        _ => '詞彙備份已還原'
      };
  String get glossaryCloudSyncHint => switch (locale) {
        'en' =>
          'Use TypeTwo Server for shared review, a WebDAV folder, or a local folder inside OneDrive, Dropbox, Google Drive, Nextcloud, or Synology Drive.',
        'vi' =>
          'Dùng TypeTwo Server để duyệt chung, thư mục WebDAV, hoặc thư mục cục bộ trong OneDrive, Dropbox, Google Drive, Nextcloud hoặc Synology Drive.',
        _ =>
          '可使用 TypeTwo Server 做共用審核，也可使用 WebDAV 資料夾，或選擇 OneDrive、Dropbox、Google Drive、Nextcloud、Synology Drive 內的本機資料夾。'
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
  String get glossaryImportPreview => switch (locale) {
        'en' => 'Import preview',
        'vi' => 'Xem trước nhập',
        _ => '匯入預覽'
      };
  String get glossaryImportPreviewTitle => switch (locale) {
        'en' => 'Glossary import preview',
        'vi' => 'Xem trước nhập từ điển',
        _ => '詞彙匯入預覽'
      };
  String get glossaryImportConflictStrategyTitle => switch (locale) {
        'en' => 'Import conflict strategy',
        'vi' => 'Cách xử lý xung đột khi nhập',
        _ => '匯入衝突處理'
      };
  String get glossaryImportOverwrite => switch (locale) {
        'en' => 'Overwrite existing terms',
        'vi' => 'Ghi đè mục hiện có',
        _ => '覆蓋既有詞彙'
      };
  String get glossaryImportKeepExisting => switch (locale) {
        'en' => 'Keep existing terms',
        'vi' => 'Giữ mục hiện có',
        _ => '保留既有詞彙'
      };
  String get glossaryImportConfirm =>
      switch (locale) { 'en' => 'Import', 'vi' => 'Nhập', _ => '正式匯入' };
  String glossaryImportDone(int imported, int updated) => switch (locale) {
        'en' => 'Import completed: $imported added, $updated updated',
        'vi' => 'Đã nhập: thêm $imported, cập nhật $updated',
        _ => '匯入完成：新增 $imported 筆，更新 $updated 筆'
      };
  String glossaryImportImported(int n) =>
      switch (locale) { 'en' => '$n added', 'vi' => 'Thêm $n', _ => '新增 $n 筆' };
  String glossaryImportUpdated(int n) => switch (locale) {
        'en' => '$n updated',
        'vi' => 'Cập nhật $n',
        _ => '更新 $n 筆'
      };
  String glossaryImportUnchanged(int n) => switch (locale) {
        'en' => '$n unchanged',
        'vi' => 'Không đổi $n',
        _ => '未變更 $n 筆'
      };
  String glossaryImportSkipped(int n) => switch (locale) {
        'en' => '$n skipped',
        'vi' => 'Bỏ qua $n',
        _ => '略過 $n 筆'
      };
  String get glossaryImportCurrentTarget => switch (locale) {
        'en' => 'Current translation',
        'vi' => 'Bản dịch hiện tại',
        _ => '目前譯文'
      };
  String get glossaryImportCurrentStatus => switch (locale) {
        'en' => 'Current status',
        'vi' => 'Trạng thái hiện tại',
        _ => '目前狀態'
      };
  String get glossaryImportActionImported =>
      switch (locale) { 'en' => 'Add', 'vi' => 'Thêm', _ => '新增' };
  String get glossaryImportActionUpdated =>
      switch (locale) { 'en' => 'Update', 'vi' => 'Cập nhật', _ => '更新' };
  String get glossaryImportActionUnchanged =>
      switch (locale) { 'en' => 'Unchanged', 'vi' => 'Không đổi', _ => '未變更' };
  String get glossaryImportActionSkipped =>
      switch (locale) { 'en' => 'Skipped', 'vi' => 'Bỏ qua', _ => '略過' };
  String get glossaryExportRemote =>
      switch (locale) { 'en' => 'Export', 'vi' => 'Xuất', _ => '匯出' };
  String get glossaryExportRemoteTitle => switch (locale) {
        'en' => 'Export remote glossary',
        'vi' => 'Xuất từ điển từ xa',
        _ => '匯出遠端詞彙'
      };
  String get glossaryExportApproved =>
      switch (locale) { 'en' => 'Approved', 'vi' => 'Đã duyệt', _ => '已核准' };
  String get glossaryExportPending =>
      switch (locale) { 'en' => 'Pending', 'vi' => 'Đang chờ', _ => '待審核' };
  String get glossaryExportRejected =>
      switch (locale) { 'en' => 'Rejected', 'vi' => 'Đã từ chối', _ => '已退回' };
  String get glossaryExportAll => switch (locale) {
        'en' => 'All statuses',
        'vi' => 'Tất cả trạng thái',
        _ => '全部狀態'
      };
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
  String get glossaryPendingSearch => switch (locale) {
        'en' => 'Search pending terms',
        'vi' => 'Tìm từ đang chờ',
        _ => '搜尋待審核詞彙'
      };
  String glossaryPendingSelected(int n) => switch (locale) {
        'en' => '$n selected',
        'vi' => 'Đã chọn $n',
        _ => '已選取 $n 筆'
      };
  String get glossarySelectFiltered => switch (locale) {
        'en' => 'Select filtered',
        'vi' => 'Chọn kết quả lọc',
        _ => '選取篩選結果'
      };
  String get glossaryClearSelection => switch (locale) {
        'en' => 'Clear selection',
        'vi' => 'Bỏ chọn',
        _ => '清除選取'
      };
  String get glossaryApproveSelected => switch (locale) {
        'en' => 'Approve selected',
        'vi' => 'Duyệt đã chọn',
        _ => '批次核准'
      };
  String get glossaryRejectSelected => switch (locale) {
        'en' => 'Reject selected',
        'vi' => 'Từ chối đã chọn',
        _ => '批次退回'
      };
  String get glossaryRejectReasonTitle => switch (locale) {
        'en' => 'Reject reason',
        'vi' => 'Lý do từ chối',
        _ => '退回原因'
      };
  String get glossaryRejectReasonHint => switch (locale) {
        'en' => 'Reason shown in history',
        'vi' => 'Lý do sẽ hiển thị trong lịch sử',
        _ => '原因會記錄在 history'
      };
  String get glossaryHistory =>
      switch (locale) { 'en' => 'History', 'vi' => 'Lịch sử', _ => '紀錄' };
  String get glossaryNoHistory => switch (locale) {
        'en' => 'No history',
        'vi' => 'Không có lịch sử',
        _ => '沒有紀錄'
      };
  String get glossaryHistoryReason =>
      switch (locale) { 'en' => 'Reason', 'vi' => 'Lý do', _ => '原因' };
  String get glossaryRestoreHistory =>
      switch (locale) { 'en' => 'Restore', 'vi' => 'Khôi phục', _ => '回復' };
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
  String get glossaryLoginRequired => switch (locale) {
        'en' => 'Login required',
        'vi' => 'Cần đăng nhập',
        _ => '需要登入'
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
