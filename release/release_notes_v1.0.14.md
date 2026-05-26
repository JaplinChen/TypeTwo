## 重點更新

- **修正越南文 không dấu 問題**：翻譯成越南文時，prompt 會明確要求輸出標準越南語並保留 đầy đủ dấu，避免 `Máy tính` 被模型輸出成 `May tinh`
- **強化詞彙表後端 production guard**：正式環境會拒絕預設 JWT secret、預設 PostgreSQL 密碼、弱 admin 密碼、`AUTO_CREATE_TABLES=true` 與非 HTTPS `PUBLIC_BASE_URL`
- **補齊公司內部部署文件**：新增 `.env.example.production`、`DEPLOYMENT.md` 與 `RELEASE_CHECKLIST.md`，整理 Caddy HTTPS、Alembic migration、smoke test、備份與 rollback 流程
- **改善帳號生命週期 API**：新增 `/auth/me` 與 `/auth/change-password`，登入會更新 `lastLoginAt`，使用者狀態也包含 `mustChangePassword`、`updatedAt`
- **強化 smoke test**：API smoke 會等待 `/health` 穩定，並在 cleanup 後確認 smoke 詞彙已刪、smoke user 已停用、既有 token 已失效

## 安裝方式

- 下載下方 `setup_typetwo.exe`
- 執行安裝後，從開始選單啟動 TypeTwo
- 若要自動安裝 Ollama 與模型，可執行安裝目錄內的 `install_ollama_and_model.bat`

## 建議升級對象

- 翻譯越南文時遇到缺少聲調符號的使用者
- 需要部署 TypeTwo 詞彙表後端給公司內部使用的管理員
- 需要管理詞彙表帳號、驗證 migration、smoke test、備份與 rollback 的維運者
