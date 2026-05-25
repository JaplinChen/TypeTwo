## 2026-05-25｜TypeTwo 模組化重構順序

狀態：採用
情境：TypeTwo 同時包含 Flutter app、FastAPI glossary backend、legacy Python bridge，直接大拆 `AppConfig` 或後端 router 風險較高。
決策：先從 Flutter 詞彙同步 state/mutation 抽出 service，再拆 `GlossaryRemoteService`，之後才拆 FastAPI glossary router 與 `AppConfig` 子設定。
理由：
- `ConfigProvider` 的 glossary pending queue 行為已有現成 Flutter 測試，可快速驗證行為不變。
- `AppConfig` 是設定檔相容核心，直接拆分容易造成 JSON schema migration 風險。
- 後端 router 拆分牽涉 API contract 與 SQLAlchemy transaction 邊界，應在前端同步邏輯穩定後處理。
替代方案：
- 一次性重構所有大檔：未採用，因為會同時改動設定、同步、API 與測試，回歸定位困難。
驗證：
- 每個階段至少跑 `flutter analyze`、相關 `flutter test`；後端階段跑 `python -m pytest backend\tests`。

## 2026-05-25｜後端 router 拆分先保留 transaction 邊界

狀態：採用
情境：`backend/app/routers/glossary.py` 同時負責 presenter、history、duplicate lookup、endpoint 與 transaction，已是結構熱點。
決策：第三階段只把 presenter/query/helper 抽到 `backend/app/services/glossary_service.py`，暫時不移動 create/update/import 的 commit/refresh 流程。
理由：
- 這一步能明確降低 router 行數與職責，且不改 HTTP contract。
- transaction 邊界若同時移動，失敗時較難判斷是 API 行為、SQLAlchemy session 還是 presenter 回歸。
- 現有 `backend\tests` 是 API-level 測試，尚不足以支撐 repository 層大幅移動。
替代方案：
- 直接拆成 repository/service/router 三層：未採用，因為目前缺 service/repository focused tests。
驗證：
- `python -m pytest backend\tests`
- `python -m pytest src\tests backend\tests`

## 2026-05-25｜Provider runtime 子設定保持唯讀相容層

狀態：採用
情境：`AppConfig` provider 相關欄位散落在 model、provider service、translation service 與 UI；直接改成巢狀 JSON 會影響既有 `translator_config.json`。
決策：先新增 `ProviderRuntimeConfig` 與 `AppConfig.providerRuntime` getter，只遷移讀取邏輯與純規則，不改 JSON schema 或 UI 寫入方式。
理由：
- `temperature` clamp 與主模型加 fallback model 去重是 runtime 規則，適合先集中到子設定。
- 唯讀 getter 可降低服務層對扁平欄位的依賴，同時不需要 migration。
- 後續若要完整 provider adapter 或設定檔 schema migration，能先以這個 getter 作為過渡邊界。
替代方案：
- 直接把 JSON 改為巢狀 `providerRuntime` 或 `providers`：未採用，因為會擴大設定相容與 UI 寫入回歸範圍。
驗證：
- `flutter test test\models\app_config_and_template_test.dart`
- `flutter test test\services\provider_service_test.dart test\services\ai_provider_helpers_test.dart`
- `flutter analyze`
- `flutter test`
- `python -m pytest src\tests backend\tests`

## 2026-05-25｜拆 remote service 後補 client focused tests

狀態：採用
情境：Flutter 遠端詞彙同步已拆成 service、client、models，若只靠 service integration tests，transport 回歸定位仍不夠直接。
決策：新增 `glossary_remote_client_test.dart`，先補 client 層契約測試，再考慮繼續拆 API method adapter。
理由：
- header、base URL、JSON encode/decode、204 response、錯誤 status 都是 transport 層責任。
- `MockClient` 測試速度快，不需要開 socket，也比整合測試更容易定位。
- 不改 production API，只補重構安全網。
替代方案：
- 只保留 `GlossaryRemoteService 支援登入與詞彙 CRUD` 整合測試：未採用，因為它無法單獨保證 client 層錯誤處理。
驗證：
- `flutter test test\services\glossary_remote_client_test.dart`
- `flutter analyze`
- `flutter test`

## 2026-05-25｜AI provider adapter 統一先抽最小共用 helper

狀態：採用
情境：TypeTwo 的 provider model list/check 與 translation call 都有 OpenAI-compatible API 行為，但完整 adapter 統一會碰到 endpoint、model list、chat completion 與錯誤處理。
決策：先抽 `AiProviderHelpers.openAICompatibleHeaders` 並補 focused tests，不一次重組所有 provider adapter。
理由：
- header 組裝是明確重複且低風險。
- OpenAI-compatible endpoint/model URI 邏輯仍有 provider-specific 規則，應等測試更完整再移動。
- 這一步能降低重複，又保留現有 service 邊界。
替代方案：
- 直接建立完整 `AiProviderClient` 介面：未採用，因為會同時改 model list、check connection、translate 三條流程。
驗證：
- `flutter test test\services\ai_provider_helpers_test.dart test\services\provider_service_test.dart test\models\app_config_and_template_test.dart`
- `flutter analyze`
- `flutter test`

## 2026-05-25｜OpenAI-compatible models URI 推導集中到 helper

狀態：採用
情境：`ProviderService` 內部 `_ProviderAdapter` 仍持有 OpenAI/Groq models URI 推導，這和後續完整 provider adapter 統一相關。
決策：將 URI 推導抽到 `AiProviderHelpers.openAICompatibleModelsUri`，`_ProviderAdapter` 只決定 provider default URL。
理由：
- URI 推導規則可獨立測試，包含 chat completions path、custom path、query 清除。
- 這比一次搬動 `fetchModels/checkConnection/translate` 更小，回歸容易定位。
- 保留 `_ProviderAdapter` 可避免 provider-specific switch 在這一步擴散。
替代方案：
- 直接建立完整 provider adapter interface：仍未採用，因為現階段先處理明確共用規則即可。
驗證：
- `flutter test test\services\ai_provider_helpers_test.dart test\services\provider_service_test.dart`
- `flutter analyze`
- `flutter test`

## 2026-05-25｜AppConfig 拆分先建立子設定讀取邊界

狀態：採用
情境：`AppConfig` 是使用者設定檔相容核心，直接拆 JSON schema 風險高。
決策：先新增 `GlossarySyncConfig` 與 `AppConfig.glossarySync` getter，讓 service 逐步依賴子設定；暫不改 serialized shape。
理由：
- 可降低 `AppConfig` 呼叫端對扁平欄位的散落依賴。
- 不影響既有 `translator_config.json`。
- 後續若要真正 migration，可先觀察哪些模組已只依賴子設定。
替代方案：
- 直接將 JSON 改為巢狀 `glossarySync`：未採用，因為需要 migration 與更廣泛回歸測試。
驗證：
- `flutter test test\models\app_config_and_template_test.dart test\services\glossary_sync_service_test.dart`
- `flutter analyze`
- `flutter test`

## 2026-05-25｜AppConfig 子設定遷移先讀後寫

狀態：採用
情境：呼叫端已可透過 `config.glossarySync` 讀同步設定，但寫入仍需要維持既有 JSON schema。
決策：先把 service/provider/UI 的讀取改成 `GlossarySyncConfig`，寫入暫時保留 `copyWith(glossarySyncUrl: ...)` 等扁平欄位。
理由：
- 讀取遷移不影響設定檔相容性。
- 寫入遷移會牽涉 `copyWith` API 與 JSON migration，應另成一步。
- UI 角色判斷集中到 `canReview/canManageUsers` 後，後續權限規則更容易調整。
替代方案：
- 同時改 getter、copyWith 與 JSON shape：未採用，因為回歸範圍過大。
驗證：
- `flutter test test\services\glossary_sync_service_test.dart test\screens\glossary_tab_test.dart test\models\app_config_and_template_test.dart`
- `flutter analyze`
- `flutter test`

## 2026-05-25｜後端 glossary 寫入流程先抽 service、不另建 repository

狀態：採用
情境：helper 抽離後，router 仍持有 create/update/import 的實際寫入流程；但目前沒有 repository focused tests。
決策：先把寫入 use case 收斂到 `backend/app/services/glossary_service.py`，暫不新增 repository 層。
理由：
- 這能讓 router 更接近 HTTP layer，同時不增加過多抽象。
- 現有 SQLAlchemy 查詢仍簡單，repository 層目前主要只是搬家，不會立刻降低複雜度。
- API-level 測試可直接驗證這次搬移是否維持 contract。
替代方案：
- 立即新增 `repositories/glossary_repository.py`：未採用，因為缺少直接測 repository 的價值與測試基礎。
驗證：
- `python -m py_compile backend\app\routers\glossary.py backend\app\services\glossary_service.py`
- `python -m pytest src\tests backend\tests`

## 2026-05-25｜拆 repository 前先補 service focused tests

狀態：採用
情境：glossary 寫入流程已搬到 service，但下一步若直接引入 repository，API-level tests 對內部 transaction 與 history 細節的定位不夠直接。
決策：先新增 `backend/tests/test_glossary_service.py`，再考慮 repository 層。
理由：
- focused tests 能直接覆蓋 pending、duplicate、history、import upsert、soft delete。
- 後續移動 SQLAlchemy 查詢時，失敗會比 API-level tests 更容易定位。
- 不新增 production 抽象，只提高重構安全網。
替代方案：
- 直接開始 repository 拆分：未採用，因為缺少內部行為測試會提高回歸定位成本。
驗證：
- `python -m pytest backend\tests`
- `python -m pytest src\tests backend\tests`

## 2026-05-25｜Provider adapter 先遷移讀取來源，不重建 adapter

狀態：採用
情境：`translate_service_providers.dart` 的 provider method 已能透過 `ProviderRuntimeConfig` 取得 runtime 欄位，但完整 adapter interface 仍會牽涉 model list、check connection、translate 與錯誤處理。
決策：本階段只把 provider method 的 endpoint/model/apiKey/thinkingMode 讀取改走 `cfg.providerRuntime`，並把 Gemini thinking budget 規則集中到 runtime 子設定。
理由：
- 讀取來源遷移能降低扁平欄位耦合，且不改 API payload contract。
- Azure OpenAI request body 不含 `model` 是重要既有行為，這一步保留並用測試覆蓋。
- 完整 adapter interface 需要更大測試矩陣，應另成後續階段。
替代方案：
- 直接建立 `ProviderAdapter` 抽象並重寫所有 provider call：未採用，因為會同時改多條 HTTP 行為，回歸定位成本高。
驗證：
- `flutter test test\models\app_config_and_template_test.dart`
- `flutter test test\services\azure_openai_and_bridge_test.dart test\services\provider_service_test.dart test\services\ai_provider_helpers_test.dart`
- `flutter analyze`
- `flutter test`
- `python -m pytest src\tests backend\tests`

## 2026-05-25｜EngineTab 只遷移讀取與草稿組裝

狀態：採用
情境：設定頁同時承擔 provider 切換、草稿表單、連線測試與模型列表拉取；直接改寫 provider 設定儲存 API 會牽動 UI 與 JSON schema。
決策：只把 `EngineTab` 的 runtime 欄位讀取改成 `config.providerRuntime`，並抽出 `_providerConfigsWithCurrentDraft`；寫入仍使用既有扁平 `copyWith` 欄位。
理由：
- 讀取遷移能延續 `ProviderRuntimeConfig` 邊界，減少 UI 對扁平欄位的散落依賴。
- 草稿組裝集中後，切換 provider 與儲存目前 provider 的行為較不容易漂移。
- 不改寫入 API，可避免設定檔 migration 與 UI 行為同時變更。
替代方案：
- 同步新增巢狀 provider 設定寫入 API：未採用，因為需要更完整的 UI 測試覆蓋 provider 切換流程。
驗證：
- `flutter test test\models\app_config_and_template_test.dart`
- `flutter test test\screens\glossary_tab_test.dart`
- `flutter test test\services\provider_service_test.dart test\services\azure_openai_and_bridge_test.dart`
- `flutter analyze`
- `flutter test`
- `python -m pytest src\tests backend\tests`

## 2026-05-25｜EngineTab provider 切換先補行為測試

狀態：採用
情境：`EngineTab` 的 provider 切換是狀態ful UI 行為，`AppConfig` 與 service tests 無法直接覆蓋表單草稿保存。
決策：新增 widget test 覆蓋 OpenAI 表單草稿切換到 Gemini 時的保存與載入行為。
理由：
- 這是 `_providerConfigsWithCurrentDraft` 的主要行為風險點。
- 測試先鎖定 provider 切換 contract，後續若要新增巢狀 provider 設定寫入 API，有直接回歸保護。
- 設定 test surface size 可避免 `ListView` lazy build 導致 API Key 欄位不存在的假失敗。
替代方案：
- 只靠手動測試設定頁：未採用，因為 provider 切換草稿保存容易在重構時回歸。
驗證：
- `flutter test test\screens\engine_tab_test.dart`
- `flutter test test\screens\engine_tab_test.dart test\screens\glossary_tab_test.dart test\models\app_config_and_template_test.dart`
- `flutter analyze`
- `flutter test`
- `python -m pytest src\tests backend\tests`

## 2026-05-25｜ConfigService 拆檔先補 contract test

狀態：採用
情境：`ConfigService.save` 將 `glossary` 從主設定拆到 `glossary.json`，這個行為和使用者詞彙資料保存直接相關。
決策：先新增 focused test 驗證主設定檔不含 `glossary`，且 `glossary.json` 寫入完整詞彙；暫不改 production code。
理由：
- 現有損壞設定檔測試只保護 corrupt backup，沒有保護正常 save 的拆檔格式。
- 拆檔 contract 一旦回歸，可能造成詞彙混進主設定或漏寫 glossary file。
- 先補測試比重構 `ConfigService` 更直接，能建立後續拆 storage helper 的安全網。
替代方案：
- 立即把 config/glossary storage 拆成兩個 repository：未採用，因為目前缺的首先是 contract coverage。
驗證：
- `flutter test test\services\config_service_test.dart`
- `flutter analyze`
- `flutter test`
- `python -m pytest src\tests backend\tests`
