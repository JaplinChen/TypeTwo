# TypeTwo 回退手冊

## 觸發條件

遇到下列任一情況，先停止繼續擴大部署，並進入回退判斷：

- `/health` 顯示 `db` 非 `ok`。
- production smoke 失敗，且不是 smoke 測試資料 cleanup 的單次環境問題。
- Flutter App 無法登入或同步 TypeTwo Server。
- migration 後資料不完整、重複詞彙異常、history restore 失效。
- Caddy HTTPS 或網域入口異常。

## 快速止血

1. 保留現場資訊：

```powershell
docker compose ps
docker compose logs --tail=200 api
docker compose logs --tail=200 caddy
```

2. 暫停流量或公告暫停同步。
3. 不直接刪除 volume。
4. 先備份目前 DB 狀態，避免回退過程覆蓋可調查資料。

## App 回退

若只有 Windows App 問題：

1. 取上一版 `setup_typetwo.exe`。
2. 在測試機確認可啟動、可翻譯、可同步。
3. 通知使用者安裝上一版。
4. TypeTwo Server 不需要回退，除非 API contract 也破壞舊版 App。

## Backend image 回退

1. 確認上一版 backend image tag 或 artifact。
2. 載入上一版 image：

```powershell
docker load -i typetwo-glossary-api-<previous-version>.tar
```

3. 更新部署環境使用上一版 tag。
4. 重啟服務：

```powershell
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

5. 執行 production smoke。

## DB migration 回退

優先策略是還原部署前 DB 備份。只有 migration 已明確支援 downgrade 且 staging 驗證過，才使用 Alembic downgrade。

備份還原流程：

1. 停止 API 寫入流量。
2. 備份目前異常 DB。
3. 先用臨時 volume 驗證部署前備份可還原：

```powershell
.\scripts\verify_typetwo_postgres_backup.ps1 -BackupZip .\backups\typetwo_<timestamp>.sql.zip
```

4. 還原部署前備份：

```powershell
.\scripts\restore_typetwo_postgres.ps1 -BackupZip .\backups\typetwo_<timestamp>.sql.zip
```

5. 啟動上一版 backend image。
6. 執行 smoke，確認 cleanup 通過。

## 詞彙資料回復

若單筆詞彙誤改但服務本身正常，優先使用 history restore：

1. 以 `admin` 或 `editor` 登入 Flutter App。
2. 進入雲端同步頁。
3. 開啟 pending review 的「紀錄」。
4. 對目標 history snapshot 按「回復」。
5. 同步 App，確認 approved 詞彙包符合預期。

大量資料誤匯入時，先停止新增匯入，再依 DB 備份還原或批次修復腳本處理。

## 回復後確認

- `/health` 正常。
- production smoke 通過。
- Flutter App 可登入、同步、審核 pending。
- smoke cleanup 沒留下測試詞彙或 active smoke user。
- release notes 或 incident note 記錄原因與後續修正。
