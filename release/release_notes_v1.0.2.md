## 重點更新

- 將 `Ollama` 調整為主力預設 provider，預設模型統一為 `translategemma:4b`
- 實際翻譯仍以 TypeTwoUI 儲存的模型設定為準，不會被程式內建預設覆蓋
- 移除 `Gemini 429` 的自動重試，避免 quota / rate limit 時一次翻譯被放大成多次請求
- 強化 `127.0.0.1:8765` bridge 啟動驗證，避免誤連到其他本機服務或被異常 `apiVersion` 回應弄掛
- 新增一鍵安裝腳本 `install_ollama_and_model.bat`，可自動安裝 Ollama 並下載指定模型
- `install_ollama_and_model.bat` 的使用提示改為英文，方便直接提供給非中文使用者

## 安裝方式

- 下載下方 `setup_typetwo.exe`
- 執行安裝後，從開始選單啟動 TypeTwo
- 若要自動安裝 Ollama 與模型，可執行安裝目錄內的 `install_ollama_and_model.bat`

## 建議升級對象

- 主要使用本機 Ollama 翻譯的使用者
- 經常遇到 Gemini quota / rate limit 的使用者
- 曾遇過 `127.0.0.1:8765`、`404 /translate`、`500 /translate` 類型錯誤的使用者

## 已知限制

- 目前仍以 Windows 版本為主
- iOS 版本尚未開始開發
- repo 內仍保留安裝包輸出檔，方便直接發佈給使用者
