# 共感 LinkAble 競賽 Demo 驗收檢查清單

> 使用範圍：2026 創客大賽 Demo-first MVP
> 關鍵聲明：**競賽 Demo 不依賴外部服務**。所有檢查都應在無真實 Supabase、無真實 WebRTC、無真實推送、無真實 OCR key 的情況下成立。

## 啓動檢查

- [ ] `linklab/lib/main.dart` 啓動時鎖定 demo mode，並啓用演示員預置會話。
- [ ] App 通過 `ProviderScope(child: LinkLabApp())` 啓動。
- [ ] `LinkLabApp` 能根據 session 狀態進入默認主界面；競賽演示不被登錄/註冊卡住。
- [ ] 默認底部導航只有 `首頁 / AI助手 / 我的`。
- [ ] 首頁第一屏顯示“我需要幫助”大按鈕，且按鈕可點擊進入 AI 或匹配主流程。
- [ ] 不需要真實 Supabase 初始化、不需要 Firebase 初始化、不需要真實 API key 才能打開 App。

建議命令：

```powershell
git status --short
cd linklab
flutter pub get
flutter test test/closed_loop/startup_login_closed_loop_test.dart
```

## 無網絡 / 無 API key 檢查

- [ ] 斷網或不配置真實 API key 時，App 仍能啓動到首頁。
- [ ] OCR、場景描述、匹配、通話、SOS 都走本地 demo fallback。
- [ ] 頁面沒有要求輸入 Supabase URL、Firebase token、WebRTC server、OCR key。
- [ ] 控制檯沒有因爲缺少外部服務而導致主流程崩潰。
- [ ] 評審現場可明確說明：競賽 Demo 不依賴外部服務，真實集成是後續版本。

建議檢查：

```powershell
cd linklab
rg -n "Supabase.initialize|Firebase.initializeApp|RealCallService\(|WebRTCService\(|PushNotificationService\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
```

驗收口徑：默認啓動、首頁和 demo flow 不應命中真實外部服務初始化或真實通話依賴。

## AI demo fallback 檢查

- [ ] 從首頁大按鈕或 `AI助手` 進入單一 AI Agent 入口。
- [ ] 輸入或選擇“幫我讀藥品盒”，返回本地 OCR demo 響應。
- [ ] OCR 響應包含藥名、規格、用法用量、有效期等可講述信息。
- [ ] 輸入或選擇“我面前是什麼”，返回本地場景描述 demo 響應。
- [ ] AI 響應有處理中、成功、失敗或可轉人工等明確狀態。
- [ ] AI 無法處理或複雜需求時，可以 `100%` 轉到志願者匹配。
- [ ] 緊急詞能進入 SOS 路徑，不能只停留在普通聊天回覆。

對應代碼：

- `linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`
- `linklab/lib/services/demo/demo_ai_service.dart`
- `linklab/assets/demo_data/ai_responses.json`
- `linklab/assets/demo_data/help_scenarios.json`

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/ai_to_human_closed_loop_test.dart
flutter test test/closed_loop/demo_mainline_end_to_end_test.dart
```

## 匹配 demo 檢查

- [ ] 點擊轉人工或複雜需求後進入 `DemoMatchingScreen`，不是進入真實 `MatchingScreen`。
- [ ] 匹配頁顯示處理中狀態、候選志願者信息和成功狀態。
- [ ] demo 志願者數據來自 `assets/demo_data/volunteers.json`。
- [ ] 用戶可以取消匹配，取消後有可見反饋。
- [ ] 匹配成功後進入 demo 通話，不依賴真實推送、真實地理位置或真實 Supabase。

對應代碼：

- `linklab/lib/demo_flow/demo_matching_flow.dart`
- `linklab/lib/screens/call/demo_matching_screen.dart`
- `linklab/lib/services/demo_call_service.dart` 中 `DemoMatchingService`
- `linklab/assets/demo_data/volunteers.json`

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/matching_call_rating_closed_loop_test.dart
rg -n "MatchingScreen\(|RealCallScreen|RealCallPage|WebRTCService\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
```

## 通話 demo 檢查

- [ ] 匹配成功後進入 `DemoCallScreen`，不是進入真實 WebRTC 通話頁。
- [ ] 通話頁顯示連接中、已連接、志願者信息、掛斷按鈕。
- [ ] 掛斷後進入評價頁或結果回看落點。
- [ ] 評價提交後可返回首頁或幫助檔案落點。
- [ ] 口播明確：這是 demo 通話狀態機，真實 WebRTC 是後續真實集成，不作爲競賽 Demo 外部依賴。

對應代碼：

- `linklab/lib/screens/call/demo_call_screen.dart`
- `linklab/lib/screens/call/demo_call_rating_screen.dart`
- `linklab/lib/services/demo_call_service.dart` 中 `DemoCallService`

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/matching_call_rating_closed_loop_test.dart
```

## SOS mock 檢查

- [ ] 首頁 SOS 或 AI 緊急詞能進入 `DemoSOSScreen`。
- [ ] 頁面顯示 10 秒誤觸撤銷窗口。
- [ ] 頁面顯示 Mock 廣播演示，不依賴真實推送。
- [ ] 頁面顯示緊急聯繫人通知狀態；聯繫人爲空時有明確說明和降級文案。
- [ ] 用戶能撤銷誤觸；撤銷後狀態明確，不靜默失敗。
- [ ] SOS 路徑不走普通 F9 匹配公式，而是廣播型緊急流程。

對應代碼：

- `linklab/lib/screens/call/demo_sos_screen.dart`
- `linklab/lib/services/demo_call_service.dart` 中 `DemoSOSService`
- `linklab/lib/demo_flow/demo_sos_flow.dart`
- `linklab/lib/services/security/emergency_contact_service.dart`

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/sos_closed_loop_test.dart
```

## 無障礙檢查

- [ ] 默認主鏈路所有交互控件有可理解的 `Semantics` label/hint。
- [ ] 主要按鈕和可點區域接近或達到 `48x48dp`。
- [ ] 文字和背景對比度達到 `>= 7:1` 的競賽口徑。
- [ ] 系統字體縮放到 `200%` 時，首頁、AI、匹配、通話、SOS、我的頁不破版。
- [ ] 錯誤、警告、成功狀態不能只靠顏色表達，需要文字和圖標共同表達。
- [ ] 焦點順序符合視覺與操作順序。
- [ ] 不存在強制倒計時選擇；唯一允許例外是 SOS 10 秒誤觸撤銷窗口。
- [ ] 圖片、故事卡片和圖標型按鈕有可理解替代文本或語義說明。

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/theme_toggle_live_update_test.dart
```

人工驗收：使用系統讀屏和 `200%` 字體縮放完整跑一遍 3 分鐘腳本。

## Flutter analyze / test 驗收

- [ ] `flutter analyze` 通過。
- [ ] `flutter test` 通過。
- [ ] 閉環測試至少覆蓋啓動/登錄、AI 轉人工、匹配通話評價、SOS、Seeker Center MVP 範圍。
- [ ] 不把被 `analysis_options.yaml` 排除的默認可達頁面誤認爲已完全驗收；P0 後應恢復默認主鏈路 analyze 覆蓋。

建議命令：

```powershell
cd linklab
flutter analyze
flutter test
flutter test test/closed_loop
```

## 非 MVP 污染檢查

- [ ] 默認社羣僅展示精選故事，沒有發帖、羣聊或地區社羣；積分、徽章、排班、後臺不進入主線。
- [ ] 首頁和 demo flow 不進入真實 WebRTC、真實推送、真實 Supabase 頁面。
- [ ] `SeekerCenterScreen` 默認只展示“幫助檔案 / 求助狀態”；積分、異步任務、收藏志願者不進入競賽主線。
- [ ] 根 `supabase/` 中非 MVP 表和 functions 已被標註 legacy、歸檔或從競賽部署路徑移除。
- [ ] `admin_dashboard/`、`linklab/lib/admin/` 不參與競賽 App 默認構建驗收。

建議命令：

```powershell
cd linklab
rg -n "AdminLoginScreen|AdminLayout|InterestGroupsScreen|GroupChatScreen|NewbieVillageScreen|PointsTab|AsyncRequestsTab|FavoriteVolunteersTab|RealCallScreen|RealCallPage|MatchingScreen\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
rg -n "points-calculator|point_transactions|async_tasks|reports|call_records" ..\supabase
```

## 文檔與變更範圍檢查

- [ ] 本輪只改 `docs/` 下文檔。
- [ ] 未改 `AGENTS.md`。
- [ ] 未改 `lib/`、`test/`、`supabase/`。
- [ ] 已運行 `git diff -- docs`；若新建文檔尚未被 Git 跟蹤，結合 `git status --short` 或 `git diff --no-index` 覈對新增內容。

建議命令：

```powershell
git diff -- docs
git status --short
```
