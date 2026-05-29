# TypeTwo 發版檢查清單

本清單的「Staging」與「Production」段落是實際部署 gate；若尚未配置真實主機、DNS、HTTPS 與 production DB，這些項目不阻塞 M0-M5 repo 產品化完成。

## 版本資訊

- Release version：
- Git SHA：
- Windows installer artifact：
- Windows installer SHA256：
- Backend image artifact：
- Backend image SHA256：
- Migration revision：

## 合併前

- `flutter analyze`
- `flutter test`
- `py -3.12 -m pytest backend\tests`
- `py -3.12 -m pytest src\tests`
- `.\scripts\check_backend_migrations.ps1 -Python py -PythonArgs -3.12`
- `.\scripts\backup_typetwo_postgres.ps1 -OutputDir .\backups-test -KeepDays 1`
- `.\scripts\verify_typetwo_postgres_backup.ps1 -BackupZip <backup.zip>`
- `git diff --check`

## CI gate

- GitHub Actions `CI / backend-quality` 通過：
  - backend pytest
  - Alembic migration gate
  - backend Docker image build
  - TypeTwo Server smoke
- GitHub Actions `CI / windows-quality` 通過：
  - Flutter analyze
  - Flutter test
  - legacy Python unit tests
  - clipboard hotkey regression

## Release artifact

- `setup_typetwo.exe` 已由 release workflow 產出並附加到 GitHub Release。
- `setup_typetwo.exe.sha256` 已由 release workflow 產出並附加到 GitHub Release。
- `typetwo-glossary-api-<version>.tar` 已由 release workflow 產出並附加到 GitHub Release。
- `typetwo-glossary-api-<version>.tar.sha256` 已由 release workflow 產出並附加到 GitHub Release。
- `.\scripts\test_typetwo_release_artifacts.ps1 -Version <version>` 通過。
- backend image tag 至少包含：
  - `typetwo-glossary-api:<git-sha>`
  - `typetwo-glossary-api:<version>`
- production 不使用 `latest` tag。
- 下載 artifact 後的 SHA256 與 release 內附 checksum 一致。

## Staging

- staging DB 已備份或可重建。
- staging 備份已用 `verify_typetwo_postgres_backup.ps1` 還原到臨時 volume 驗證。
- Alembic migration 已在 staging 成功升級到 head。
- staging smoke 通過。
- `test_typetwo_deployment_gate.ps1` 或 GitHub Actions `Deployment Gate` 已產出 staging evidence JSON。
- Flutter App 可連 staging TypeTwo Server 並完成登入、同步、pending review、匯入預覽。

## Production

- production DB 已完成備份並記錄備份位置。
- production 備份已在非 production volume 驗證可還原。
- `check_typetwo_prod_env.ps1` 通過。
- 若需產生新 env，`new_typetwo_prod_env.ps1` 產出的 `.env.production` 已保存到部署主機並限制權限。
- Alembic migration 已執行。
- service 已啟動，`/health` 為 `ok=true`、`db=ok`、`environment=production`。
- production smoke 通過且 cleanup 驗證通過。
- `test_typetwo_deployment_gate.ps1` 或 GitHub Actions `Deployment Gate` 已產出 production evidence JSON。
- rollback owner 與 rollback artifact 已確認。

## Release notes

- 列出使用者可見變更。
- 列出 migration 與資料風險。
- 列出已知限制。
- 列出 rollback 步驟摘要。
