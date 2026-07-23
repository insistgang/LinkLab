# 共感 LinkAble 競賽 Demo MVP 交付計劃

> 狀態日期：2026-04-28
> 最高事實來源：根目錄 `AGENTS.md`
> 交付硬約束：**競賽 Demo 不依賴外部服務**。默認首頁、默認路由、默認構建和默認測試只服務 F1/F9/F11/F13/F33/F36 六項 MVP。
> 2026-05-01 文檔口徑補充：當前對外標註爲 Demo-first MVP，Web / Chrome 是首選演示路徑；本輪文檔整理未運行 Flutter，歷史驗證記錄需要在交付前復跑確認。

## 項目定位

共感 LinkAble 是一個“AI Agent 第一響應 + 人類志願者兜底”的無障礙互助 App。競賽 Demo 的目標不是展示完整平臺能力，而是在 3 分鐘內穩定跑通：用戶發起求助、AI 先處理、複雜或高風險問題轉人工、進入志願者匹配、完成 demo 通話、必要時觸發 SOS，並且全流程對讀屏、動態字體和低認知負擔友好。

當前工程驗收口徑是 Demo-first MVP：只交付可點擊、可講述、可閉環的本地演示主線。真實 Supabase、真實 WebRTC、真實推送、後臺和社羣等能力可以作爲後續方向存在，但不得阻塞競賽 Demo。

## 當前主鏈路判斷

- `linklab/lib/main.dart` 已在啓動時鎖定 demo mode，啓用演示員預置會話，初始化 `DemoDataLoader`，並通過 `ProviderScope(child: LinkLabApp())` 啓動。
- `linklab/lib/app.dart` 中 `LinkLabApp` 已是 `ConsumerWidget`，默認通過 session 狀態進入 `MainScreen`、登錄或首次引導。
- `linklab/lib/screens/home/main_screen.dart` 默認底部導航已收縮爲 `首頁 / AI助手 / 我的`。
- `linklab/pubspec.yaml` 已聲明 `assets/demo_data/`，`DemoDataLoader` 當前讀取 `volunteers.json`、`ai_responses.json`、`help_scenarios.json`。
- 當前審計結論：Flutter 默認演示主鏈路基本符合 Demo-first，但仍需要繼續隔離 `SeekerCenterScreen` 內的積分/異步/收藏殘留、根 `supabase/` 的非 MVP 表和 `points-calculator`、真實 WebRTC/推送/admin/community 的非默認入口。

## 當前唯一 MVP 範圍

| ID | 功能 | Demo MVP 驗收口徑 | 當前代碼入口 |
|---|---|---|---|
| `F1` | AI Agent 智能對話 | 單一入口承接 OCR、場景描述、顏色識別、鈔票識別、翻譯、環境描述、導航、藥品確認、緊急詞檢測；首次響應 `<= 3s`；連續 3 輪上下文正確；AI 無法處理時 `100%` 可轉人工；無網絡/無 API key 時走本地 demo fallback | `linklab/lib/screens/home/ai_chat_screen.dart`；`linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`；`linklab/lib/services/demo/demo_ai_service.dart`；`linklab/assets/demo_data/ai_responses.json`；`linklab/assets/demo_data/help_scenarios.json` |
| `F9` | 志願者匹配引擎 | AI 無法處理或用戶主動轉人工時進入匹配；基於 demo 志願者池展示 Top 5/默認志願者；匹配頁有處理中、成功、取消等可見狀態；競賽 Demo 不依賴真實地理位置、推送或 Supabase | `linklab/lib/demo_flow/demo_matching_flow.dart`；`linklab/lib/screens/call/demo_matching_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoMatchingService`；`linklab/assets/demo_data/volunteers.json` |
| `F11` | 實時語音通話 | 匹配成功後進入 demo 通話；必須展示連接中、已連接、掛斷、評價、結果沉澱；視頻、屏幕共享、真實 WebRTC 建鏈不進入競賽主線 | `linklab/lib/screens/call/demo_call_screen.dart`；`linklab/lib/screens/call/demo_call_rating_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoCallService` |
| `F13` | SOS 緊急呼救 | 一鍵或緊急意圖觸發；必須顯示廣播、聯繫人通知、誤觸撤銷窗口；Demo 允許 mock，但狀態變化必須可見；唯一允許的倒計時是 10 秒誤觸撤銷窗口 | `linklab/lib/screens/call/demo_sos_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoSOSService`；`linklab/lib/demo_flow/demo_sos_flow.dart`；`linklab/lib/services/security/emergency_contact_service.dart` 的本地 fallback |
| `F33` | 登錄與無障礙偏好 | 手機號驗證碼登錄 + 首次引導 + 簡化身份/偏好設置；競賽默認使用預置演示員會話，避免 3 分鐘腳本卡在註冊；登錄和偏好流程仍需可獨立跑通 | `linklab/lib/main.dart`；`linklab/lib/services/app_session_service.dart`；`linklab/lib/providers/app_session_provider.dart`；`linklab/lib/screens/auth/onboarding_screen.dart`；`phone_login_screen.dart`；`verification_screen.dart`；`identity_select_screen.dart`；`disability_select_screen.dart`；`preference_screen.dart` |
| `F36` | 全局無障礙適配 | 所有默認可達頁面必須有清晰 `Semantics`、接近或達到 `48x48dp` 觸摸目標、`>= 7:1` 對比度、支持 `200%` 字體縮放、錯誤狀態不只靠顏色表達；讀屏用戶能獨立完成主流程 | `linklab/lib/app.dart` 中 `TextScaler` 適配；`linklab/lib/widgets/accessible/`；默認主鏈路頁面中的 `Semantics` 與無障礙按鈕文案；閉環測試 `linklab/test/closed_loop/` |

## 明確排除範圍

以下內容不屬於競賽 Demo MVP，不得進入默認導航、默認首頁、默認路由、默認測試驗收或 P0/P1 資源：

- 交互式社羣、羣聊、地區社區、新手村、訓練場景；競賽版最多保留硬編碼精選故事展示。
- 積分、徽章、善意時間線、排班、多級認證、積分流水和排行榜。
- `admin_dashboard/` 與 `linklab/lib/admin/` 後臺；運營後臺由 Supabase Dashboard 替代，不作爲競賽 App 能力展示。
- 真實 WebRTC、真實信令、視頻、屏幕共享、通話錄音、AI 通話檢測。
- 真實推送、FCM、App 未啓動時的真實後臺喚醒；Demo 只展示本地 mock 狀態。
- 真實 Supabase 強依賴、真實 API key、真實 OCR key、真實部署腳本；競賽 Demo 必須在無網絡/無 key 時完成。
- 異步留言、任務隊列、`async_tasks`、`point_transactions`、`reports`、`call_records`、`points-calculator` 等非 MVP 後端能力。

## 已符合 AGENTS.md 的點

- 全局入口已有 `ProviderScope`，`LinkLabApp` 可讀取 Riverpod session provider。
- `AppConfig` 已鎖定競賽 demo mode，並啓用演示員預置會話。
- 默認導航已收斂爲 `首頁 / AI助手 / 我的`，未把後臺、社羣、積分、真實通話放入底部導航。
- 演示數據已落在 `assets/demo_data/`，並由 `DemoDataLoader` 加載。
- `linklab/supabase/` 已標記 legacy，根目錄 `supabase/` 是事實來源。
- `docs/rc_acceptance_evidence.md` 曾記錄 `flutter analyze` 和 `flutter test` 通過，但注意部分默認可達文件仍被 `analysis_options.yaml` 排除，不能把歷史通過結果誤讀爲當前全主鏈路完全無風險。
- Web / Chrome 是首選演示路徑；Windows 桌面運行或構建需要 Visual Studio C++ 桌面開發工具鏈，不作爲默認驗收入口。

## P0/P1/P2 修復順序

### P0：阻斷演示污染源

1. 恢復或重構默認可達文件的 analyze 覆蓋：`SeekerCenterScreen`、`demo_flow`、安全/聯繫人入口等默認主鏈路文件不應長期被排除。
2. 拆分 `SeekerCenterScreen`：默認只保留“幫助檔案 / 求助狀態”；將 `AsyncRequestsTab`、`PointsTab`、`FavoriteVolunteersTab` 以及對 `AsyncTaskService`、`PointsService`、`VolunteerDetailScreen` 的依賴移出主文件或歸檔。
3. 收斂根 `supabase/`：MVP 事實表只保留 `users`、`volunteer_profiles`、`help_requests`、`emergency_contacts`、`virtual_identities`；`async_tasks`、`point_transactions`、`reports`、`call_records`、`points-calculator` 移入 legacy 或明確非競賽路徑。
4. 複覈主鏈路沒有真實 Supabase、真實 Firebase、真實 WebRTC、真實推送初始化要求；無 key、斷網仍能打開 App 並完成 3 分鐘腳本。

### P1：凍結 Demo / Real 邊界

1. 將 `real_*` 頁面、`MatchingScreen`、`RealCallScreen`、`RealCallPage`、真實 WebRTC service、推送 service、admin route 明確標記爲 experimental，確認默認入口無法觸達。
2. 精選故事保持靜態展示；若進入詳情頁，移除或隱藏 like/unlike 等交互式社羣行爲。
3. 對 `flutter_webrtc`、Firebase、admin dashboard 相關依賴做隔離評估，避免默認平臺構建被非 MVP 依賴拖垮。
4. 將 SOS mock 的 10 秒撤銷窗口、廣播展示、聯繫人通知展示與 AGENTS.md 口徑對齊；真實 `<= 3s` 推送指標只作爲後續真實集成驗收，不冒充 Demo 已完成。

### P2：交付前收斂質量

1. 歸檔重複實現，例如未被默認主鏈路使用的 `demo_flow/demo_ai_service.dart`。
2. 逐步把 UI 直接 new service、service singleton 和裸 `setState` 流程狀態遷移到 provider-backed controller。
3. 統一 `AppLogger`，減少 `print` / `debugPrint`，並補齊失敗態的可見降級路徑。
4. 複查 F36：動態字體 `200%`、讀屏順序、觸摸目標、顏色+圖標+文字三重錯誤表達。

## 分階段驗收命令

### P0 驗收

```powershell
git status --short
cd linklab
flutter pub get
flutter analyze
flutter test test/closed_loop/seeker_center_scope_test.dart
flutter test test/closed_loop/demo_mainline_end_to_end_test.dart
rg -n "PointsTab|AsyncRequestsTab|FavoriteVolunteersTab|PointsService|AsyncTaskService|VolunteerDetailScreen" lib/screens/user_center/seeker_center_screen.dart
rg -n "points-calculator|point_transactions|async_tasks|reports|call_records" ..\supabase
```

驗收口徑：Flutter 命令通過；後兩個 `rg` 只能命中 legacy/archive 或無輸出，不能命中競賽默認主鏈路。

### P1 驗收

```powershell
cd linklab
flutter analyze
flutter test test/closed_loop
flutter build web --debug
rg -n "AdminLoginScreen|AdminLayout|RealCallScreen|RealCallPage|MatchingScreen\(|InterestGroupsScreen|GroupChatScreen|NewbieVillageScreen" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
rg -n "Supabase.initialize|Firebase.initializeApp|RealCallService\(|WebRTCService\(|PushNotificationService\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
```

驗收口徑：構建和測試通過；默認主鏈路搜索不出現真實後端、真實通話、後臺或交互式社羣入口。

### P2 驗收

```powershell
cd linklab
flutter analyze
flutter test
flutter build web --release
flutter pub deps --style=compact
rg -n "print\(|debugPrint\(" lib
rg -n "factory .*Service\(\)|static final .*Service _instance|ChangeNotifier" lib/screens lib/services
```

驗收口徑：默認構建和全量測試通過；日誌、service singleton 和 `ChangeNotifier` 殘留都有明確遷移或隔離說明。
