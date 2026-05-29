# TypeTwo 詞彙表後端

此目錄提供 TypeTwo 詞彙表雲端同步服務。後端使用 FastAPI，資料庫使用 PostgreSQL，正式部署建議透過根目錄 `docker-compose.yml` 啟動。

## 本機測試

在專案根目錄執行：

```powershell
python -m pytest backend\tests
```

測試會使用 SQLite in-memory database，不需要先啟動 Docker。

## Docker 啟動

在專案根目錄執行：

```powershell
docker compose up --build
```

只建立並確認 TypeTwo API image：

```powershell
.\scripts\verify_typetwo_docker.ps1
```

建立 image、啟動 API、驗證 `/health`，驗證後清理測試 container 與 volume：

```powershell
.\scripts\verify_typetwo_docker.ps1 -RunHealthCheck -Cleanup
```

若要保留服務持續執行並測試登入、approved 詞彙包、一般 user 建議 pending、admin approve 流程：

```powershell
docker compose up -d --build
.\scripts\smoke_typetwo_glossary_api.ps1
```

Smoke test 會建立臨時 approved 詞彙、臨時一般使用者、pending 建議詞，並驗證 admin approve 後可進入 approved 詞彙包。預設執行結束會刪除當次建立的 smoke 詞彙、停用當次建立的 smoke 使用者，並再次查詢確認 smoke 詞彙已不存在、smoke 使用者已停用、既有 token 已無法繼續呼叫 API；若清理或清理驗證失敗，腳本會以失敗結束，避免測試污染被誤判為通過。若需要保留測試資料方便手動排查，可加上：

```powershell
.\scripts\smoke_typetwo_glossary_api.ps1 -KeepSmokeData
```

預設會啟動：

- `api`：FastAPI，對外開發用 `http://localhost:18000`
- `db`：PostgreSQL，只在 Docker network 內部使用
- `typetwo_pgdata`：PostgreSQL volume

健康檢查：

```http
GET http://localhost:18000/health
```

回傳 `db: "ok"` 代表 API 可以正常連到資料庫；`migrationRevision` 會顯示目前 Alembic revision，若開發環境尚未建立 `alembic_version` 則為 `null`。Docker Compose 也已設定 DB 與 API healthcheck，可用下列指令查看：
所有 API response 都會包含 `X-Request-ID` header；若 client 有傳入同名 header，後端會沿用該值，方便使用者回報錯誤時對應伺服器 log。

```powershell
docker compose ps
```

Docker image 名稱固定為：

```text
typetwo-glossary-api:latest
```

若 Docker Desktop 的 Images 頁面顯示載入錯誤，先用 CLI 確認 image 是否存在：

```powershell
docker images typetwo-glossary-api
```

若 `docker ps` 或 `docker images` 長時間沒有回應，代表 Docker Desktop daemon/API 可能卡住；重啟 Docker Desktop 後再執行 `.\scripts\verify_typetwo_docker.ps1`。

也可以先用診斷腳本確認 Docker Desktop 狀態：

```powershell
.\scripts\repair_docker_desktop.ps1
```

若診斷顯示 `docker ps` 逾時，再執行修復模式：

```powershell
.\scripts\repair_docker_desktop.ps1 -Apply
```

修復模式會關閉並重新啟動 Docker Desktop 與 `docker-desktop` WSL distro，會暫停正在執行的 container，但不會刪除 image、container 或 volume。

## 資料庫 migration

開發環境預設 `AUTO_CREATE_TABLES=true`，API 啟動時會自動建表，方便本機快速測試。

正式環境建議改用 Alembic 管理 schema：

```powershell
$env:DATABASE_URL="postgresql+psycopg://typetwo:strong-password@localhost:5432/typetwo"
cd backend
alembic upgrade head
```

若使用 Docker Compose，可在 DB 健康後執行：

```powershell
docker compose up -d db
docker compose run --rm -e AUTO_CREATE_TABLES=false api alembic upgrade head
```

確認 migration 可產生 SQL：

```powershell
cd backend
alembic upgrade head --sql
```

當正式資料庫已由 migration 建好後，可設定：

```powershell
$env:AUTO_CREATE_TABLES="false"
```

正式環境必須覆蓋這些環境變數：

```powershell
$env:ENVIRONMENT="production"
$env:POSTGRES_PASSWORD="strong-password"
$env:JWT_SECRET="at-least-32-bytes-secret"
$env:ADMIN_EMAIL="admin@example.com"
$env:ADMIN_PASSWORD="strong-admin-password"
$env:PUBLIC_BASE_URL="https://typetwo-glossary.company.com"
$env:AUTO_CREATE_TABLES="false"
docker compose up --build -d
```

## 正式 HTTPS 部署

正式環境建議使用 Caddy 自動申請 TLS certificate：

```powershell
$env:GLOSSARY_DOMAIN="glossary.example.com"
$env:ACME_EMAIL="admin@example.com"
$env:ENVIRONMENT="production"
$env:POSTGRES_PASSWORD="strong-password"
$env:JWT_SECRET="at-least-32-bytes-secret"
$env:ADMIN_EMAIL="admin@example.com"
$env:ADMIN_PASSWORD="strong-admin-password"
$env:PUBLIC_BASE_URL="https://glossary.example.com"
$env:AUTO_CREATE_TABLES="false"
.\scripts\check_typetwo_prod_env.ps1
docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
```

正式 overlay 會：

- 只開 `80/443` 給 Caddy。
- 不直接對外開 FastAPI 的 `18000`。
- PostgreSQL 仍只在 Docker network 內部使用。

`check_typetwo_prod_env.ps1` 只檢查環境變數，不會啟動服務。它會擋下常見正式部署錯誤：

- 缺少必要環境變數。
- `POSTGRES_PASSWORD`、`JWT_SECRET`、`ADMIN_PASSWORD` 仍使用開發預設值。
- secret 長度太短。
- Email 格式錯誤。
- `GLOSSARY_DOMAIN` 仍是 `example.com`。
- `PUBLIC_BASE_URL` 不是 HTTPS。
- `AUTO_CREATE_TABLES` 未關閉。
- `CORS_ALLOWED_ORIGINS` 使用 `*` 或非 HTTPS origin。

更完整的正式部署、migration、smoke、備份與 rollback 流程請見根目錄 [DEPLOYMENT.md](../DEPLOYMENT.md)。發版前檢查請見 [RELEASE_CHECKLIST.md](../RELEASE_CHECKLIST.md)。

## 初始管理員

啟動時若 `ADMIN_EMAIL` 與 `ADMIN_PASSWORD` 有值，系統會自動建立第一個 `admin` 使用者。若同 email 已存在，不會覆蓋密碼。

## 匯入現有 glossary.json

後端啟動並連到資料庫後，可匯入目前 Flutter asset：

```powershell
docker compose exec api python scripts/import_glossary.py /app/assets/glossary.json
```

若在本機直接跑 script，需先設定 `DATABASE_URL`，並指定實際檔案路徑：

```powershell
$env:DATABASE_URL="postgresql+psycopg://typetwo:password@localhost:5432/typetwo"
python backend\scripts\import_glossary.py typetwo_flutter\assets\glossary.json
```

## 主要 API

登入：

```http
POST /auth/login
```

同一 client IP 與 email 在短時間內連續登入失敗會被暫時限制，回傳 `429`，降低暴力嘗試風險。

目前登入者與改密碼：

```http
GET  /auth/me
POST /auth/change-password
Authorization: Bearer <token>
```

讀取 App 可用詞彙包：

```http
GET /glossary?status=approved
Authorization: Bearer <token>
```

回傳格式：

```json
{
  "glossary": {
    "申請": "Nộp đơn"
  },
  "langGlossary": {
    "繁體中文-越南文": {
      "簽核": "Ký duyệt"
    }
  },
  "syncedAt": "2026-05-22T10:00:00Z"
}
```

維護詞彙需要 `admin` 或 `editor` 角色：

```http
POST   /glossary
PUT    /glossary/{id}
DELETE /glossary/{id}
POST   /glossary/import/preview
POST   /glossary/import
```

`/glossary/import/preview` 不會寫入資料庫，會回傳每筆匯入資料的 `imported`、`updated`、`unchanged` 或 `skipped` 判定，以及總計數，讓管理員可在正式匯入前確認影響範圍。

匯入 payload 可使用 `conflictStrategy` 控制既有詞彙處理方式：

- `overwrite`：預設值，既有詞彙會被匯入內容覆蓋。
- `keepExisting`：既有詞彙會保留，preview 會將不同內容標示為 `skipped`。

一般 `user` 也可以 `POST /glossary` 提交詞彙建議，但後端會自動將狀態設為 `pending`，不會直接進入 approved 詞彙包。

審核 API：

```http
GET    /glossary/terms?status=pending
POST   /glossary/{id}/approve
POST   /glossary/{id}/reject
GET    /glossary/{id}/history
POST   /glossary/{id}/history/{history_id}/restore
```

`approve/reject/history/restore` 需要 `admin` 或 `editor`。`restore` 會將詞彙回復到指定 history snapshot，並新增一筆 `restore` history。

使用者管理 API 需要 `admin`：

```http
GET  /users
POST /users
PUT  /users/{id}
POST /users/{id}/reset-password
```

可用於建立詞彙表使用者、調整 `user/editor/admin` 角色、啟用或停用帳號，以及重設使用者密碼。
使用者回傳內容包含 `mustChangePassword`、`lastLoginAt`、`createdAt`、`updatedAt`，方便管理員確認帳號狀態。
重設密碼會回傳一次性臨時密碼，並將 `mustChangePassword` 設為 `true`。

## 輸入驗證

API 會在資料進入資料庫前檢查：

- 使用者角色只能是 `user`、`editor`、`admin`。
- 詞彙狀態只能是 `approved`、`pending`、`rejected`。
- Email 會自動去除前後空白並轉小寫。
- 新增或更新詞彙時，原文不可為空。
- 建立或更新密碼時，密碼至少需要 6 個字元。

## 備份

Docker volume 不是備份。正式環境至少每天做一次 `pg_dump`，並把備份檔放到 Docker host 之外。

範例：

```powershell
docker compose exec db pg_dump -U typetwo typetwo > typetwo_backup.sql
```

建議再加上壓縮、保留天數與外部儲存上傳流程。

專案已提供 PowerShell 腳本：

```powershell
.\scripts\backup_typetwo_postgres.ps1 -OutputDir .\backups -KeepDays 30
.\scripts\restore_typetwo_postgres.ps1 -BackupZip .\backups\typetwo_YYYYMMDD_HHMMSS.sql.zip
```
