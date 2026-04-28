# TypeTwo

Windows 雙語輸出翻譯工具。選取任意文字，按下快捷鍵，剪貼簿自動變成**原文 + 譯文**的雙語格式，直接貼進 Teams、Line、聊天室或任何輸入框。

```
中文：
請問明天的會議幾點開始？

Tiếng Việt：
Cuộc họp ngày mai bắt đầu lúc mấy giờ ạ？
```

支援 Ollama（本機）、OpenAI、Azure OpenAI、Gemini、Groq、LM Studio，可自訂翻譯規則與詞彙表。

---

## 功能

- **雙語輸出**：原文 + 譯文同時貼回剪貼簿，貼一次搞定雙語訊息
- **熱鍵觸發**：預設 `Ctrl+Alt+T`，即時翻譯選取內容
- **智慧切換目標**：設定第一目標與第二目標，當偵測到來源等於第一目標時自動切換（例：偵測到中文 → 翻譯成越南語）
- **多 AI 引擎**：Ollama（本機免費）、OpenAI、Azure OpenAI、Gemini、Groq、LM Studio
- **備援模型**：設定多組 fallback 模型，主模型失敗自動切換
- **詞彙表**：固定關鍵詞翻譯，確保術語一致
- **翻譯規則**：自訂 Prompt 規則，控制輸出格式與語氣
- **限定程式**：只在指定 App 內觸發翻譯（例：Teams.exe）
- **系統匣常駐**：背景執行，隨時可用
- **單一實例**：第二次啟動自動喚醒已有視窗

---

## 安裝

從 [GitHub Releases](https://github.com/JaplinChen/TypeTwo/releases/latest) 下載 `setup_typetwo.exe`，執行安裝後從開始選單啟動 TypeTwo。

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
| 語言設定 | 來源語言、第一目標語言、第二目標語言、輸出格式範本 |
| 翻譯規則 | 每行一條規則，翻譯時強制遵守 |
| 詞彙表 | 固定術語對照（支援匯入 TSV） |
| 限定程式 | 限定觸發翻譯的 .exe 名稱（留空 = 全部允許） |
| 快捷鍵 | 自訂熱鍵組合 |

設定檔儲存於 `%LOCALAPPDATA%\TypeTwo\translator_config.json`。

### Ollama（本機，免費）

```bash
ollama pull translategemma:4b
```

Endpoint 預設 `http://127.0.0.1:11434/api/chat`。預設模型順序：主模型 `qwen3:14b`，備援 `translategemma:4b` → `translategemma:12b` → `qwen3:8b`。

### Groq（雲端，免費方案可用）

1. 至 [console.groq.com](https://console.groq.com) 取得 API Key
2. 在 TypeTwo 選擇 `Groq`，填入 API Key
3. 按「取得模型」選擇模型（建議 `llama-3.3-70b-versatile`）

### LM Studio（本機，OpenAI-compatible）

1. 啟動 LM Studio 本機伺服器
2. 在 TypeTwo 選擇 `LM Studio`，Endpoint 預設 `http://127.0.0.1:1234/v1/chat/completions`
3. 按「取得模型」選擇已載入模型

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
installer/           Inno Setup 腳本
release/             建置腳本
scripts/             開發工具腳本
src/                 Python 翻譯後端（開發用）
```
