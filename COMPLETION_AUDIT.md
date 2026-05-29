# TypeTwo 產品化完成度審核

日期：2026-05-29

本文用來區分「本階段產品化已完成並驗證」與「後續部署到真實 staging / production 時才需要驗證」的項目。依目前決策，真實主機、DNS、production DB 與 rollback 實機演練暫不納入本階段完成條件。

## 結論

M0-M5 的 repo 內產品化工作已完成：程式、文件、測試、本機 production-like 驗證、CI、release artifact、checksum、部署前置工具與 deployment evidence gate 都已驗證。真實 HTTPS domain、staging/production smoke、production 備份還原與 rollback 實機演練改列為「後續部署時驗證」，不再阻塞本階段完成。

## 本機已完成證據

| 階段 | 狀態 | 證據 |
| --- | --- | --- |
| M0 產品化基線 | 本機完成 | production guard、`.env.example.production`、`DEPLOYMENT.md`、`RELEASE_CHECKLIST.md`、production env check 與 Docker smoke 已驗證 |
| M1 公司內部 Beta 可部署 | 本階段完成 | production compose、migration flow、備份與臨時 volume 還原驗證腳本、deployment gate 與 production env 產生工具已完成；真實外部 HTTPS domain 改列後續部署時驗證 |
| M2 帳號與管理 UX | 本機完成 | user management、改密碼、reset password、停用帳號 token 失效、角色權限測試已納入既有測試集 |
| M3 同步 UX 產品化 | 本機完成 | `/health` 診斷、token 失效處理、未登入停用同步、pending queue 保留與 Flutter 測試已完成 |
| M4 詞彙治理 | 本機完成 | pending 搜尋與批次審核、reject reason、history、restore、匯入預覽、匯出、匯入衝突策略與測試已完成 |
| M5 發版與維運閉環 | CI 與 workflow artifact 已驗證 | CI backend-quality、windows-quality、migration gate、Docker build、smoke、release backend artifact、installer artifact、checksum、rollback runbook 與備份還原驗證已完成 |

## 最近驗證結果

- `flutter analyze`：通過。
- `flutter test`：97 passed。
- `py -3.12 -m pytest backend\tests`：34 passed。
- `py -3.12 -m pytest src\tests`：81 passed。
- `.\scripts\check_backend_migrations.ps1 -Python py -PythonArgs -3.12`：通過。
- `docker compose build api`：通過。
- `docker compose up -d --build` + `.\scripts\smoke_typetwo_glossary_api.ps1` + `.\scripts\backup_typetwo_postgres.ps1` + `.\scripts\verify_typetwo_postgres_backup.ps1` + `docker compose down -v`：通過。
- `git diff --check`：通過，僅有既有 CRLF warning。
- GitHub PR #44 `CI / backend-quality`：通過。
- GitHub PR #44 `CI / windows-quality`：通過。
- GitHub Actions workflow_dispatch run `26616184411`：通過，已產出 `setup_typetwo` 與 `typetwo-glossary-api-codex-productize-typetwo-m0-m5` artifacts。
- workflow artifact checksum：`setup_typetwo.exe.sha256` 與 backend image tar `.sha256` 皆已下載後重新計算並驗證一致。
- GitHub PR #45 版本更新：通過並已合併。
- `master` CI run `26617148862`：`backend-quality` 與 `windows-quality` 皆通過。
- GitHub Release `v1.0.18`：release workflow run `26617247786` 通過，已附加 `setup_typetwo.exe`、`setup_typetwo.exe.sha256`、`typetwo-glossary-api-v1.0.18.tar`、`typetwo-glossary-api-v1.0.18.tar.sha256`。
- GitHub Release `v1.0.18` checksum：release assets 已下載後重新計算，installer 與 backend image checksum 皆吻合。
- 已新增 `scripts/test_typetwo_deployment_gate.ps1`，可對 staging/production URL 執行 `/health`、smoke、備份還原驗證並輸出 evidence JSON。
- 已新增 GitHub Actions `Deployment Gate` workflow，設定 environment secrets 後可手動對 staging/production URL 產出 deployment evidence artifact。
- 本機 Docker 已實測 `test_typetwo_deployment_gate.ps1 -AllowHttp -ExpectedEnvironment development`，`health` 與 `smoke` 均通過，cleanup 成功；production/staging 仍需真實 HTTPS URL 重跑。
- 已新增 `scripts/new_typetwo_prod_env.ps1`，可產生強 secret production `.env` 並立即套用 `check_typetwo_prod_env.ps1` 驗證。
- 已新增 `scripts/test_typetwo_release_artifacts.ps1`，可下載 GitHub Release assets 並重新計算 installer/backend image SHA256。
- 已實測 `new_typetwo_prod_env.ps1` 可產出 production env，且 production env guard 通過。
- 已實測 `test_typetwo_release_artifacts.ps1 -Version v1.0.18`，GitHub Release assets 下載與 checksum 驗證通過。

## 後續部署時驗證

以下項目需要真實主機或 production 資料來源；依目前決策暫不納入本階段完成條件。

| 項目 | 需要的外部資源 | 驗收方式 |
| --- | --- | --- |
| 正式 HTTPS domain | DNS、TLS 憑證與可從公司外連線的主機 | `Invoke-RestMethod https://<domain>/health` 回傳 `ok=true`、`db=ok`、`environment=production` |
| staging smoke | staging domain 與 staging DB | 對 staging URL 執行 `.\scripts\smoke_typetwo_glossary_api.ps1 -BaseUrl https://<staging-domain>` |
| production smoke | production domain 與 production 帳號策略 | 對 production URL 執行 smoke，確認 cleanup 後沒有測試詞彙與可登入測試帳號 |
| staging/production evidence | 真實 URL 與 admin secrets | 執行 `test_typetwo_deployment_gate.ps1` 或 GitHub Actions `Deployment Gate` |
| GitHub Actions 綠燈 | 已在 PR 與 `master` 驗證通過 | `CI / backend-quality` 與 `CI / windows-quality` 皆通過 |
| Release artifact 可下載 | 已在 GitHub Release `v1.0.18` 驗證通過 | Release 內有 `setup_typetwo.exe`、`setup_typetwo.exe.sha256`、`typetwo-glossary-api-v1.0.18.tar`、`typetwo-glossary-api-v1.0.18.tar.sha256` |
| production 備份還原演練 | production DB 備份檔與非 production 還原環境 | 用 `.\scripts\verify_typetwo_postgres_backup.ps1 -BackupZip <production-backup.zip>` 驗證成功 |
| production env 產生 | 已有腳本，本機可驗證；正式值需保存到部署主機與密碼管理器 | `.\scripts\new_typetwo_prod_env.ps1 -GlossaryDomain <domain> -AcmeEmail <email> -AdminEmail <email>` |

## 宣告全部完成的條件

以下條件已滿足，M0-M5 本階段可判定完成：

1. M0-M5 功能、文件、腳本與測試完成。
2. 本機 Docker production-like smoke、備份、還原驗證與 deployment gate 通過。
3. default branch GitHub Actions `backend-quality` 與 `windows-quality` 綠燈。
4. GitHub Release `v1.0.18` 已產出 installer、backend image tar 與各自 checksum，並已驗證 checksum。
5. 部署手冊、release checklist、rollback runbook、completion audit、production env 產生工具與 deployment gate 已完成。

## 後續部署需要的外部設定

repo 目前沒有部署 secrets、environment variables、遠端主機或 DNS 設定；這些已不阻塞本階段完成。若未來要讓 GitHub Actions `Deployment Gate` 直接完成 staging/production evidence，需先在 GitHub environment `staging` 與 `production` 設定：

- `TYPETWO_ADMIN_EMAIL`
- `TYPETWO_ADMIN_PASSWORD`

並準備可從 GitHub runner 連線的 HTTPS URL，例如 `https://typetwo-glossary.company.com`。
