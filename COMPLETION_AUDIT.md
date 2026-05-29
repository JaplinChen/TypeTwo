# TypeTwo 產品化完成度審核

日期：2026-05-29

本文用來區分「本機已完成並驗證」與「需要 staging / production 外部環境才能宣告完成」的項目。避免把尚未部署到正式網域的能力誤判為已完成。

## 結論

M0、M2、M3、M4 與 M5 的程式、文件、測試與本機 production-like 驗證已完成到可交付審查狀態。M1 與 M5 的正式完成仍需要外部環境證據：正式 HTTPS domain、staging/production smoke、GitHub Actions 實際綠燈、production 備份還原演練。

## 本機已完成證據

| 階段 | 狀態 | 證據 |
| --- | --- | --- |
| M0 產品化基線 | 本機完成 | production guard、`.env.example.production`、`DEPLOYMENT.md`、`RELEASE_CHECKLIST.md`、production env check 與 Docker smoke 已驗證 |
| M1 公司內部 Beta 可部署 | 本機部署流程完成 | production compose、migration flow、備份與臨時 volume 還原驗證腳本已完成；實際外部 HTTPS domain 尚待部署 |
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

## 外部環境待驗證

| 項目 | 為什麼不能本機宣告完成 | 驗收方式 |
| --- | --- | --- |
| 正式 HTTPS domain | 需要真實 DNS、TLS 憑證與可從公司外連線的主機 | `Invoke-RestMethod https://<domain>/health` 回傳 `ok=true`、`db=ok`、`environment=production` |
| staging smoke | 需要 staging domain 與 staging DB | 對 staging URL 執行 `.\scripts\smoke_typetwo_glossary_api.ps1 -BaseUrl https://<staging-domain>` |
| production smoke | 需要 production domain 與 production 帳號策略 | 對 production URL 執行 smoke，確認 cleanup 後沒有測試詞彙與可登入測試帳號 |
| GitHub Actions 綠燈 | 已在 PR #44 驗證通過；merge 後仍需確認 default branch 綠燈 | `CI / backend-quality` 與 `CI / windows-quality` 皆通過 |
| workflow artifact 可下載 | 已在 workflow_dispatch run `26616184411` 驗證通過；正式 GitHub Release attach 仍需 release event | Release 內有 `setup_typetwo.exe`、`setup_typetwo.exe.sha256`、`typetwo-glossary-api-<version>.tar`、`typetwo-glossary-api-<version>.tar.sha256` |
| production 備份還原演練 | 需要 production DB 備份檔與非 production 還原環境 | 用 `.\scripts\verify_typetwo_postgres_backup.ps1 -BackupZip <production-backup.zip>` 驗證成功 |

## 宣告全部完成的條件

全部條件都滿足後，才能把 `plan-20260526.md` 的 M0-M5 狀態改為「全部完成」：

1. 正式 domain `/health` 從外部網路可連。
2. staging smoke 通過。
3. production smoke 通過，且 cleanup 驗證通過。
4. merge 後 default branch GitHub Actions `backend-quality` 與 `windows-quality` 綠燈。
5. GitHub Release event 產出 installer、backend image tar 與各自 checksum，並附加到 GitHub Release。
6. production 備份已還原到非 production volume 驗證。
7. rollback runbook 至少演練一次並記錄結果。
