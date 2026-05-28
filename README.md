# TypeTwo

Windows 雙語輸出翻譯工具。選取任意文字，按下快捷鍵，剪貼簿自動變成**原文 + 譯文**的雙語格式，直接貼進 Teams、Line、聊天室或任何輸入框。

```
請問明天的會議幾點開始？
Cuộc họp ngày mai bắt đầu lúc mấy giờ ạ？
```

支援 Ollama（本機）、OpenAI、Azure OpenAI、Gemini、Groq，可自訂翻譯規則與詞彙表。

---

## 功能

- **雙語輸出**：原文 + 譯文同時貼回剪貼簿，貼一次搞定雙語訊息
- **熱鍵觸發**：預設 `Ctrl+Alt+T`，即時翻譯選取內容
- **智慧切換目標**：設定第一目標與第二目標，當偵測到來源等於第一目標時自動切換（例：偵測到中文 → 翻譯成越南語）
- **多 AI 引擎**：Ollama（本機免費）、OpenAI、Azure OpenAI、Gemini、Groq
- **各 Provider 設定獨立儲存**：切換 Provider 時自動保存 API Key、Endpoint 與模型，切回時自動還原
- **備援模型**：設定多組 fallback 模型，主模型失敗自動切換
- **詞彙表**：固定關鍵詞翻譯，支援搜尋、TSV/JSON 匯入匯出與反向套用（例：`業務 ↔ Kinh doanh`）
- **詞彙表雲端同步**：可連到 TypeTwo 詞彙表後端、WebDAV / Nextcloud，也可使用 OneDrive、Dropbox、Google Drive、Synology Drive、本機或公司檔案伺服器（含 UNC 路徑）保存詞彙表快照；支援拖曳調整多個同步目標的優先順序
- **翻譯糾錯**：翻譯結果出現後可點擊糾錯按鈕，輸入正確翻譯，一鍵加入詞彙表，下次同樣原文自動套用
- **翻譯規則**：自訂 Prompt 規則，控制輸出格式與語氣
- **越南語後處理**：翻譯結果自動修正 LLM 常見遺漏——日期格式（`2024/5/25` → `25/5/2024`）、時間（`下午3點半` → `3 giờ rưỡi chiều`）、星期、標點符號、單位、稱謂、書面語詞等；越南文輸出會明確要求保留 đầy đủ dấu，避免變成 không dấu
- **自動更新**：啟動時靜默檢查 GitHub Releases，有新版即顯示通知；也可在「關於」手動觸發更新檢查
- **限定程式**：只在指定 App 內觸發翻譯（例：Teams.exe）
- **系統匣常駐**：背景執行，隨時可用
- **單一實例**：第二次啟動自動喚醒已有視窗

---

## 安裝

從 [GitHub Releases](https://github.com/JaplinChen/TypeTwo/releases/latest) 下載 `setup_typetwo.exe`，執行安裝後從開始選單啟動 TypeTwo。
升級安裝時，安裝程式會先結束正在系統匣常駐的舊版 TypeTwo，再覆蓋新版檔案。

若要使用本機 Ollama 模型：

```bat
package\install_ollama_and_model.bat
```

---

## 使用方式

1. 從開始選單啟動 TypeTwo（系統匣常駐）
2. 在設定視窗選擇翻譯引擎與語言
3. 在任意視窗選取文字 → 按 `Ctrl+Alt+T` → 剪貼簿自動更新為翻譯結果

---

## 設定

開啟 TypeTwo，依分頁設定：

| 分頁 | 說明 |
|------|------|
| 翻譯引擎 | 選擇 Provider、輸入 API Key、選擇模型與備援模型 |
| 語言設定 | 來源語言、第一目標語言、第二目標語言、自訂輸出格式範本（`{source}`、`{translation}`） |
| 翻譯規則 | 每行一條規則，翻譯時強制遵守 |
| 詞彙表 | 固定術語對照，支援搜尋、TSV/JSON 匯入匯出，以及依目標語言自動反向套用；頁面上方只保留同步空間與同步按鈕 |
| 雲端同步 | 設定詞彙表同步空間，可選 TypeTwo Server、WebDAV / Nextcloud、OneDrive、Dropbox、Google Drive、Synology Drive 或本機或公司檔案伺服器（含 UNC 路徑），並可登入、同步、審核與管理使用者；支援拖曳調整同步目標順序 |
| 限定程式 | 限定觸發翻譯的 .exe 名稱（留空 = 全部允許） |
| 快捷鍵 | 自訂熱鍵組合 |

設定檔儲存於目前使用者的 AppData 目錄（Windows 預設 `%APPDATA%\TypeTwo\`）：

- `translator_config.json`：所有設定（引擎、語言、規則等）
- `glossary.json`：詞彙表

如果 `translator_config.json` 損壞，TypeTwo 會保留一份
`translator_config.json.corrupt.*` 備份，再回到預設設定；遇到這種情況時可從備份檔找回原本的 API Key、Endpoint、翻譯規則或其他設定。

### 自訂 Endpoint

OpenAI 與 Groq 可使用相容 API Endpoint。當 Endpoint 指向
`/chat/completions` 時，「取得模型」與「測試連線」會自動使用同一個 host 的
`/models` 路徑，不會固定打到官方 API。

### Ollama（本機，免費）

```bash
ollama pull translategemma:4b
```

Endpoint 預設 `http://127.0.0.1:11434/api/chat`。預設模型順序：主模型 `qwen3:8b`，備援 `translategemma:4b` → `translategemma:12b` → `qwen3:14b`。

### Groq（雲端，免費方案可用）

1. 至 [console.groq.com](https://console.groq.com) 取得 API Key
2. 在 TypeTwo 選擇 `Groq`，填入 API Key
3. 按「取得模型」選擇模型（建議 `llama-3.3-70b-versatile`）

### 詞彙表雲端同步

詞彙表分頁上方只保留「同步空間」與「同步」按鈕；完整設定移到「雲端同步」分頁。

目前支援兩種同步空間：

- **TypeTwo Server**：使用既有 FastAPI 詞彙表後端，適合公司共用詞彙庫、角色權限、pending 審核與使用者管理。
- **WebDAV / Nextcloud**：輸入 WebDAV 資料夾 URL、帳號與密碼或 app password。TypeTwo 會在該遠端資料夾讀寫 `glossary.snapshot.json`。
- **OneDrive / Dropbox / Google Drive / Synology Drive**：選擇這些官方桌面同步工具已同步到本機的資料夾。TypeTwo 會在該資料夾寫入 `glossary.snapshot.json`，雲端硬碟客戶端負責把檔案同步到其他裝置。
- **本機或公司檔案伺服器**：選擇任意本機資料夾或 UNC 路徑（如 `\\server\share\TypeTwo`），適合 iCloud Drive、pCloud、MEGA、公司共享磁碟（SMB）或其他未列出的網絡空間。

使用 TypeTwo Server 時，同步開啟後：

- App 會拉取後端 approved 詞彙包並合併到本機設定。
- 本機新增、修改、刪除詞彙時會嘗試推送到後端；若當下離線，會先保留在待同步佇列，恢復連線後再送出。
- `admin` 與 `editor` 可以審核 pending 詞彙建議。
- `admin` 可以管理詞彙表使用者與角色；後端支援目前登入者查詢與使用者自行改密碼。

使用 OneDrive、Dropbox、Google Drive、Synology Drive 或本機或公司檔案伺服器時，第一次同步會建立 `glossary.snapshot.json`；之後同步會讀取該快照並與本機詞彙表合併，再寫回同一個快照檔。這個模式不需要 TypeTwo 後端，適合個人或小團隊用既有雲端硬碟或公司共享磁碟同步詞彙表。

使用 WebDAV / Nextcloud 時，請填到「存放 TypeTwo 詞彙表的資料夾」URL，必須以 `http://` 或 `https://` 開頭（不支援 UNC 路徑）。例如 Nextcloud 常見格式為 `https://cloud.example.com/remote.php/dav/files/使用者/TypeTwo`。若服務支援 app password，建議使用 app password；若不需要驗證，帳號密碼可留空。

每次按「同步」前，TypeTwo 會先在 `%APPDATA%\TypeTwo\glossary_sync_backups\` 建立本機詞彙快照備份，預設保留最近 10 份。需要回復時，可在「雲端同步」分頁按「還原備份」，從最近的備份清單選擇一份還原到本機詞彙表；還原前也會自動先備份目前詞彙，避免誤還原後無法找回當前版本。

設定完成後可先按「測試連線」：

- TypeTwo Server 會檢查 `/health` 是否可連。
- WebDAV / Nextcloud 會檢查遠端資料夾是否可連。
- OneDrive、Dropbox、Google Drive、Synology Drive 與本機雲端資料夾會檢查指定資料夾是否可寫入。

正式部署建議使用 Linux VPS 或公司 DMZ server + Docker Compose + Caddy HTTPS，不直接暴露 FastAPI port。後端部署、Docker、migration、備份與 API 說明請見 [backend/README.md](backend/README.md)，完整 production runbook 請見 [DEPLOYMENT.md](DEPLOYMENT.md)。

---

## 建置

### 需求

- Windows
- Flutter 3.32+
- Inno Setup 6（建置安裝包時）

### 建置安裝包

```bat
build_all.bat
```

輸出：`installer\output\setup_typetwo.exe`

### CI / Release

詳細步驟請見 [RELEASING.md](RELEASING.md)。GitHub Actions 會在發布 Release 時自動建置並附加安裝包。

---

## 目錄說明

```
typetwo_flutter/     Flutter 主程式（UI、熱鍵、系統匣）
backend/             FastAPI 詞彙表雲端同步後端
installer/           Inno Setup 腳本
release/             發版輔助腳本（實際建置入口為根目錄 build_all.bat）
scripts/             開發工具腳本
src/                 Python 翻譯後端與歷史相容程式碼
```
