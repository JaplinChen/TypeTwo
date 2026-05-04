part of 'app_strings.dart';

extension AppStringsProcesses on AppStrings {
  String get processesTitle => switch (locale) {
        'en' => 'Translation trigger scope',
        'vi' => 'Phạm vi kích hoạt dịch',
        _ => '翻譯觸發範圍'
      };
  String processesDesc(String h) => switch (locale) {
        'en' =>
          'Choose whether $h works in all windows or only in selected apps',
        'vi' => 'Chọn $h áp dụng cho mọi cửa sổ hay chỉ các ứng dụng đã chọn',
        _ => '設定 $h 要套用在所有視窗，還是只套用在指定程式',
      };
  String get processModeAll => switch (locale) {
        'en' => 'Allow all windows',
        'vi' => 'Cho phép mọi cửa sổ',
        _ => '全部允許'
      };
  String get processModeRestricted => switch (locale) {
        'en' => 'Only selected apps',
        'vi' => 'Chỉ các ứng dụng đã chọn',
        _ => '只限下列程式'
      };
  String get processModeAllDesc => switch (locale) {
        'en' =>
          'No app list is needed. Any foreground window can trigger translation.',
        'vi' =>
          'Không cần danh sách ứng dụng. Mọi cửa sổ đang hoạt động đều có thể kích hoạt dịch.',
        _ => '不需要指定程式名，任何前景視窗都可以觸發翻譯。'
      };
  String get processModeRestrictedDesc => switch (locale) {
        'en' =>
          'Translation triggers only when one of the selected apps is focused.',
        'vi' =>
          'Chỉ kích hoạt dịch khi một trong các ứng dụng đã chọn đang ở tiền cảnh.',
        _ => '只有你選過的程式在前景時，才會觸發翻譯。'
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
  String get processInputHelp => switch (locale) {
        'en' =>
          'You can paste an .exe path here. Only the file name will be kept.',
        'vi' =>
          'Bạn có thể dán đường dẫn .exe vào đây. Hệ thống sẽ tự giữ lại tên tệp.',
        _ => '也可以直接貼上 .exe 完整路徑，系統會自動只保留檔名。'
      };
  String get processesEmpty => switch (locale) {
        'en' => 'List is empty — all windows can trigger translation',
        'vi' => 'Danh sách trống, tất cả cửa sổ đều có thể kích hoạt dịch',
        _ => '列表為空，所有視窗均可觸發翻譯'
      };
  String get restrictedProcessesEmpty => switch (locale) {
        'en' =>
          'No app selected yet. Translation will not trigger until you add one.',
        'vi' =>
          'Chưa chọn ứng dụng nào. Dịch sẽ không kích hoạt cho đến khi bạn thêm ít nhất một ứng dụng.',
        _ => '尚未加入任何程式，在你加入至少一個程式前，不會觸發翻譯。'
      };
  String processesCount(int n) => switch (locale) {
        'en' => '$n app(s) allowed',
        'vi' => '$n ứng dụng được phép',
        _ => '已限制 $n 個程式'
      };
  String get chooseExeFile => switch (locale) {
        'en' => 'Choose .exe file',
        'vi' => 'Chọn tệp .exe',
        _ => '選擇 .exe 檔'
      };
  String get pickForegroundProcess => switch (locale) {
        'en' => 'Use current window',
        'vi' => 'Dùng cửa sổ hiện tại',
        _ => '加入目前視窗'
      };
  String get refreshProcesses => switch (locale) {
        'en' => 'Refresh list',
        'vi' => 'Làm mới danh sách',
        _ => '重新整理清單'
      };
  String get runningProcessesTitle => switch (locale) {
        'en' => 'Pick from running windows',
        'vi' => 'Chọn từ cửa sổ đang mở',
        _ => '從目前開啟的視窗挑選'
      };
  String get runningProcessesDesc => switch (locale) {
        'en' => 'Click once to add a process instead of typing it manually.',
        'vi' => 'Bấm một lần để thêm chương trình, không cần tự gõ thủ công.',
        _ => '直接點選即可加入，不用自己手動輸入。'
      };
  String get noRunningProcesses => switch (locale) {
        'en' => 'No eligible windows detected right now',
        'vi' => 'Hiện chưa phát hiện cửa sổ phù hợp',
        _ => '目前沒有偵測到可加入的視窗'
      };
  String get processDetectFailed => switch (locale) {
        'en' => 'Failed to detect running windows',
        'vi' => 'Không thể đọc danh sách cửa sổ đang mở',
        _ => '無法讀取目前開啟的視窗清單'
      };
  String foregroundProcessLabel(String process) => switch (locale) {
        'en' => 'Current window: $process',
        'vi' => 'Cửa sổ hiện tại: $process',
        _ => '目前視窗：$process'
      };
}
