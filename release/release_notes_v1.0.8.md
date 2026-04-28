## 重點更新

- 新增 **Groq** provider：OpenAI 相容，支援模型列出與 API key 驗證
- 新增**第二翻譯目標**：來源設為「自動偵測」時，可設定備援目標語言；若偵測到來源等於第一目標，自動切換到第二目標（例：偵測到中文 → 改翻越南語）
- **單實例強制**：改用 Windows named mutex，確保只有一個 TypeTwo 視窗，第二次啟動會喚醒已有視窗並直接退出
- **移除 bridge 程序依賴**：Tray 與熱鍵改為直接由 UI 管理，不再需要背景 bridge process
- **Config 遷移至 LOCALAPPDATA**：Windows 設定檔路徑改為 `%LOCALAPPDATA%\TypeTwo\translator_config.json`，並自動遷移舊路徑的設定
- 修正 5xx HTTP 錯誤統一分類為 `service_unavailable`，避免誤判為 provider 設定問題

## 安裝方式

- 下載下方 `setup_typetwo.exe`
- 執行安裝後，從開始選單啟動 TypeTwo
- 若要自動安裝 Ollama 與模型，可執行安裝目錄內的 `install_ollama_and_model.bat`

## 建議升級對象

- 想使用 Groq 雲端推理的使用者
- 需要雙向翻譯（中↔越、中↔英 等）、希望自動切換目標語言的使用者
- 過去遇到多個 TypeTwo 視窗同時存在的使用者

## 已知限制

- 目前仍以 Windows 版本為主
- iOS 版本尚未開始開發
