# TypeTwo

> Windows 雙語輸出翻譯工具

---

## 怎麼用

```mermaid
flowchart LR
    A["① 選取文字\n（任何 App）"] -->|"Ctrl+Alt+T"| B(["翻譯"])
    B --> C["② 剪貼簿更新\n原文 + 譯文"]
    C -->|"貼上"| D["Teams / Line\n任何輸入框"]

    style B fill:#2563eb,color:#fff,stroke:#1d4ed8
    style C fill:#166534,color:#fff,stroke:#14532d
```

---

## 支援的 AI 引擎

```mermaid
graph LR
    subgraph local["本機（免費，不需網路）"]
        Ollama
    end
    subgraph cloud["雲端"]
        OpenAI
        Gemini
        Azure["Azure OpenAI"]
        Groq["Groq\n免費方案可用"]
    end

    style local fill:#1c3a2a,stroke:#22c55e,color:#86efac
    style cloud fill:#1e2a3a,stroke:#3b82f6,color:#93c5fd
```

每個 Provider 的 API Key、Endpoint、模型各自獨立儲存，切換時自動還原。

---

## 主要功能

```mermaid
mindmap
  root((TypeTwo))
    翻譯
      雙語輸出：原文＋譯文同時貼回剪貼簿
      智慧切換：偵測到中文自動改翻越南語
      備援模型：主模型失敗自動切換
      翻譯糾錯：一鍵將正確翻譯存入詞彙表
    詞彙表
      固定術語翻譯
      搜尋 / 篩選
      CSV 匯入匯出
      雲端同步
    系統
      系統匣常駐
      啟動時自動檢查更新
      限定特定 App 才觸發
```

---

## 設定分頁

| 分頁 | 功能 |
|------|------|
| 翻譯引擎 | Provider、API Key、模型、備援模型、測試連線 |
| 語言設定 | 來源語言、目標語言、輸出格式範本 |
| 翻譯規則 | 自訂 Prompt，每行一條 |
| 詞彙表 | 術語對照、搜尋、匯入匯出、同步狀態列 |
| 雲端同步 | 同步空間設定、備份還原、角色管理 |
| 限定程式 | 只在指定 .exe 內觸發 |
| 快捷鍵 | 自訂熱鍵組合 |

---

## 詞彙表雲端同步

```mermaid
flowchart TD
    S(["選擇同步空間"]) --> A["TypeTwo Server"]
    S --> B["WebDAV / Nextcloud"]
    S --> C["OneDrive\nDropbox\nGoogle Drive\nSynology Drive"]
    S --> D["本機 / 公司檔案伺服器"]

    A --> A1["公司共用詞彙庫\n角色權限 · Pending 審核\n使用者管理"]
    B --> B1["填 URL + 帳密\n需 http:// 或 https://"]
    C --> C1["選本機同步資料夾即可\n不需額外 API Key"]
    D --> D1["含 UNC 路徑\n例：\\\\server\\share\\TypeTwo"]

    style S fill:#2563eb,color:#fff,stroke:#1d4ed8
    style A1 fill:#1c3a2a,stroke:#22c55e,color:#86efac
    style B1 fill:#1e2a3a,stroke:#3b82f6,color:#93c5fd
    style C1 fill:#1e2a3a,stroke:#3b82f6,color:#93c5fd
    style D1 fill:#1e2a3a,stroke:#3b82f6,color:#93c5fd
```

多個同步空間可拖曳調整優先順序。每次同步前自動備份，可從清單選擇還原點。

---

## 安裝

從 [GitHub Releases](https://github.com/JaplinChen/TypeTwo/releases/latest) 下載 `setup_typetwo.exe` → 執行 → 從開始選單啟動。

升級安裝時自動關閉舊版再覆蓋，不需手動結束程式。

**使用 Ollama（本機免費）：**

```bat
package\install_ollama_and_model.bat
```

---

## 建置 / 開發

```
typetwo_flutter/   Flutter 主程式（UI、熱鍵、系統匣）
backend/           FastAPI 詞彙表後端
installer/         Inno Setup 腳本
```

```bat
build_all.bat      # 輸出 installer\output\setup_typetwo.exe
```

後端部署請見 [backend/README.md](backend/README.md)　｜　Production runbook 請見 [DEPLOYMENT.md](DEPLOYMENT.md)　｜　發版檢查請見 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)　｜　完成度審核請見 [COMPLETION_AUDIT.md](COMPLETION_AUDIT.md)　｜　回退手冊請見 [ROLLBACK_RUNBOOK.md](ROLLBACK_RUNBOOK.md)
