## 重點更新

- 新增 **LM Studio** provider：OpenAI 相容 endpoint，支援模型列出與驗證，路徑 prefix 會被保留
- **Windows 打包加固**：Python client 改以 PyInstaller onedir 模式打包，消除過去出現雙 `TypeTwo.exe` process 的情況
- **單實例**：以 named Windows kernel event 實作，並提供 `/quit` HTTP fallback
- **Process restrict mode**：新增 `restrictToAllowedProcesses` 設定，可選擇「全部視窗都翻譯」或「只允許指定 process」
- 新增前景視窗 picker（Win32 FFI），方便加入白名單
- 被擋下的 hotkey 改為靜默丟棄，不再彈出訊息框
- **預設 hotkey** 從 `Ctrl+Alt+Enter` 改為 `Ctrl+Alt+T`
- Installer 預先下載三組備援 Ollama 模型：`qwen3:14b`、`translategemma:4b`、`translategemma:12b`
- Config service 清理：移除 `path_provider` 與 bridge-sync 重複邏輯（onedir 後 exe 同目錄即為設定來源）

## 安裝方式

- 下載下方 `setup_typetwo.exe`
- 執行安裝後，從開始選單啟動 TypeTwo
- 若要自動安裝 Ollama 與模型，可執行安裝目錄內的 `install_ollama_and_model.bat`

## 建議升級對象

- 想使用本機 LM Studio 做為翻譯 provider 的使用者
- 想在特定 app（例如只在 Chrome、Notepad）才觸發翻譯熱鍵的使用者
- 過去遇到雙 `TypeTwo.exe` 同時跑、或關不掉舊實例的使用者

## 已知限制

- 目前仍以 Windows 版本為主
- iOS 版本尚未開始開發
