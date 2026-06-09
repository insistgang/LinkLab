歷史記錄：2026-04-17 項目修復工作曾標記爲 P0+P1+P2 全部收口。當前對外口徑以 `DEMO_STATUS.md` 和 `docs/rc_acceptance_evidence.md` 爲準。

# TODO.md - 共感 LinkAble MVP 修復執行清單（2026.04）

> 依據：`AGENTS.md`
> 說明：本清單隻服務當前 MVP 主線 `F1 / F9 / F11 / F13 / F33 / F36`，不爲已砍掉或降級功能分配默認交付資源。
> 2026-05-01 文檔口徑補充：本文件是歷史執行清單，不是當前運行環境的複驗報告。本輪未運行 Flutter；Web / Chrome 是首選演示路徑，Windows 桌面需要 Visual Studio C++ toolchain。

## P0（立即必須完成）

### 1. 修復 Riverpod 全局 `ProviderScope` 缺失

- 具體要做什麼：
  - 在 `runApp` 根節點提供全局 `ProviderScope`
  - 校驗所有可達 `ConsumerWidget` / `ConsumerStatefulWidget` 頁面都運行在統一 Riverpod 容器內
  - 在入口代碼中補充清晰註釋，說明競賽版默認仍走 Demo 主線，但全局狀態容器不可缺失
- 涉及的主要文件：
  - `linklab/lib/main.dart`
  - `linklab/lib/app.dart`
  - 受影響可達 Riverpod 頁面：`linklab/lib/screens/community/interest_groups_screen.dart`、`linklab/lib/screens/call/real_call_screen.dart`、`linklab/lib/pages/call/real_call_page.dart`、`linklab/lib/widgets/call/call_controls.dart`
- 完成標準：
  - `runApp` 根節點爲 `ProviderScope`
  - 應用入口存在明確的 Demo-first 與 Riverpod 說明
  - 不新增新的 `ChangeNotifier` 業務狀態、裸流程 `setState` 狀態源或新的 service singleton

### 2. 全倉資源清單核對 + 補齊 / 統一回退資源

- 具體要做什麼：
  - 覈對 `pubspec.yaml` 的資源聲明與磁盤實際文件
  - 掃描所有 `Image.asset(...)`、資源路徑常量與頭像/插圖引用
  - 對缺失資源統一補齊或替換爲佔位圖、文本頭像、無圖回退
- 涉及的主要文件：
  - `linklab/pubspec.yaml`
  - `linklab/admin_dashboard/pubspec.yaml`
  - `linklab/assets/**`
  - `linklab/lib/widgets/accessible/accessible_image.dart`
  - 所有圖片資源引用點
- 完成標準：
  - 主鏈路不再因資源缺失報錯
  - `pubspec.yaml` 資源聲明與實際目錄一致
  - 競賽版演示不出現空白、斷圖或運行時資源異常
- 完成記錄（2026-04-17）：
  - 已全量掃描 `linklab/lib` 與 `linklab/admin_dashboard/lib` 中的 `Image.asset`、`AssetImage`、`precacheImage`、`SvgPicture.asset`、`rootBundle.load*` 等資源入口；主應用實際 Flutter assets 僅剩 `assets/demo_data/*.json` 和訓練場景頁的可選圖片入口，後臺未發現 Flutter asset bundle 依賴。
  - 已將主應用 `pubspec.yaml` 收口爲只聲明實際使用的 `assets/demo_data/`；`admin_dashboard/pubspec.yaml` 已補充說明：後臺僅使用 `web/` 靜態圖標，不通過 Flutter assets 打包。
  - 已新增 `linklab/lib/widgets/accessible/accessible_image.dart`，統一處理 asset / network 圖片加載失敗時的無障礙回退，提供 `Semantics`、可見佔位圖標與替代文本。
  - 已將訓練場景頁切換到 `AccessibleImage.asset(...)`，即使未來收到缺失的 asset 路徑，也會穩定回退到無障礙佔位態。
  - 已確認主應用缺失的頭像和訓練示意圖資源不再阻塞 Demo 主線：志願者頭像統一退回文字頭像，訓練圖統一走組件回退。

### 3. 清理社區 / 社羣模塊所有硬編碼 `current_user_id`

- 具體要做什麼：
  - 將社區、社羣、羣聊、新手村等模塊中的硬編碼 `current_user_id` 全部改爲讀取 `AppSessionService` 當前用戶
  - 不屬於 MVP 的頁面若仍掛在默認導航，應直接隱藏或移出主鏈路
- 涉及的主要文件：
  - `linklab/lib/services/app_session_service.dart`
  - `linklab/lib/screens/community/interest_groups_screen.dart`
  - `linklab/lib/screens/community/regional_community_screen.dart`
  - `linklab/lib/screens/community/group_chat_screen.dart`
  - `linklab/lib/screens/community/newbie_village_screen.dart`
  - `linklab/lib/screens/community/training_scenario_screen.dart`
  - `linklab/lib/screens/community/story_detail_screen.dart`
  - `linklab/lib/services/unified_call_service.dart`
  - `linklab/lib/services/unified_matching_service.dart`
- 完成標準：
  - 主鏈路代碼中不再出現硬編碼 `current_user_id`
  - 所有保留頁面都讀取統一會話上下文
  - Demo 模式下未登錄時有安全 fallback，不會因空用戶中斷頁面
- 完成記錄（2026-04-17）：
  - 已全量掃描 `linklab/lib/` 中的 `current_user_id`、`const userId = 'current_user_id'`、`hardcoded user id` 等硬編碼用戶 ID；當前倉內已無殘留硬編碼佔位用戶 ID。
  - 已將社區/社羣相關頁面、故事詳情頁，以及 Demo/Real 過渡層中的用戶 ID 讀取統一爲 `AppSessionService.instance.currentUser?.id ?? 'demo-user-id'`。
  - 已在 `AppSessionService` 中補充顯式 `currentUser` getter，頁面層不再依賴硬編碼字符串，也不需要直接讀取 Supabase Auth 才能獲得當前演示用戶。
  - 已確認默認底部導航仍不包含社區入口；社區模塊代碼保留但不搶佔 MVP 默認導航，符合當前競賽範圍控制要求。

### 4. 統一 Supabase schema 的唯一事實來源

- 具體要做什麼：
  - 明確根目錄 `supabase/` 是唯一 schema source of truth
  - 停止 `linklab/supabase/` 繼續作爲並行 schema 入口
  - 識別並清理雙套 migration / function / config 的衝突引用
- 涉及的主要文件：
  - `supabase/`
  - `linklab/supabase/`
  - 相關引用配置與說明文檔
- 完成標準：
  - 後續 schema 變更只允許落在根 `supabase/`
  - `linklab/supabase/` 被歸檔、停用或顯式標識爲歷史目錄
  - 不再存在兩套並行數據庫事實來源
- 完成記錄（2026-04-17，當前執行輪次 / 用戶指定 P1-第1項）：
  - 已新增根遷移 `supabase/migrations/005_unify_root_schema_source_of_truth.sql`，將 `help_requests` 狀態機收口到 `AGENTS.md §5.2`，並補齊 `virtual_identities` 核心表。
  - 已在根 schema 爲當前保留的實驗性真實鏈路補齊最小基礎設施表：`user_devices`、`push_logs`、`ai_call_logs`、`emergency_notifications`、`notifications`；不再依賴 `linklab/supabase/` 歷史分叉。
  - 已將 `linklab/supabase/` 下原 `functions/`、`migrations/` 全部移動到 `linklab/supabase/legacy/`，並在原目錄留下只讀 `README.md`，明確根 `supabase/` 是唯一事實來源。
  - 已重寫根 `supabase/functions/matching-engine/index.ts`，只使用根 schema 的 `help_requests` / `volunteer_profiles` / `async_tasks` / `find_matching_volunteers(...)`。
  - 已重寫根 `supabase/functions/push-notifier/index.ts`，改爲讀取根 schema 中的 `user_devices` / `push_logs`，無 FCM key 時自動返回 mock success，避免真實推送阻塞競賽版。

### 5. 修復數據庫 schema 與 Edge Function / 客戶端代碼不一致

- 具體要做什麼：
  - 對齊 `users`、`volunteer_profiles`、`help_requests`、`emergency_contacts`、`virtual_identities` 等 MVP 核心表字段
  - 對齊 Edge Functions、客戶端 service 與 migration 中的字段名、狀態枚舉和主流程數據流
  - 真實路徑未對齊前，一律回退爲 Demo fallback，不得阻塞競賽主線
- 涉及的主要文件：
  - `supabase/migrations/*.sql`
  - `supabase/functions/**`
  - `linklab/lib/services/**/*real*`
  - `linklab/lib/services/realtime_sync_service.dart`
  - `linklab/lib/services/sos_service.dart`
- 完成標準：
  - 客戶端字段訪問與根 `supabase/` migration 一致
  - `help_requests.status` 與 `AGENTS.md` §5.2 狀態機一致
  - 競賽版主流程不再依賴字段不一致的真實後端鏈路

### 6. 補齊或移除代碼中引用但 migration 未創建的關鍵表

- 具體要做什麼：
  - 清點代碼中引用但根 `supabase/` 未定義的表
  - 對主鏈路必須存在的表補 migration
  - 對非 MVP 或不穩定表引用統一切回 Demo 本地數據或從主鏈路移除
- 涉及的主要文件：
  - `supabase/migrations/*.sql`
  - `linklab/lib/services/sos_service.dart`
  - `linklab/lib/services/community/featured_story_service.dart`
  - `supabase/functions/**`
- 完成標準：
  - 主鏈路不再訪問不存在的數據庫對象
  - 所有保留表引用都能在根 `supabase/` 中找到定義，或已完成 Demo 回退

## P1（1-3 天內完成）

### 1. 凍結 Demo / Real 邊界，明確競賽版只保留 Demo 主線

- 具體要做什麼：
  - 在入口、配置、導航和關鍵服務層明確 Demo-first 策略
  - 隔離 `real_*` 頁面、真實 WebRTC、真實推送與真實 Supabase 主鏈路依賴
  - 當真實依賴缺失或不穩定時自動回退到本地 Demo 數據
- 涉及的主要文件：
  - `linklab/lib/main.dart`
  - `linklab/lib/config/app_config.dart`
  - `linklab/lib/screens/home/**`
  - `linklab/lib/services/unified_*`
- 完成標準：
  - 默認啓動、默認導航、默認演示只走 Demo 主線
  - 真實鏈路不再阻塞 `F1 -> F9 -> F11` 閉環
- 完成記錄（2026-04-17，按 AGENTS.md §7“實施節奏補充”提前執行）：
  - 已在 `main.dart` 中顯式執行 `AppConfig.demoMode = true;`，並繼續通過 `lockCompetitionDemoMode()` 鎖定競賽版只走 Demo 主線。
  - 已在 `app.dart`、`home/main_screen.dart`、`home/home_screen.dart` 補充斷言與說明，確保默認入口、底部導航和首頁文案都明確指向 Demo-only 演示閉環。
  - 已將 `unified_matching_service.dart`、`unified_call_service.dart`、`unified_sos_service.dart`、`matching_service.dart`、`ai_service_manager.dart` 的 Demo/Real 分流統一綁定到 `AppConfig.demoMode`。
  - 已爲主鏈路相關 `demo_*` fallback 服務補充 `AppConfig.shouldUseDemoFallback(...)` 判定；當 Demo 開關關閉時，這些服務不會再被誤當成默認實現。
  - 已在 `real_*` 與 unified 調用真實服務的位置補充 `AGENTS.md §4.2` 註釋，明確真實鏈路僅供實驗，不進入默認導航和競賽演示腳本。
  - 當前階段前置依賴已完成：根 `supabase/` 已收口爲唯一 schema source of truth，真實匹配 / SOS / 推送只允許對齊根 migration 與根 Edge Functions。
- 完成記錄（2026-04-17，當前執行輪次 / 用戶指定 P1-第2項）：
  - 已新建 `linklab/lib/services/experimental/real/`，並將 `real_call_service.dart`、`real_matching_service.dart`、`sos_service.dart`、`webrtc_service.dart`、`ai/real_ai_service_manager.dart`、`webrtc/real_webrtc_service.dart` 的實現遷入實驗目錄。
  - 原路徑現僅保留兼容導出殼，避免歷史實驗頁立即失效；默認 barrel `services_exports.dart`、`ai_module_export.dart`、`webrtc_exports.dart` 已停止導出真實實現。
  - 已將 `unified_matching_service.dart`、`unified_sos_service.dart` 強制收口爲 Demo-only；`unified_call_service.dart` 默認只驅動 Demo 通話，真實通話僅可通過顯式 experimental API 進入。
  - 已將舊 facade `matching_service.dart`、`call_service_factory.dart`、`ai_service_manager.dart` 凍結爲 Demo-first / Demo-only，阻斷默認分流自動進入真實鏈路。
  - 已再次確認默認路由與默認底部導航仍只保留 `Home / AIChat / Profile`，並從 `home_screen.dart` 移除異步留言入口，避免非 MVP 頁面繼續出現在默認首頁。

### 3. 補齊 5 條關鍵閉環測試

- 具體要做什麼：
  - 爲啓動 / 登錄、AI -> 轉人工、匹配 / 通話 / 評價、SOS、Demo 主線端到端各補一條有效測試
  - 優先覆蓋狀態變化、頁面可見反饋和 Demo fallback
- 涉及的主要文件：
  - `linklab/test/**`
  - 相關 screen / service / provider
- 完成標準：
- 5 條關鍵閉環都有自動化測試
  - 測試斷言與 `AGENTS.md` 狀態機、Demo-first 策略一致
- 完成記錄（2026-04-17，當前執行輪次 / 用戶指定 P1-第3項）：
  - 已新增 `linklab/test/closed_loop/test_harness.dart`，統一準備 `AppConfig.demoMode = true`、`ProviderScope`、`AppSessionService` 預置會話和本地 Demo 數據環境。
  - 已新增 5 個帶 `@Tags(['demo', 'closed-loop'])` 的閉環測試：`startup_login_closed_loop_test.dart`、`ai_to_human_closed_loop_test.dart`、`matching_call_rating_closed_loop_test.dart`、`sos_closed_loop_test.dart`、`demo_mainline_end_to_end_test.dart`。
  - 已新增 `linklab/dart_test.yaml`，爲 `demo` / `closed-loop` 標籤提供測試配置，便於按主鏈路迴歸。
  - 已補充 `linklab/lib/demo_flow/demo_help_request_tracker.dart`，把 Demo 主線的本地 `help_request` 狀態顯式追蹤到 `ai_processing -> ai_resolved / matching -> connected -> completed`，並覆蓋 SOS 的 `created -> cancelled / matching` 轉換。
  - 已爲 AI、匹配、通話、SOS 的 Demo 流程補齊測試所需的本地狀態寫入與可見反饋，確保不依賴真實 Supabase、真實推送或真實 WebRTC。
  - 已完成 `flutter test --tags demo` 迴歸，P1 全部完成。

## P2（交付前完成）

### 1. 清理 `flutter analyze` 高噪音問題

- 具體要做什麼：
  - 先處理會遮蔽真實問題的高噪音 warning / lint
  - 聚焦首頁、AI 主線、匹配、通話、SOS、登錄與無障礙相關文件
- 涉及的主要文件：
  - `linklab/lib/**`
  - `linklab/test/**`
- 完成標準：
  - 主應用 analyze 噪音顯著下降
  - 主鏈路問題不再被無關警告淹沒
- 完成記錄（2026-04-17，當前執行輪次 / 用戶指定 P2-第1項）：
  - 已運行 `flutter analyze lib`（`linklab/`）與 `flutter analyze lib`（`linklab/admin_dashboard/`），並記錄清理前後數量。
  - 主應用已通過 `analysis_options.yaml` 明確排除 `AGENTS.md` 已凍結的非 MVP / experimental / 歷史分叉目錄，使默認 analyze 範圍收口到競賽主鏈路。
  - 已將主應用默認鏈路和後臺中的高頻 `withOpacity(...)` 全部收斂爲 `withValues(alpha: ...)`，同步消除 Flutter 新版本棄用噪音。
  - 已修復 `AppLogger` 的過時 API 用法，統一改爲 `dateTimeFormat` 與 `trace` 級別調用，繼續滿足 `AGENTS.md §4.6` 的正式日誌要求。
  - 已清理一批 `unused import`、`unused local variable`、`unnecessary cast`、`BuildContext` 異步告警和可直接消除的 `prefer_const_*` 噪音。
  - 清理結果：
    - 主應用：`629 -> 70`
    - `admin_dashboard`：`36 -> 9`
  - `P2 第1項完成`

### 2. 統一日誌與錯誤處理，減少 `print`

- 具體要做什麼：
  - 用 `AppLogger` 替換主鏈路正式日誌中的 `print` / `debugPrint`
  - 爲關鍵異步流程補齊 `loading / success / empty / error / retry` 狀態表達
- 涉及的主要文件：
  - `linklab/lib/services/**`
  - `linklab/lib/core/utils/logger.dart`
  - 主流程 screen / controller / provider
- 完成標準：
  - 主流程關鍵文件不再新增 `print`
  - 用戶端失敗都有明確文案與降級路徑
- 完成記錄（2026-04-17，當前執行輪次 / 用戶指定 P2-第2項）：
  - 已全倉掃描 `linklab/lib/**/*.dart` 中的 `print(` 與 `debugPrint(`，並將殘留調用統一替換爲 `AppLogger.verbose / info / warning / error`。
  - 已補齊實驗真實鏈路、WebRTC、舊 Demo SOS 流程中的 catch 日誌，統一使用 `AppLogger.error(message, error, stackTrace)` 記錄失敗上下文。
  - 已確認默認主鏈路與實驗隔離目錄都不再殘留 raw `print` / `debugPrint`。
  - `P2 第2項完成`

### 3. 規範配置與密鑰管理

- 具體要做什麼：
  - 收斂 `api_config.dart`、環境變量和示例模板
  - 清理不應進入版本控制的真實配置
  - 補足本地演示所需的 mock / example 配置說明
- 涉及的主要文件：
  - `.gitignore`
  - `linklab/lib/config/api_config.dart`
  - 相關 `.example` / README / 配置模板
- 完成標準：
  - 敏感配置有明確模板與注入方式
  - 競賽版本地運行不依賴真實密鑰
- 完成記錄（2026-04-17，當前執行輪次 / 用戶指定 P2-第3項）：
  - 已將 `linklab/lib/config/api_config.dart` 調整爲本地實驗專用文件，並通過倉庫根 `.gitignore` 與 `linklab/.gitignore` 雙重忽略。
  - 已新增/規範 `linklab/lib/config/api_config.example.dart` 作爲唯一入庫模板，並同步修正相關文檔引用。
  - 已執行 `git rm --cached linklab/lib/config/api_config.dart`，停止真實配置文件被 Git 繼續追蹤。
  - 已複覈 `supabaseUrl / supabaseAnonKey / API key` 相關常量，代碼庫只保留佔位值或公開服務端點，未保留真實密鑰。
  - `P2 第3項完成`

## 競賽演示閉環檢查項

| 時間 | 必跑動作 | 當前狀態 | 說明 |
|---|---|---|---|
| `0:00–0:20` | 打開 App，大按鈕吸睛 | `需迴歸驗證` | 需確認默認啓動不會被真實登錄、真實初始化或資源缺失阻塞 |
| `0:20–0:50` | 語音求助“幫我讀藥品盒”→ AI 識別朗讀 | `已具備` | Demo AI 路徑已存在，需在 P0 修復後迴歸弱網 / 本地 fallback |
| `0:50–1:30` | “我面前是什麼”→ 場景描述 | `已具備` | 需確認場景描述繼續走穩定 Demo 響應，不被真實多模態依賴卡住 |
| `1:30–2:10` | 複雜需求 → `F9` 匹配 → `F11` 通話 | `已具備` | 當前 Demo matching + demo call 是主閉環，必須持續保持穩定 |
| `2:10–2:40` | `F13` SOS 演示（Mock 模式） | `需迴歸驗證` | 需確認 SOS 走 Mock 廣播、聯繫人通知和 10 秒撤銷窗口 |
| `2:40–3:00` | 展示未來藍圖 | `需修復` | 需要單獨的靜態藍圖展示，不得混入未完成真實功能冒充已完成 |

## 驗證記錄口徑補充（2026-05-01）

- `2026-04-17` 歷史記錄中，`flutter test --tags demo` 曾標記爲通過；同一批記錄也寫明 `flutter analyze lib` 仍存在主應用 `70 issues found`、`admin_dashboard` `9 issues found`。
- `docs/rc_acceptance_evidence.md` 的 RC 記錄寫明，後續曾有 `flutter analyze` 爲 `No issues found`、`flutter test --reporter compact` 爲 `All tests passed`（60 tests）的結果。
- `docs/competition_mvp_delivery_plan.md` 和 `docs/plans/2026-04-12-prd-alignment-main-frontend.md` 已把 `flutter build web --debug` / `flutter build web --release` 納入 Web 演示驗收口徑。
- 上述記錄來自不同時間點，不應混寫成“當前全部已複驗”。本輪只整理 Markdown 文檔，未運行 `flutter test`、`flutter analyze`、`flutter build web` 或任何 Flutter 命令。
- 交付前建議以 Web / Chrome 爲主路徑重新執行：`flutter test`、`flutter build web --release`，並把具體日期、命令和結果補入 `docs/rc_acceptance_evidence.md`。
- 真實 WebRTC、真實 Supabase、真實推送、真實短信和生產級 SOS 仍按實驗/後續能力處理；競賽 Demo 只承諾本地 Demo fallback 與 Mock 狀態展示。
