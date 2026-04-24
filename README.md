# TypeTwo

Windows 雙語輸出翻譯工具。複製文字，按下快捷鍵，剪貼簿自動變成**原文 + 譯文**的雙語格式，直接貼進 Teams、聊天室或任何輸入框。

```
中文：
請問明天的會議幾點開始？

Tiếng Việt：
Cuộc họp ngày mai bắt đầu lúc mấy giờ ạ？
```

支援 Ollama（本機）、OpenAI、Azure OpenAI、Gemini、LM Studio，可自訂翻譯規則與詞彙表。

---

## 功能

- **雙語輸出**：原文 + 譯文同時貼回剪貼簿，貼一次搞定雙語訊息
- **熱鍵觸發**：預設 `Ctrl+Alt+T`，即時翻譯剪貼簿內容
- **多 AI 引擎**：Ollama（本機）、OpenAI、Azure OpenAI、Gemini、LM Studio
- **詞彙表**：固定關鍵詞翻譯，確保術語一致
- **翻譯規則**：自訂 Prompt 規則，控制輸出格式與語氣
- **限定程式**：只在指定 App 內觸發翻譯（例：Teams.exe）
- **系統匣常駐**：背景執行，隨時可用

---

## 架構

```
TypeTwo.exe          ← Python 主程式（熱鍵監聽 + 系統匣）
  └─ Bridge (Flask)  ← 本機 HTTP 翻譯服務（port 8765）

TypeTwoUI.exe        ← Flutter 設定 UI
```

---

## 使用方式

1. 執行 `TypeTwo.exe`（主程式 + Bridge 一起啟動）
2. 執行 `TypeTwoUI.exe` 設定翻譯引擎與語言
3. 複製任意文字 → 按 `Ctrl+Alt+T` → 剪貼簿自動更新為翻譯結果

---

## 安裝

### 下載安裝包（建議）

執行 `installer/output/setup_typetwo.exe`，安裝完成後從開始選單啟動。

### 手動執行

```
package/
  TypeTwo.exe
  TypeTwoUI.exe
  tray_icon.ico
  ui_locale.txt
  translator_config.json
  *.dll
  data/
```

其中 `TypeTwo.exe` 會直接讀取同目錄的 `translator_config.json`、`tray_icon.ico`、`ui_locale.txt`；若只複製兩個 EXE 而沒有帶完整 `package\` 內容，執行時會缺少必要檔案。

---

## 設定

開啟 TypeTwoUI，依分頁設定：

| 分頁 | 說明 |
|------|------|
| 翻譯引擎 | 選擇 Provider、輸入 API Key、選擇模型 |
| 語言設定 | 來源語言、目標語言、輸出格式範本 |
| 翻譯規則 | 每行一條規則，翻譯時強制遵守 |
| 詞彙表 | 固定術語對照（支援匯入 TSV） |
| 限定程式 | 限定觸發翻譯的 .exe 名稱（留空 = 全部允許） |
| 快捷鍵 | 自訂熱鍵組合 |

### Ollama（本機，免費）

```bash
ollama pull translategemma   # 或任何翻譯模型
```

Endpoint 預設為 `http://127.0.0.1:11434/api/chat`。

目前預設翻譯模型順序：

- 主模型：`qwen3:14b`
- 備援模型：`translategemma:4b` → `translategemma:12b` → `qwen3:8b`

當主模型 quota 用盡、暫時失敗，或 Ollama 回傳可 fallback 的錯誤時，TypeTwo 會依上列順序自動切換。

如果要在 Windows 一鍵安裝 Ollama 並下載預設模型，可直接執行：

```bat
package\install_ollama_and_model.bat
```

若要指定模型：

```bat
package\install_ollama_and_model.bat translategemma:4b
```

### LM Studio（本機，OpenAI-compatible）

1. 啟動 LM Studio 本機伺服器
2. 確認 API endpoint 可用，預設為 `http://127.0.0.1:1234/v1/chat/completions`
3. 在 TypeTwoUI 選擇 `LM Studio`
4. 按「取得模型」選擇已載入模型

若你的 LM Studio 放在 reverse proxy 後面，也可以填入帶 path prefix 的 endpoint，例如：

```text
http://127.0.0.1:1234/proxy/lmstudio/v1/chat/completions
```

TypeTwo 會自動用相同前綴去查模型列表，不需要另外手改 `/v1/models`。

---

## 建置

### 需求

- Windows
- Python 3.11+
- Flutter 3.x（建置 UI 時）
- Inno Setup 6（建置安裝包時）

### 只建置 EXE

```bat
release\make_release.bat
```

輸出：`package\TypeTwo.exe`、`package\TypeTwoUI.exe`

### 建置安裝包

```bat
build_all.bat
```

輸出：`installer\output\setup_typetwo.exe`

## 驗證

若要重現並驗證「第一次正常、第二次同文案卻被誤判成沒選取」這個 clipboard 問題，可執行：

```powershell
.\scripts\verify_hotkey_clipboard_bug.ps1
```

若要讓腳本直接輸出 JSON：

```powershell
.\scripts\verify_hotkey_clipboard_bug.ps1 -AsJson
```

預期結果：

- `OldLogicWouldFail` 會是 `True`
- `NewLogicWouldFail` 會是 `False`

代表舊熱鍵邏輯會把「選取內容剛好等於 clipboard 原內容」誤判為失敗，而目前修正後的邏輯不會。

## Release 到 GitHub

- 已提供 GitHub Actions workflow：`.github/workflows/release.yml`
- 已提供日常驗證 workflow：`.github/workflows/ci.yml`
- 當你建立並發佈 GitHub Release 時，workflow 會在 Windows runner 上自動：
  - 建置 Flutter Windows UI
  - 建置 Python `TypeTwo.exe`
  - 建置 Inno Setup 安裝包
  - 將 `installer/output/setup_typetwo.exe` 掛到該次 GitHub Release
- 若只想手動測試流程，可用 `workflow_dispatch` 觸發；安裝包會先以 workflow artifact 形式保存
- 一般 push / pull request 時，CI 會自動執行 `flutter analyze`、`flutter test` 與 Python 單元測試
- 詳細步驟請見 [RELEASING.md](RELEASING.md)

---

## 目錄說明

```
src/
  typetwo_client.py        主程式（熱鍵 + 系統匣 + Bridge 啟動）
  translate_engine.py      Flask Bridge（翻譯 API）
  settings_ui.py           舊版 tkinter 設定 UI
  providers.py             AI Provider 實作
  translator_config.json   設定檔

typetwo_flutter/           Flutter 設定 UI（TypeTwoUI.exe）

assets/                    圖示等靜態資源
data/
  glossary.tsv             詞彙表
installer/
  typetwo.iss              Inno Setup 腳本
release/                   建置腳本
```
