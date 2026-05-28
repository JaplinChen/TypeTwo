# TypeTwo 發版檢查清單

每次發版都要能回答：發了什麼、如何驗證、如何部署、如何回退、資料如何保護。

## 本機檢查

```powershell
python -m pytest backend\tests
python -m pytest src\tests
```

Flutter 變更需加跑：

```powershell
cd typetwo_flutter
flutter analyze
flutter test
```

## Docker 與設定檢查

```powershell
.\scripts\check_typetwo_prod_env.ps1
docker compose -f docker-compose.yml -f docker-compose.prod.yml config
docker compose build api
```

正式 `.env` 必須符合：

- `ENVIRONMENT=production`
- `PUBLIC_BASE_URL` 使用 `https://`
- `AUTO_CREATE_TABLES=false`
- `JWT_SECRET` 至少 32 字元且不是預設值
- `POSTGRES_PASSWORD` 與 `ADMIN_PASSWORD` 不是預設值

## Migration 閘門

部署前必須先備份：

```powershell
.\scripts\backup_typetwo_postgres.ps1 -OutputDir .\backups -KeepDays 30
```

再執行 migration：

```powershell
docker compose up -d db
docker compose run --rm -e AUTO_CREATE_TABLES=false api alembic upgrade head
```

## Staging Smoke 驗證

```powershell
.\scripts\smoke_typetwo_glossary_api.ps1 -BaseUrl https://staging-domain
```

驗收項目：

- `/health` 回傳 `ok: true` 與 `db: "ok"`。
- admin 可登入。
- approved 詞彙包可讀取。
- user 建立詞彙後狀態為 pending。
- admin approve 後詞彙可同步。
- smoke cleanup 成功。
- cleanup 後查不到 smoke 詞彙，smoke user 為 inactive，既有 token 不能繼續呼叫 API。

## Production 部署

```powershell
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
.\scripts\smoke_typetwo_glossary_api.ps1 -BaseUrl https://production-domain
```

部署完成後確認：

- Caddy 只開 80/443。
- FastAPI `18000` 沒有對外暴露。
- 備份排程仍可執行。
- App 可用正式 domain 登入並同步 approved 詞彙。

## Rollback

保留以下資訊：

- 上一版 commit 或 image tag。
- 部署前備份檔路徑。
- migration revision。
- smoke test output。

若需要回退：

```powershell
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
git checkout <previous-release>
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
.\scripts\smoke_typetwo_glossary_api.ps1 -BaseUrl https://production-domain
```

若 schema 或資料已不相容，先依 `DEPLOYMENT.md` 的還原流程回復 DB，再啟動舊版服務。
