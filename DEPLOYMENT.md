# TypeTwo Server 部署手冊

## 部署前 gate

在 staging 或 production 部署前，必須先完成下列檢查：

```powershell
py -3.12 -m pytest backend\tests
.\scripts\check_backend_migrations.ps1 -Python py
.\scripts\check_typetwo_prod_env.ps1
```

若使用 `py` 啟動器，migration gate 可用：

```powershell
.\scripts\check_backend_migrations.ps1 -Python py -PythonArgs -3.12
```

若 `DATABASE_URL` 已設定，migration gate 會對該資料庫執行 `alembic upgrade head` 並確認目前 revision 已到 head；若未設定，則只做單一 head 檢查與 SQL 產生，不能取代 staging/production 前的 PostgreSQL migration gate。

`check_typetwo_prod_env.ps1` 需要下列 production 環境變數已設定：

- `ENVIRONMENT=production`
- `POSTGRES_PASSWORD`
- `JWT_SECRET`
- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`
- `GLOSSARY_DOMAIN`
- `ACME_EMAIL`
- `PUBLIC_BASE_URL=https://<GLOSSARY_DOMAIN>`
- `AUTO_CREATE_TABLES=false`

可從範本建立正式環境檔：

```powershell
Copy-Item .env.example.production .env
notepad .env
```

## Staging smoke

先建立或還原一份 staging DB，再執行：

```powershell
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
.\scripts\smoke_typetwo_glossary_api.ps1 `
  -BaseUrl "https://staging.example.com" `
  -AdminEmail $env:ADMIN_EMAIL `
  -AdminPassword $env:ADMIN_PASSWORD
```

smoke script 會建立臨時 approved 詞彙、臨時 user、pending 建議詞，驗證 approve 後可進 approved 詞彙包，最後刪除 smoke 詞彙、停用 smoke user，並確認既有 token 已失效。

## Production 部署

1. 備份 production PostgreSQL。
2. 確認 release artifact：
   - `setup_typetwo.exe`
   - `typetwo-glossary-api-<version>.tar`
3. 載入或拉取 backend image，tag 必須是 release version 或 git SHA，不使用 `latest` 部署 production。
4. 執行 Alembic migration：

```powershell
docker compose exec api alembic upgrade head
```

5. 啟動服務：

```powershell
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

6. 執行 production smoke：

```powershell
.\scripts\smoke_typetwo_glossary_api.ps1 `
  -BaseUrl $env:PUBLIC_BASE_URL `
  -AdminEmail $env:ADMIN_EMAIL `
  -AdminPassword $env:ADMIN_PASSWORD
```

## 備份與還原驗證

建立備份：

```powershell
.\scripts\backup_typetwo_postgres.ps1 -OutputDir .\backups -KeepDays 30
```

還原到目前 compose DB：

```powershell
.\scripts\restore_typetwo_postgres.ps1 -BackupZip .\backups\typetwo_<timestamp>.sql.zip
```

部署前應先把備份還原到臨時 Docker volume 驗證，不要直接拿 production DB 做演練：

```powershell
.\scripts\verify_typetwo_postgres_backup.ps1 `
  -BackupZip .\backups\typetwo_<timestamp>.sql.zip
```

驗證腳本會用獨立 compose project 啟動 PostgreSQL、匯入備份，並確認 `users`、`glossary_terms`、`glossary_term_history` 三張必要資料表存在；預設結束時會刪除臨時 container 與 volume。

## 部署後檢查

- `/health` 回傳 `ok=true`、`db=ok`、`environment=production`。
- Caddy HTTPS 憑證有效。
- Flutter App 可登入 TypeTwo Server。
- 詞彙同步、pending review、匯入預覽、history restore 可操作。
