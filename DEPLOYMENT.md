# TypeTwo 部署指南

本文說明 TypeTwo 詞彙表後端的正式部署流程。正式 Beta 建議使用 Linux VPS 或公司 DMZ server，透過 Docker Compose 啟動 FastAPI、PostgreSQL 與 Caddy，對外只開 HTTPS。

## 部署路線

| 路線 | 適用情境 | 注意事項 |
| --- | --- | --- |
| Linux VPS + Docker Engine | 正式內部 Beta 建議路線 | 最接近 production，適合固定 domain、HTTPS、備份與監控 |
| Windows Docker Desktop | 本機驗證或臨時展示 | 不建議承擔正式服務，更新與重啟容易受個人電腦影響 |
| Linux Docker Engine 內網主機 | 公司內網部署 | 若需要公司網路外連線，仍需 DNS、防火牆與 HTTPS |

正式服務不要直接暴露 FastAPI `18000`，也不要長期依賴 ngrok free tunnel。正式入口必須走 Caddy HTTPS reverse proxy。

## 前置需求

- 一台可執行 Docker Compose 的主機。
- 指向該主機的 domain，例如 `typetwo-glossary.company.com`。
- 防火牆允許 80 與 443。
- 一組正式管理員 Email 與強密碼。
- 一組至少 32 字元的 `JWT_SECRET`。

## 建立正式環境檔

在 repo 根目錄複製範本：

```powershell
Copy-Item .env.example.production .env
```

編輯 `.env`，至少替換：

```dotenv
ENVIRONMENT=production
POSTGRES_PASSWORD=replace-with-strong-postgres-password
JWT_SECRET=replace-with-at-least-32-random-characters
ADMIN_EMAIL=admin@company.com
ADMIN_PASSWORD=replace-with-strong-admin-password
GLOSSARY_DOMAIN=typetwo-glossary.company.com
ACME_EMAIL=admin@company.com
PUBLIC_BASE_URL=https://typetwo-glossary.company.com
AUTO_CREATE_TABLES=false
```

若前端 Web 管理頁未來獨立部署，再設定 `CORS_ALLOWED_ORIGINS` 為允許的 HTTPS origin，逗號分隔。Flutter desktop app 不需要 CORS。

## 上線前檢查

在 PowerShell 載入 `.env` 後執行檢查。Windows 可用：

```powershell
Get-Content .env | Where-Object { $_ -and $_ -notmatch '^#' } | ForEach-Object {
  $name, $value = $_ -split '=', 2
  [Environment]::SetEnvironmentVariable($name, $value, 'Process')
}

.\scripts\check_typetwo_prod_env.ps1
```

檢查會擋下預設 secret、弱密碼、非 production 環境、非 HTTPS `PUBLIC_BASE_URL`，以及 `AUTO_CREATE_TABLES=true`。

## Migration 與啟動

正式環境必須先跑 Alembic migration，再啟動完整服務：

```powershell
docker compose up -d db
docker compose run --rm -e AUTO_CREATE_TABLES=false api alembic upgrade head
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

確認服務狀態：

```powershell
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
Invoke-RestMethod https://typetwo-glossary.company.com/health
```

`/health` 回傳 `ok: true` 與 `db: "ok"` 代表 API 已連到 DB。

## Smoke 驗證

正式或 staging domain 啟動後執行：

```powershell
.\scripts\smoke_typetwo_glossary_api.ps1 -BaseUrl https://typetwo-glossary.company.com
```

Smoke test 會建立臨時詞彙與臨時使用者，預設會清理當次建立的 smoke 詞彙並停用 smoke 使用者。cleanup 失敗會讓測試失敗。

## App 設定

TypeTwo Flutter App 的詞彙表同步 URL 請填正式 domain：

```text
https://typetwo-glossary.company.com
```

公司網路外不可填 `localhost`，因為那只會指向使用者自己的電腦。

## 備份

Docker volume 不是備份。正式環境至少每天做一次 `pg_dump`，並把壓縮檔放在 Docker host 之外：

```powershell
.\scripts\backup_typetwo_postgres.ps1 -OutputDir .\backups -KeepDays 30
```

還原演練請先在臨時主機或臨時 volume 上執行：

```powershell
.\scripts\restore_typetwo_postgres.ps1 -BackupZip .\backups\typetwo_YYYYMMDD_HHMMSS.sql.zip
```

## 升級

每次升級前：

1. 確認目前 production smoke 通過。
2. 執行資料庫備份。
3. 在 staging 或臨時環境跑 migration。
4. 啟動新 image 或新 commit。
5. 再跑 smoke 驗證。

## Rollback

若升級後 smoke 失敗：

1. 保留失敗現場 logs。
2. 切回上一版 backend image 或上一個 commit。
3. 若 migration 已破壞資料，依備份還原流程回復 DB。
4. 回復後重新執行 `/health` 與 smoke test。

只有在確認資料 schema 與舊版程式相容時，才可只 rollback app 不還原 DB。
