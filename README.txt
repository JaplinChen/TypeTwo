TypeTwo Windows Release Toolkit

這份工具包提供：
1. EXE 常駐版建置流程
2. setup.exe 安裝器建置流程

目錄說明：
- src/
  - typetwo_client.py          主程式（熱鍵監聽 + 翻譯 Bridge 合併）
  - settings_ui.py             設定與測試 GUI (tkinter)
  - translator_config.json     設定檔
  - requirements-build.txt
- assets/
  - LOGO-1.jpg, LOGO-2.jpg    品牌素材
- data/
  - glossary.tsv               翻譯詞彙表（可匯入 settings_ui）
  - export.txt                 詞彙表備份
- release/
  - build_client_exe.bat       打包 TypeTwo.exe
  - build_settings_ui.bat      打包 settings_ui.exe
  - make_release.bat           全自動打包 → package\
- installer/
  - typetwo.iss
  - build_installer.bat
- build_all.bat                全流程一鍵建置（EXE + 安裝包）

建置前需求：
- Windows
- Python 3.11+
- Inno Setup 6

建置流程：

A. 只做 EXE
1. 執行 release\make_release.bat

輸出：
- src\dist\TypeTwo.exe
- src\dist\settings_ui.exe
- package\TypeTwo.exe
- package\settings_ui.exe
- package\translator_config.json

B. 做 setup.exe
1. 先完成 EXE 建置
2. 執行 installer\build_installer.bat

輸出：
- installer\output\setup_typetwo.exe

C. 全流程
直接執行：
- build_all.bat

執行方式：
- TypeTwo.exe        主程式（含翻譯服務，Ctrl+Alt+Enter 觸發翻譯）
- settings_ui.exe    設定 GUI
