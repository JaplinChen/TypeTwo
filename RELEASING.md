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

## GitHub 發版方式

### 方式 1：正式發版

1. 先把要發版的 commit push 到 GitHub
2. 建立 tag，例如 `v1.0.2`
3. 到 GitHub 建立對應的 Release，並按下 Publish
4. GitHub Actions 會自動：
   - 建置 Flutter Windows UI
   - 建置 Python `TypeTwo.exe`
   - 建立 `setup_typetwo.exe`
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

- `installer/output/setup_typetwo.exe` 目前保留在 repo，因為你會直接拿它發佈給使用者
- `typetwo_flutter/ios/` 目前已忽略，等真的開始開發 iOS 再納入版控
- 若 workflow 失敗，先看：
  - Flutter Windows build 是否失敗
  - Python 打包依賴是否安裝成功
  - Inno Setup 是否正常安裝
