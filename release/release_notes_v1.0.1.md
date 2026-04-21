## 重點更新

- 修正 Azure OpenAI 整合，Flutter UI 與 Python bridge 現在都會使用正確的 `api-key` 協定
- 改善 bridge ownership 與熱鍵初始化流程，避免設定 UI 啟動時誤搶全域熱鍵
- bridge 停止流程改為只停止由目前 UI 啟動的程序，不再用程序名稱強殺所有 `TypeTwo`
- 新增 Flutter 與 Python 正式回歸測試，涵蓋 Azure OpenAI、template 套用、config round-trip、glossary 篩選等核心行為
- 新增 GitHub Actions：
  - PR / push 自動執行品質檢查
  - GitHub Release 自動建置並附加 Windows 安裝包

## 安裝方式

- 下載下方 `setup_typetwo.exe`
- 執行安裝後，從開始選單啟動 TypeTwo

## 建議升級對象

- 正在使用 OpenAI / Azure OpenAI / Gemini 的使用者
- 需要較穩定 Windows 熱鍵與 bridge 啟停行為的使用者
- 想直接從 GitHub Release 取得最新安裝包的使用者

## 已知限制

- 目前仍以 Windows 版本為主
- iOS 版本尚未開始開發
- repo 內仍保留安裝包輸出檔，方便直接發佈給使用者
