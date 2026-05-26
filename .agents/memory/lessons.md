## 2026-05-25｜TypeTwo 全 repo 標準化審查基準

情境：審查或重構 TypeTwo 的 Flutter 主程式、FastAPI 詞彙同步後端與 legacy Python bridge 時。
內容：
- 審查範圍應排除 `src/.venv`、`build`、`package`、`oz-skills`、Flutter `windows/flutter/ephemeral`。
- 目前主要結構債集中在 `typetwo_flutter/lib/providers/config_provider.dart`、`typetwo_flutter/lib/services/glossary_remote_service.dart`、`typetwo_flutter/lib/models/app_config.dart`、`backend/app/routers/glossary.py`。
- 優先重構 Flutter 詞彙同步 mutation/pending queue，因為已有 `glossary_sync_service_test.dart` 覆蓋離線佇列與遠端 CRUD 行為，最適合先做實操驗證。
驗證：基準命令為 `flutter analyze`、`flutter test`、`python -m pytest src\tests backend\tests`。

## 2026-05-25｜TypeTwo 後端 glossary router 漸進拆分

情境：拆分 `backend/app/routers/glossary.py` 時，避免一次移動 endpoint、transaction 與 SQLAlchemy 查詢造成回歸難定位。
內容：
- 第一小步只抽 `active_terms_query`、`bundle_from_terms`、`term_out`、`history_out`、`record_history`、`find_existing`、`validate_status_filter` 到 `backend/app/services/glossary_service.py`。
- router 先保留 endpoint、HTTP status、commit/refresh 與權限 dependency，確保 API contract 不變。
- 後續若繼續拆 repository，應先補 service/repository 單元測試，再移動 create/update/import transaction 流程。
驗證：已跑 `python -m pytest backend\tests`、`python -m pytest src\tests backend\tests`、`flutter analyze`、`flutter test`。

## 2026-05-25｜TypeTwo glossary 寫入流程收斂到 service

情境：`backend/app/routers/glossary.py` 的 create/update/approve/reject/delete/import 流程包含 duplicate lookup、history、version、commit/refresh，router 職責仍偏重。
內容：
- 將 `create_term_record`、`update_term_record`、`set_term_status`、`soft_delete_term`、`import_glossary_records` 放到 `backend/app/services/glossary_service.py`。
- router 保留 FastAPI endpoint、dependency、query list/export orchestration 與 response mapping。
- 寫入流程搬移後必須跑 backend API 測試，因為現有保障仍主要是 HTTP-level contract。
驗證：已跑 `python -m py_compile backend\app\routers\glossary.py backend\app\services\glossary_service.py`、`python -m pytest src\tests backend\tests`、`flutter analyze`、`flutter test`。

## 2026-05-25｜TypeTwo glossary service focused tests

情境：`glossary_service.py` 已承接寫入 use case，後續若再拆 repository 或 transaction 邊界，需要比 API tests 更直接的保護。
內容：
- 新增 `backend/tests/test_glossary_service.py` 直接測 `create_term_record`、`update_term_record`、`import_glossary_records`、`soft_delete_term`。
- 測試涵蓋一般 user 建議詞強制 pending、active duplicate 409、history operation 順序、import upsert 與 soft delete。
- 測試使用 `Base.metadata.drop_all/create_all` reset in-memory DB，避免和 API-level tests 的資料互相污染。
驗證：已跑 `python -m pytest backend\tests`、`python -m pytest src\tests backend\tests`，Python 測試總數從 90 增加到 95。

## 2026-05-25｜TypeTwo Flutter remote client focused tests

情境：`GlossaryRemoteService` 已拆出 DTO 與 `GlossaryRemoteClient`，後續若繼續拆 API adapter，需要直接覆蓋 transport 行為。
內容：
- 新增 `typetwo_flutter/test/services/glossary_remote_client_test.dart`，直接測 `headersFor`、`normalizeBaseUrl`、JSON body、204 empty response、非預期 status、非 Map 回應。
- 使用 `package:http/testing.dart` 的 `MockClient`，不需要啟動本機 `HttpServer`。
- `GlossaryRemoteService` 測試保留端到端 API method 行為；client tests 專注 transport contract。
驗證：已跑 `flutter test test\services\glossary_remote_client_test.dart`、`flutter analyze`、`flutter test`，Flutter 測試總數從 33 增加到 39。

## 2026-05-25｜TypeTwo AI provider 共用 helper

情境：Provider model list/check 與 TranslateService 各自實作 OpenAI-compatible header 組裝，後續統一 provider adapter 前先消除最小重複。
內容：
- 新增 `typetwo_flutter/lib/services/ai_provider_helpers.dart`，提供 `AiProviderHelpers.openAICompatibleHeaders`。
- `ProviderService` 與 `TranslateService` 的 OpenAI/Groq path 改用同一 helper。
- 新增 `typetwo_flutter/test/services/ai_provider_helpers_test.dart`，直接測 content type、trim token 與 bearer header。
驗證：已跑 `flutter test test\services\ai_provider_helpers_test.dart test\services\provider_service_test.dart test\models\app_config_and_template_test.dart`、`flutter analyze`、`flutter test`，Flutter 測試總數增加到 41。

## 2026-05-25｜Dart Uri.replace 清 query 的陷阱

情境：將 OpenAI-compatible `/models` URI 推導抽到 `AiProviderHelpers.openAICompatibleModelsUri` 時，需要保留原有「同源但清除 query」行為。
內容：
- `uri.replace(path: path, query: null)` 會保留原 query，不會清除。
- `uri.replace(path: path, query: '')` 會產生尾端 `?`。
- 用 `Uri(...)` 重建同源 URI 時，無 port 的 URL 不要傳 `port: 0`，否則會序列化為 `:0`。
- 目前 helper 用 `_replacePathWithoutQuery` 依 `uri.hasPort` 分支建立 URI。
驗證：`ai_provider_helpers_test.dart` 覆蓋帶 query 的 chat completions endpoint 與非 chat path endpoint。

## 2026-05-25｜AppConfig 子設定先用 getter，不改 JSON schema

情境：`AppConfig` 欄位過多，但直接拆成多個巢狀 JSON 物件會影響使用者既有設定檔。
內容：
- 新增 `GlossarySyncConfig` 與 `AppConfig.glossarySync` getter，先提供讀取邊界。
- `toJson/fromJson/copyWith` 保持原本扁平欄位，不輸出新的 `glossarySync` key。
- 先讓 `GlossarySyncService` 與 `GlossaryMutationService` 使用 `config.glossarySync`，UI 仍可暫時讀原欄位。
- 測試需明確檢查 `json.containsKey('glossarySync') == false`，避免不小心破壞設定相容。
驗證：已跑 `flutter test test\models\app_config_and_template_test.dart test\services\glossary_sync_service_test.dart`、`flutter analyze`、`flutter test`。

## 2026-05-25｜AppConfig 子設定呼叫端遷移順序

情境：`GlossarySyncConfig` getter 已建立後，需要逐步減少呼叫端直接讀 `glossarySync*` 扁平欄位。
內容：
- 先改 service 層：`GlossarySyncService`、`GlossaryMutationService`。
- 再改 provider/UI 讀取：`ConfigProvider` remote API 呼叫、pending queue append、`GlossaryTab` sync panel 顯示。
- 寫入仍用 `copyWith(glossarySyncUrl: ...)` 等扁平欄位，直到正式做 JSON schema migration。
- UI 使用 `sync.canReview`、`sync.canManageUsers`，避免角色判斷散落。
驗證：已跑 `flutter test test\services\glossary_sync_service_test.dart test\screens\glossary_tab_test.dart test\models\app_config_and_template_test.dart`、`flutter analyze`、`flutter test`。

## 2026-05-25｜AppConfig provider runtime 先抽唯讀邊界

情境：`AppConfig` 的 provider/model/endpoint/apiKey/temperature/thinkingMode 欄位仍是扁平設定，但 `TranslateService` 已開始累積模型嘗試與溫度正規化規則。
內容：
- 新增 `ProviderRuntimeConfig` 與 `AppConfig.providerRuntime` getter，先集中 provider runtime 讀取，不改 `toJson/fromJson/copyWith` 的 serialized shape。
- 將 `clampedTemperature` 與 `modelAttempts` 放在子設定中，讓 `TranslateService` 不再自行拼 fallback model 去重邏輯。
- 測試需明確檢查 `json.containsKey('providerRuntime') == false`，確保不意外改動使用者既有設定檔。
驗證：已跑 `flutter test test\models\app_config_and_template_test.dart`、`flutter test test\services\provider_service_test.dart test\services\ai_provider_helpers_test.dart`、`flutter analyze`、`flutter test`、`python -m pytest src\tests backend\tests`。

## 2026-05-25｜Provider adapter 讀取改走 runtime 子設定

情境：`ProviderRuntimeConfig` 已建立後，`translate_service_providers.dart` 仍直接讀取 `cfg.endpoint/model/apiKey/thinkingMode`，讓 provider 呼叫細節與設定來源耦合。
內容：
- Ollama、OpenAI-compatible、Azure OpenAI、Gemini provider 呼叫先建立 `final runtime = cfg.providerRuntime`，再讀 endpoint/model/apiKey。
- Gemini `thinkingMode` 到 `thinkingBudget` 的轉換移到 `ProviderRuntimeConfig.geminiThinkingBudget`。
- Azure OpenAI 仍維持 request body 不包含 `model` 的既有契約，避免破壞 deployment URL 模式。
驗證：已跑 `flutter test test\models\app_config_and_template_test.dart`、`flutter test test\services\azure_openai_and_bridge_test.dart test\services\provider_service_test.dart test\services\ai_provider_helpers_test.dart`、`flutter analyze`、`flutter test`、`python -m pytest src\tests backend\tests`。

## 2026-05-25｜EngineTab provider 設定讀取收斂

情境：`engine_tab.dart` 是 provider 設定 UI，仍直接讀取 `cfg.endpoint/model/apiKey/temperature/thinkingMode/providerOrder/fallbackModels/providerConfigs`，且 `_commit` 與 `_selectProvider` 重複組裝 provider draft。
內容：
- `initState`、連線測試、模型拉取改透過 `cfg.providerRuntime` 讀取 runtime 欄位。
- 新增 `_providerConfigsWithCurrentDraft`，集中目前表單草稿寫回 `providerConfigs` 的 Map 組裝。
- 寫入仍保留 `copyWith(endpoint/model/apiKey/...)` 扁平欄位，避免改動設定檔 serialized shape。
驗證：已跑 `flutter test test\models\app_config_and_template_test.dart`、`flutter test test\screens\glossary_tab_test.dart`、`flutter test test\services\provider_service_test.dart test\services\azure_openai_and_bridge_test.dart`、`flutter analyze`、`flutter test`、`python -m pytest src\tests backend\tests`。

## 2026-05-25｜EngineTab provider 切換補 widget test

情境：`EngineTab` 抽出 `_providerConfigsWithCurrentDraft` 後，需要直接保護「切換 provider 前保存目前表單草稿」的 UI 行為。
內容：
- 新增 `typetwo_flutter/test/screens/engine_tab_test.dart`，測 OpenAI 表單草稿切到 Gemini 時，OpenAI 草稿會進入 `providerConfigs`，Gemini 會載入既有保存值。
- Flutter widget test 的預設 surface 是 800x600，`EngineTab` 的 API Key 欄位在 `ListView` 下方時不會 build；測試需用 `tester.binding.setSurfaceSize(const Size(900, 1200))` 並在 tearDown reset。
- 這個測試補上 UI 層 provider 切換流程，避免只靠 model/service tests 漏掉表單草稿行為。
驗證：已跑 `flutter test test\screens\engine_tab_test.dart`、`flutter test test\screens\engine_tab_test.dart test\screens\glossary_tab_test.dart test\models\app_config_and_template_test.dart`、`flutter analyze`、`flutter test`、`python -m pytest src\tests backend\tests`。

## 2026-05-25｜ConfigService glossary 拆檔 contract

情境：`ConfigService.save` 會把 `AppConfig.glossary` 從主設定檔拆到 `glossary.json`，這是使用者詞彙資料保全與設定檔相容的重要 contract。
內容：
- 新增 `config_service_test.dart` 測試，確認 `translator_config.json` 不包含 `glossary` key。
- 同一測試確認 `glossary.json` 保留詞彙內容，避免後續調整 `toJson` 或 save flow 時把詞彙漏寫。
- 損壞設定檔備份測試與拆檔測試共用 `ConfigService.debugConfigDir`，每個 test 都要清理暫存目錄與 reset debug dir。
驗證：已跑 `flutter test test\services\config_service_test.dart`、`flutter analyze`、`flutter test`、`python -m pytest src\tests backend\tests`。

## 2026-05-26｜Docker API smoke 必須驗證資料清理

情境：TypeTwo backend Docker image build 成功後，仍需要確認 container 實際跑起來、API workflow 可用，而且 smoke test 不污染 PostgreSQL。
內容：
- 只看 Docker Desktop Images 不代表 API 已啟動；落地驗證要看 `docker compose ps` 的 `typetwo-api-1` 與 `typetwo-db-1` 是否 `healthy`，並呼叫 `http://localhost:18000/health`。
- `scripts/smoke_typetwo_glossary_api.ps1` 應實測 admin login、approved 詞彙包、一般 user 建議 pending、admin approve，再預設刪除當次 smoke 詞彙並停用當次 smoke user。
- cleanup 失敗不可只印 warning 後成功結束；腳本應丟出錯誤，避免測試污染被誤判通過。
- 本機若曾跑舊版 smoke script，要用 API 查 approved 詞彙包的 `smoke-*` key 與 `/users` 的 `smoke-*@example.com`，刪除 smoke 詞彙並停用 smoke user 後再重跑驗證。
驗證：已跑 `docker compose up -d --build`、`.\scripts\smoke_typetwo_glossary_api.ps1`、API 二次查詢確認 approved smoke key 數量 0、active smoke user 數量 0、停用帳號登入被拒，GitHub Actions `windows-quality` run `26425623217` 成功。
