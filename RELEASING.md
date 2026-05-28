# TypeTwo 發版流程

本專案目前以 **Windows 版本優先**，GitHub Release 會自動建置並附加安裝包。

## 版本規則

- 建議使用 `v主版號.次版號.修訂號`
- 例如：
  - `v1.0.0`
  - `v1.0.1`
  - `v1.1.0`

## 發版前檢查

在本機先確認：

```bat
cd D:\Works\TypeTwo\typetwo_flutter
flutter analyze
flutter test

cd D:\Works\TypeTwo
python -m unittest discover -s src\tests -p "test_*.py" -v
```

若要先本機產生安裝包再目測確認：

```bat
cd D:\Works\TypeTwo
build_all.bat
```

若要在本機對 `package` 內的 EXE 做快速 smoke test：

```powershell
.\scripts\package_smoke_test.ps1
```

這個 smoke test 目前會檢查：

- `TypeTwo.exe` 第一次啟動會新增一個程序，第二次啟動不會再新增程序
- 若 cleanup 失敗，會輸出殘留程序摘要，方便定位是哪個舊實例卡住

若本機已經有既有 `TypeTwo` 在執行，可先嘗試自動清理再測：

```powershell
.\scripts\package_smoke_test.ps1 -TryCleanupExisting
```

## `package` / installer 對齊原則

- `build_all.bat` 是 `package\` staging 的唯一入口
- 不要手動把檔案直接丟進 `package\` 後就視為完成，因為下次 build 可能會被覆蓋或殘留
- `TypeTwo.exe` 是 Flutter Windows app，依賴 `package\data\` 與根目錄 DLL
- 首次執行會從 Flutter bundled assets 初始化設定，使用者設定儲存在 `%APPDATA%\TypeTwo\`
- package 內保留以下輔助檔：
  - `translator_config.json`（預設設定備份）
  - `glossary.json`（預設詞彙表備份）
  - `install_ollama_and_model.bat`（提供給使用者手動安裝 Ollama）
- installer 應以 `package\` 為主要來源
- 若新增 `TypeTwo.exe` 執行期要讀取或 package 需附帶的檔案，必須同時更新：
  - `build_all.bat`
  - `installer\typetwo.iss`
  - `src/tests/test_build_all_script.py`

## GitHub 發版方式

### 方式 1：正式發版

1. 先把要發版的 commit push 到 GitHub
2. 建立 tag，例如 `v1.0.2`
3. 到 GitHub 建立對應的 Release，並按下 Publish
4. GitHub Actions 會自動：
   - 跑 Flutter analyze / Flutter test
   - 跑 Python 單元測試
   - 建置 Flutter Windows UI
   - 建立 `setup_typetwo.exe`
   - 對 `package\TypeTwo.exe` 做 smoke test
   - 把安裝包附加到該次 Release

### 方式 2：手動測試 workflow

1. 到 GitHub Actions
2. 選 `Release Windows Installer`
3. 使用 `Run workflow`
4. 安裝包會先出現在 workflow artifacts

## Release 內容建議

Release title 建議：

```text
TypeTwo v1.0.2
```

Release notes 建議格式：

```markdown
## 重點更新
- 修正 Azure OpenAI 整合流程
- 改善 bridge ownership 與熱鍵初始化
- 新增正式測試與 GitHub 自動發版

## 安裝方式
- 下載下方 `setup_typetwo.exe`
- 執行安裝後，從開始選單啟動 TypeTwo

## 已知限制
- 目前以 Windows 版本為主
- iOS 版本尚未開始開發
```

## 注意事項

- `installer/output/` 已從 repo 移除（gitignored），安裝包改由 GitHub Release workflow 自動建置並附加到對應 release。本機 build 出的 `setup_typetwo.exe` 僅供本地驗證使用
- `typetwo_flutter/ios/` 目前已忽略，等真的開始開發 iOS 再納入版控
- 若 workflow 失敗，先看：
  - Flutter / Python 測試是否失敗
  - Flutter Windows build 是否失敗
  - Python 打包依賴是否安裝成功
  - `scripts/package_smoke_test.ps1` 是否發現啟動即崩潰
  - Inno Setup 是否正常安裝

## 現成範本

- 本次 `v1.0.1` 的 release notes 草稿：`release/release_notes_v1.0.1.md`
