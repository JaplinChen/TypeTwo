# 專案索引

更新時間：2026-05-21

## 專案摘要

- TypeTwo 是 Windows 優先的雙語翻譯工具，使用 Flutter 提供主程式、設定 UI、熱鍵與系統匣；`src` 保留 Python 翻譯後端與歷史相容程式碼。

## 目錄職責

- `typetwo_flutter/lib`：Flutter app 主程式、設定畫面、Provider 設定、翻譯流程、Windows 平台整合。
- `typetwo_flutter/test`：Flutter unit/widget tests，覆蓋 config、provider、翻譯 template、詞彙表與更新檢查。
- `src`：Python 翻譯 bridge、歷史相容工具與 Python tests；避免把 `src/.venv` 視為原始碼。
- `scripts`：本機驗證與 package smoke test。
- `installer`：Inno Setup installer 腳本。
- `release`：發版輔助腳本；實際建置入口是 repo 根目錄 `build_all.bat`。
- `.github/workflows`：CI 與 Release Windows Installer workflow。

## 常用命令

- `flutter analyze`（工作目錄 `typetwo_flutter`）：檢查 Dart/Flutter 靜態問題。
- `flutter test`（工作目錄 `typetwo_flutter`）：執行 Flutter 測試。
- `python -m pytest src\tests`（工作目錄 repo 根目錄）：執行 Python 測試。
- `python -m unittest src.tests.test_build_all_script -v`：快速驗證發版腳本與 smoke test 文字防回歸。
- `build_all.bat`：建置 Flutter Windows app、整理 `package\`、若有 Inno Setup 則建置 installer。

## 驗證策略

- 改 `typetwo_flutter/lib`：至少跑 `flutter analyze` 與相關 `flutter test`；核心服務變更跑完整 `flutter test`。
- 改 `src` 或發版腳本：跑 `python -m pytest src\tests`。
- 改 `build_all.bat`、`release`、`installer`、`scripts/package_smoke_test.ps1`：跑 `python -m unittest src.tests.test_build_all_script -v`。
- 改 package/installer 輸出：本機可再跑 `.\scripts\package_smoke_test.ps1`，但需先確認沒有既有 `TypeTwo` 程序。

## 重要規則

- 發版 staging 以 `build_all.bat` 為唯一入口，不手動把檔案丟進 `package\` 當作完成。
- 使用者設定在 `%APPDATA%\TypeTwo\`，首次執行從 Flutter bundled assets 初始化。
- Provider 模型列表與連線檢查需經由 `ProviderService` adapter 規則，避免翻譯 endpoint 與檢查 endpoint 分歧。
- `oz-skills/` 目前是未追蹤外部內容，不納入 TypeTwo 產品程式碼審查。

## 常用入口

- `typetwo_flutter/lib/main.dart`：Flutter app 啟動、單一實例、熱鍵與 tray 初始化。
- `typetwo_flutter/lib/services/translate_service.dart`：翻譯 orchestration、fallback model、template、post-processing。
- `typetwo_flutter/lib/services/provider_service.dart`：Provider model list/check adapter 入口。
- `typetwo_flutter/lib/services/config_service.dart`：設定檔載入、遷移、儲存與損壞備份。
- `typetwo_flutter/lib/models/app_config.dart`：目前的設定聚合模型。
- `src/translation_providers.py`：Python provider 翻譯流程。
- `scripts/package_smoke_test.ps1`：package EXE smoke test。
