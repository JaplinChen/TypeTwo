# TypeTwo

Windows 雙語輸出翻譯工具。複製文字，按下快捷鍵，剪貼簿自動變成**原文 + 譯文**的雙語格式，直接貼進 Teams、聊天室或任何輸入框。

```
中文：
請問明天的會議幾點開始？

Tiếng Việt：
Cuộc họp ngày mai bắt đầu lúc mấy giờ ạ？
```

支援 Ollama（本機）、OpenAI、Azure OpenAI、Gemini，可自訂翻譯規則與詞彙表。

---

## 功能

- **雙語輸出**：原文 + 譯文同時貼回剪貼簿，貼一次搞定雙語訊息
- **熱鍵觸發**：預設 `Ctrl+Alt+Enter`，即時翻譯剪貼簿內容
- **多 AI 引擎**：Ollama（本機）、OpenAI、Azure OpenAI、Gemini
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
3. 複製任意文字 → 按 `Ctrl+Alt+Enter` → 剪貼簿自動更新為翻譯結果

---

## 安裝

### 下載安裝包（建議）

執行 `installer/output/setup_typetwo.exe`，安裝完成後從開始選單啟動。

### 手動執行

```
package/
  TypeTwo.exe
  TypeTwoUI.exe
  translator_config.json
```

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
