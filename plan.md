# TypeTwo 詞彙表雲端化實作計畫

## 目標

將目前的本機 `glossary.json` 改造成可多人共同維護、可在公司內外網使用、可離線快取的詞彙表系統。

目前 TypeTwo 的詞彙表流程是：

- Flutter 第一次啟動時，從 `typetwo_flutter/assets/glossary.json` 初始化。
- 之後每台電腦各自儲存在 `%APPDATA%\TypeTwo\glossary.json`。
- 翻譯時由 `GlossaryService` 從本機詞彙表挑出相關詞彙，放進 LLM prompt。

目標流程是：

- PostgreSQL 作為詞彙表唯一資料來源。
- FastAPI 提供詞彙查詢、維護、匯入、匯出與同步 API。
- TypeTwo App 啟動時先讀本機快取，背景同步雲端詞彙。
- 使用者出差在外地時，只要有網路即可同步；沒有網路時仍可使用上次同步的本機詞彙表。

## 建議架構

```text
TypeTwo Flutter App / TypeTwo.exe
  |
  | HTTPS + token
  v
FastAPI Backend
  |
  | SQLAlchemy / asyncpg
  v
PostgreSQL
```

正式部署建議使用 Docker Compose：

```text
VPS / Cloud VM
  |
  ├─ Nginx 或 Caddy：HTTPS reverse proxy
  ├─ FastAPI container：詞彙表 API
  ├─ PostgreSQL container：資料庫
  ├─ Docker volume：PostgreSQL data
  └─ backup job：每日 pg_dump 到外部儲存
```

重要原則：

- App 不直接連 PostgreSQL，只能透過 HTTPS API。
- PostgreSQL 不對外開放，只允許 Docker internal network 存取。
- 詞彙資料不能只存在 container filesystem，必須存在 Docker volume 或外部磁碟。
- Docker volume 不是備份，必須另外做 `pg_dump` 與外部備份。

## 資料模型

第一版建議先支援全域詞彙與語言方向詞彙，對應現有 `glossary` 與 `langGlossary`。

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE glossary_terms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_text TEXT NOT NULL,
  target_text TEXT NOT NULL,
  source_lang TEXT,
  target_lang TEXT,
  context_key TEXT NOT NULL DEFAULT 'global',
  status TEXT NOT NULL DEFAULT 'approved',
  version INTEGER NOT NULL DEFAULT 1,
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX glossary_terms_unique_active
ON glossary_terms (context_key, source_text, source_lang, target_lang)
WHERE deleted_at IS NULL;
```

`context_key` 規則：

```text
global
繁體中文-越南文
越南文-繁體中文
英文-繁體中文
```

`status` 建議值：

```text
approved：已核准，可用於翻譯
pending：使用者提交，等待審核
rejected：已退回，不用於翻譯
```

第二階段可新增歷史紀錄表：

```sql
CREATE TABLE glossary_term_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  term_id UUID NOT NULL REFERENCES glossary_terms(id),
  source_text TEXT NOT NULL,
  target_text TEXT NOT NULL,
  source_lang TEXT,
  target_lang TEXT,
  context_key TEXT NOT NULL,
  status TEXT NOT NULL,
  version INTEGER NOT NULL,
  changed_by UUID REFERENCES users(id),
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  change_reason TEXT
);
```

## API 設計

第一版 API：

```http
POST   /auth/login
GET    /glossary
GET    /glossary/changes?since=2026-05-22T00:00:00Z
POST   /glossary
PUT    /glossary/{id}
DELETE /glossary/{id}
POST   /glossary/import
GET    /glossary/export
```

App 最常用的同步 API：

```http
GET /glossary?status=approved
```

建議回傳格式維持接近現有 `AppConfig`，降低 Flutter 改動：

```json
{
  "glossary": {
    "申請": "Nộp đơn",
    "表單": "Biểu mẫu"
  },
  "langGlossary": {
    "繁體中文-越南文": {
      "簽核": "Ký duyệt"
    }
  },
  "syncedAt": "2026-05-22T10:00:00Z"
}
```

新增詞彙：

```http
POST /glossary
```

```json
{
  "sourceText": "簽核",
  "targetText": "Ký duyệt",
  "sourceLang": "繁體中文",
  "targetLang": "越南文",
  "contextKey": "繁體中文-越南文"
}
```

## 權限設計

第一版可採簡化權限：

```text
admin：管理使用者、匯入、匯出、刪除、核准
editor：新增、修改詞彙
user：讀取 approved 詞彙，提交 pending 詞彙
```

若要更快上線，第一階段可以先做：

```text
admin/editor：可維護詞彙
所有登入使用者：可讀取 approved 詞彙
```

安全注意事項：

- 不可把 PostgreSQL 帳號密碼放進 Flutter App。
- 不可把後端管理密鑰放進 Flutter App。
- App 只保存登入 token 或 API token。
- API 需使用 HTTPS。
- PostgreSQL 只在 Docker network 內部存取。

## Flutter 端改動

保留現有 `ConfigService` 與本機 `glossary.json` 機制，新增遠端同步層。

建議新增：

```text
GlossaryRemoteService：呼叫 FastAPI
GlossarySyncService：處理本機快取、遠端同步、離線狀態
```

調整後流程：

```text
啟動 TypeTwo
  -> 先讀取本機 glossary.json
  -> 立即可翻譯
  -> 背景呼叫 FastAPI 拉取 approved 詞彙
  -> 同步成功後更新 ConfigProvider
  -> 寫回本機 glossary.json 作為快取
```

使用者維護詞彙：

```text
新增 / 修改 / 刪除詞彙
  -> 有網路：呼叫 FastAPI
  -> API 成功後更新本機快取
  -> 沒網路：保留在 pending changes
  -> 下次有網路時自動同步
```

第一版可以先不做完整離線編輯，只做：

- 沒網路時可使用本機快取翻譯。
- 沒網路時禁止維護詞彙，顯示同步失敗狀態。
- 第二階段再加 pending changes。

## Docker 部署方案

建議 `docker-compose.yml` 結構：

```yaml
services:
  api:
    build: ./backend
    environment:
      DATABASE_URL: postgresql+asyncpg://typetwo:${POSTGRES_PASSWORD}@db:5432/typetwo
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      - db
    networks:
      - typetwo_net

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: typetwo
      POSTGRES_USER: typetwo
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - typetwo_pgdata:/var/lib/postgresql/data
    networks:
      - typetwo_net

volumes:
  typetwo_pgdata:

networks:
  typetwo_net:
```

外部流量：

```text
443 HTTPS -> Nginx / Caddy -> FastAPI container
```

不建議：

```text
外部網路 -> PostgreSQL port 5432
```

## 備份策略

最低要求：

- 每日 `pg_dump`。
- 備份檔保留至少 14 到 30 天。
- 備份檔存到 Docker host 之外，例如 S3、NAS、OneDrive、Google Drive 或另一台 server。
- 每月至少測試一次 restore。

範例備份流程：

```text
每天凌晨 02:00
  -> docker exec postgres pg_dump
  -> 壓縮備份檔
  -> 上傳外部儲存
  -> 刪除超過保留期限的舊備份
```

## 現有資料匯入

匯入來源：

```text
typetwo_flutter/assets/glossary.json
```

匯入規則：

```text
JSON key   -> source_text
JSON value -> target_text
context    -> global
status     -> approved
```

匯入後仍保留 bundled `assets/glossary.json` 作為首次安裝或離線預設資料，但正式資料來源改為 FastAPI。

## 實作階段

### 目前完成狀態

**日期：** 2026-05-22

已完成第一版可驗證基礎：

- 已新增 `backend/` FastAPI 詞彙表服務。
- 已新增 PostgreSQL Docker Compose 設定。
- 已實作登入、詞彙查詢、詞彙 CRUD、匯入、匯出 API。
- 已新增 `glossary.json` 匯入 script。
- 已新增 Flutter 遠端同步設定欄位、同步按鈕與本機快取更新流程。
- 已新增 Flutter 雲端同步面板，支援 URL、Email、Password 登入。
- 已支援遠端啟用時新增、修改、刪除詞彙同步到 FastAPI；未啟用遠端時保留原本本機設定頁流程。
- 已支援離線 pending changes：遠端失敗時先保存本機並排入待同步，下一次同步會先推送 pending 再拉取 approved 詞彙。
- 後端已新增 `glossary_term_history`，並在 create/update/delete/import 時記錄變更。
- 已新增審核流程：一般 `user` 提交的詞彙會進入 `pending`；`editor/admin` 可 approve/reject 並查 history。
- Flutter 雲端同步面板會顯示登入角色、提供登出，`editor/admin` 會看到「審核」入口並可在 UI 內核准或退回 pending 詞彙。
- `GET /glossary/changes?since=...` 已包含 soft delete 詞彙，回傳 `deletedAt` 供客戶端辨識刪除事件。
- 已保留原本本機 `glossary.json` 離線翻譯行為。
- 已新增後端與 Flutter 測試。
- Docker Compose 對外開發 port 改為 `18000:8000`，避免常見本機 `8000` port 衝突；正式部署仍建議走 HTTPS reverse proxy。
- 已新增 Caddy HTTPS reverse proxy 範本：`deploy/Caddyfile` 與 `docker-compose.prod.yml`。
- 已新增 PostgreSQL 備份與還原腳本：`scripts/backup_typetwo_postgres.ps1`、`scripts/restore_typetwo_postgres.ps1`。
- 已新增 admin 使用者管理 API：查詢使用者、建立使用者、調整角色、啟用或停用帳號。
- Flutter 雲端同步面板已新增 admin「使用者」入口，可在 UI 內管理詞彙表使用者。
- `GET /health` 已改為檢查資料庫連線，Docker Compose 已加入 PostgreSQL 與 API healthcheck。
- 已新增 `.dockerignore` 與 `.gitignore` 規則，避免 Docker build context 與 Git 納入快取、備份與本機 secrets。
- 已新增 Alembic 設定與第一版 migration，正式環境可使用版本化 schema 管理。
- 已強化 API 輸入驗證，避免非法角色、非法詞彙狀態、空白原文與弱密碼進入資料庫。
- 已新增 Docker image 驗證腳本，可建立 `typetwo-glossary-api:latest` 並可選擇啟動 `/health` 實測。
- 已新增 Docker Desktop 診斷/修復腳本，預設只診斷；加 `-Apply` 才會重啟 Docker Desktop。
- 已新增正式環境變數檢查腳本，避免用開發預設密碼或範例網域部署。

已驗證：

```powershell
python -m pytest backend\tests
flutter test
docker compose config
docker compose up --build -d
docker compose -f docker-compose.yml -f docker-compose.prod.yml config
cd backend; alembic upgrade head --sql
docker compose run --rm -e AUTO_CREATE_TABLES=false api alembic upgrade head
.\scripts\verify_typetwo_docker.ps1 -RunHealthCheck -Cleanup
.\scripts\repair_docker_desktop.ps1
.\scripts\check_typetwo_prod_env.ps1
```

Docker 端到端實測：

- `GET /health` 正常。
- Docker API container healthcheck 會進入 `healthy`。
- Alembic migration 已在 Docker PostgreSQL 上實際執行成功。
- API 已用 `AUTO_CREATE_TABLES=false` 啟動並通過 `/health`，確認正式環境可依賴 migration 建表。
- API 已實測拒絕非法 status、非法 role、空白原文與弱密碼。
- `scripts/verify_typetwo_docker.ps1` 已可用於確認 Docker daemon、image build、container health 與 `/health`。
- `scripts/repair_docker_desktop.ps1` 已可用於診斷 Docker Desktop daemon/API 逾時問題，並提供明確修復入口。
- `scripts/check_typetwo_prod_env.ps1` 已可用於正式部署前檢查必要 secrets、Email 與網域設定。
- `POST /auth/login` 可取得 admin token。
- `scripts/import_glossary.py /app/assets/glossary.json` 可匯入 bundled glossary。
- `GET /glossary?status=approved` 可讀回 approved 詞彙包。
- `scripts/backup_typetwo_postgres.ps1` 可產出 `.sql.zip` 備份。
- 一般 user 提交詞彙會得到 `pending`，admin approve 後狀態變為 `approved`，history 會記錄 `create,approve`。
- 實測後已執行 `docker compose down -v` 清理測試容器與 volume。

### 第一階段：後端基礎（已完成）

- 建立 `backend/` FastAPI 專案。
- 建立 PostgreSQL Docker Compose。
- 加入 SQLAlchemy 2.0、asyncpg、Alembic。
- 建立 `users` 與 `glossary_terms` migration。
- 實作 glossary CRUD API。
- 實作現有 `glossary.json` 匯入 script。

完成標準：

- 可用 API 新增、查詢、修改、刪除詞彙。
- 可將現有 `glossary.json` 匯入 PostgreSQL。
- 可透過 `GET /glossary?status=approved` 取得 App 可用格式。

### 第二階段：Flutter 同步（已完成）

- 新增 `GlossaryRemoteService`。
- 新增 `GlossarySyncService`。
- 啟動時先讀本機快取，再背景同步遠端。
- 同步成功後更新 `ConfigProvider` 與本機 `glossary.json`。
- 詞彙表頁新增手動同步按鈕與同步狀態。

完成標準：

- 沒網路時可使用本機詞彙翻譯。
- 有網路時可同步 PostgreSQL 內的 approved 詞彙。
- 同步後翻譯會使用最新詞彙。

### 第三階段：多人維護（已完成）

- 詞彙表頁新增、修改、刪除改為呼叫 API。
- 加入登入或 API token 設定。
- 加入 editor/admin 權限。
- 加入匯入、匯出功能。

完成標準：

- 多位使用者可共同維護同一份詞彙表。
- 一人更新詞彙後，其他使用者同步即可取得最新版本。
- 未授權使用者不能修改詞彙。

### 第四階段：正式部署（已完成第一版）

- VPS 或 Cloud VM 部署 Docker Compose。
- 設定 Nginx 或 Caddy。
- 設定 HTTPS 與正式網域。
- 設定環境變數與 secrets。
- 設定每日備份。
- 加入基本監控與錯誤 log。

完成標準：

- 公司內部與外地出差都可透過 HTTPS 同步。
- PostgreSQL 不直接暴露到外網。
- 有可還原的資料庫備份。

### 第五階段：進階同步與審核（已完成第一版）

- 支援離線 pending changes。
- 支援 `GET /glossary/changes?since=...` 增量同步。
- 支援詞彙審核流程。
- 支援詞彙歷史版本。
- 支援衝突處理。

完成標準：

- 離線維護的詞彙可在恢復網路後同步。
- 多人同時修改同一詞彙時不會靜默覆蓋。
- 管理者可追蹤詞彙變更歷史。

## 已完成實作清單

- 後端：FastAPI、SQLAlchemy、JWT、角色權限、輸入驗證、詞彙 CRUD、匯入匯出、審核、歷史紀錄、增量變更、使用者管理、健康檢查。
- 資料庫：PostgreSQL Docker volume 保存資料；測試使用 SQLite in-memory，降低本機驗證門檻。
- Migration：Alembic 已建立初始 schema migration，可逐步取代正式環境自動建表。
- 部署：開發 Docker Compose、正式 Caddy HTTPS overlay、資料庫不對外開 port、API healthcheck、DB healthcheck。
- 備份：PowerShell 備份與還原腳本，備份檔以 `.sql.zip` 保存並支援保留天數清理。
- Flutter：遠端登入、角色顯示、同步、離線 pending changes、審核 UI、使用者管理 UI、原本本機詞彙快取保留。
- 測試：後端 API 測試、Flutter model/provider/service/UI 測試、Docker Compose 設定檢查、Docker 端到端實測。

## 後續可選強化

目前已達到第一版「多人維護、內外網可用、離線可讀、Docker 可部署、可備份」目標。後續若要進一步提高正式營運等級，建議再做：

- Token refresh 與撤銷：目前使用單一 JWT 效期，後續可加入 refresh token、登入紀錄與強制登出。
- 衝突提示：目前 pending changes 推送失敗會保留待同步，後續可用 `version` 做更細緻的衝突比較與 UI 合併。
- 監控告警：加入 uptime monitor、錯誤 log 收集與備份失敗通知。

## 風險與處理

| 風險 | 處理方式 |
|---|---|
| Server 無法連線 | App 使用本機 `glossary.json` 快取 |
| PostgreSQL container 重建導致資料遺失 | 使用 Docker volume，不將資料放在 container filesystem |
| Docker volume 損壞或主機故障 | 每日 `pg_dump` 到外部儲存 |
| App token 外洩 | token 可撤銷，API 依角色限制權限 |
| 多人同時修改同一詞彙 | 第一版使用最後更新者勝出；第二版加入 version 與 history |
| 詞彙表過大影響 prompt | 沿用目前 `GlossaryService.pickRelevant()`，只放命中的詞彙 |
| 外網直接攻擊資料庫 | PostgreSQL 不開外部 port，只開 HTTPS API |

## 推薦決策

建議採用：

```text
FastAPI + PostgreSQL + Docker Compose + Nginx/Caddy + HTTPS + 本機快取
```

理由：

- 符合公司內外網使用需求。
- 保留 TypeTwo 目前本機詞彙表快取機制，離線仍可翻譯。
- 後端可控，未來可擴充審核、版本歷史、匯入匯出與權限。
- Docker Compose 對第一版正式環境足夠簡單。

不建議第一版直接做太完整的離線雙向同步。先完成雲端讀取、手動同步、多人維護與備份，再進入離線 pending changes 與衝突處理。
