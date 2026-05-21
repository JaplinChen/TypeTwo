## 重點更新

- **設定檔損壞時保留備份**：若 `translator_config.json` 無法解析，TypeTwo 會保留 `translator_config.json.corrupt.*` 備份，再回到預設設定，降低 API Key、Endpoint、翻譯規則與其他設定遺失風險
- **改善自訂 Endpoint 相容性**：OpenAI 與 Groq 使用相容 API Endpoint 時，「取得模型」與「測試連線」會使用同一個 host 的 `/models` 路徑，不再固定打到官方 API
- **整理發版流程**：`build_all.bat` 是 package 與 installer 的主要建置入口，舊的 Python settings UI 打包流程已標示淘汰，文件與 smoke test 說明已同步

## 安裝方式

- 下載下方 `setup_typetwo.exe`
- 執行安裝後，從開始選單啟動 TypeTwo
- 若要自動安裝 Ollama 與模型，可執行安裝目錄內的 `install_ollama_and_model.bat`

## 建議升級對象

- 使用自訂 OpenAI-compatible Endpoint 或 Groq-compatible Endpoint 的使用者
- 曾遇到設定檔損壞、重設後需要找回原設定的使用者
- 需要從原始碼建置或維護 release package 的開發者
