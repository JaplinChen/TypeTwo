## 重點更新

- **新增獨立雲端同步設定頁**：詞彙表同步設定集中到「雲端同步」分頁，詞彙表頁上方只保留同步空間選擇與同步按鈕。
- **支援常用同步空間**：可使用 TypeTwo Server、WebDAV / Nextcloud、OneDrive、Dropbox、Google Drive、Synology Drive 或本機雲端資料夾保存詞彙表快照。
- **新增測試連線**：雲端同步頁可直接檢查 TypeTwo Server、WebDAV 或同步資料夾是否可用。
- **同步備份與還原**：同步前會自動建立本機詞彙快照，雲端同步頁可從備份清單還原；還原前也會先備份目前詞彙，避免誤還原後遺失當前版本。
- **改善同步可靠性**：新增 WebDAV / 本機資料夾 provider、同步前備份服務、備份檔名去重與對應測試覆蓋。

## 安裝方式

- 下載下方 `setup_typetwo.exe`
- 執行安裝後，從開始選單啟動 TypeTwo

## 建議升級對象

- 需要將詞彙表同步到自己雲端空間的使用者
- 想使用 OneDrive、Dropbox、Google Drive、Synology Drive、WebDAV / Nextcloud 管理詞彙表快照的使用者
- 需要同步前自動備份與可還原機制的使用者
