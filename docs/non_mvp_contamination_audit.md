# 非 MVP 防污染審計

> 口徑聲明：**競賽 Demo 不依賴外部服務**。本審計只判斷非 MVP 模塊是否污染默認 3 分鐘 Demo 主線，不等同於刪除歷史代碼，也不聲明真實後端、真實 WebRTC、真實推送或真實後臺已完成。

## 審計結論

當前 Flutter 默認入口、默認底部導航和主演示鏈路未發現可直接進入 admin、community、points、badges、schedule、recording、真實 WebRTC 或真實 Supabase-only flow 的入口。主要風險集中在歷史代碼仍保留、`analysis_options.yaml` 對 legacy 模塊做了排除、根 `supabase/` 仍包含 points/push/recordings/schedule 等非 MVP 結構。

## 模塊清單

| 模塊名稱 | 當前路徑 | 當前狀態 | 是否可從默認首頁進入 | 是否影響 flutter analyze | 是否影響 flutter test | 建議後續處理 |
|---|---|---|---|---|---|---|
| 獨立運營後臺 | `linklab/admin_dashboard/` | legacy / hidden | 否 | 否；當前不參與主 App analyze | 否；不在主 App 測試鏈路 | 保留爲歷史工程或單獨歸檔；不得接回競賽 App 默認入口 |
| 主應用內後臺殘留 | `linklab/lib/admin/` | legacy / hidden | 否 | 否；`analysis_options.yaml` 已排除 | 否 | 後續若做真實後臺，統一到獨立後臺或 Supabase Dashboard，不在求助端保留入口 |
| 交互式社羣 / 羣聊 / 地區社區 | `linklab/lib/screens/community/**`；`linklab/lib/services/community/**` | legacy / hidden | 否 | 否；已排除 | 否 | 競賽版最多保留靜態精選故事；羣聊、地區社區、新手村繼續隱藏 |
| 首頁舊社羣頁面 | `linklab/lib/screens/home/community_screen.dart` | legacy / hidden | 否 | 否；已排除 | 否 | 不接回底部導航；如需競賽敘事，改用靜態未來藍圖 |
| 積分 / 等級 / 公益時長 | `linklab/lib/services/user_center/points_service.dart`；`linklab/lib/screens/user_center/*points*` | legacy / hidden | 否 | 否；相關 user_center legacy 已排除 | 否 | 不進入默認“我的”；後續作爲 V1.0 獨立評估 |
| 徽章 | `linklab/lib/services/user_center/badge_service.dart`；`linklab/lib/screens/user_center/*badge*` | legacy / hidden | 否 | 否；相關 user_center legacy 已排除 | 否 | 不進入默認個人中心；僅可作爲未來藍圖口播 |
| 排班 | `linklab/lib/services/user_center/schedule_service.dart`；`linklab/lib/models/schedule_model.dart` | legacy / hidden | 否 | 否；service 已排除 | 否 | F9 Demo 使用本地志願者在線狀態，不接真實排班 |
| 舊 user_center 模塊 | `linklab/lib/screens/user_center/**`；`linklab/lib/services/user_center/**` | legacy / partial hidden | 默認首頁不進入；當前只使用獨立 Demo 幫助記錄頁 | 否；多數 legacy 路徑已排除 | 否 | 保留幫助回看所需 demo 頁面；其餘積分、收藏、排班、徽章繼續隔離 |
| 通話錄音 / AI 錄音檢測 | `linklab/lib/services/security/call_recording_service.dart`；`linklab/lib/services/webrtc/call_recording_service.dart` | legacy / hidden | 否 | 否；已排除 | 否 | V2.0 之前不得進入 F11 Demo Call；不得請求錄音權限 |
| 真實 WebRTC 服務 | `linklab/lib/services/webrtc/**`；`linklab/lib/services/webrtc_service.dart`；`linklab/lib/services/experimental/real/webrtc/real_webrtc_service.dart` | experimental / hidden | 否 | 默認主分析不依賴；部分 legacy 已排除 | 否；Demo Call 測試斷言 feature flag 關閉 | 繼續放在 experimental/real adapter 後方；默認不得初始化或請求麥克風 |
| 真實通話頁面 | `linklab/lib/screens/call/real_call_screen.dart`；舊 `lib/pages/call/**` | experimental / hidden | 否 | 否；已排除 | 否 | 不接回 F11 默認路徑；F11 RC 只驗收 Demo Call 狀態機 |
| 真實匹配服務 | `linklab/lib/services/real_matching_service.dart` | experimental / hidden | 否 | 否；已排除 | 否 | F9 RC 使用 `DemoMatchingEngineService`；真實服務待 schema 收口後再評估 |
| 生產推送通知 | `linklab/lib/services/push_notification_service.dart`；`supabase/functions/push-notifier/` | experimental / backend residual | 否 | Flutter 主線不依賴 | Flutter 主線不依賴 | 保留爲後續基礎設施；競賽 Demo 不得要求 FCM token 或真實推送 |
| 生產緊急通知 / 真實短信 | `linklab/lib/services/sos_service.dart`；安全相關 legacy service | experimental / hidden | 否 | 否；相關路徑已排除 | 否 | F13 RC 只做 Mock；不得默認發短信、定位、報警 |
| volunteer advanced certification | 志願者高級認證相關舊頁面 / service | hidden / V1.0 | 否 | 當前不影響 | 當前不影響 | F33 RC 只保留預置演示員會話與基礎偏好，不做專業認證 |
| `linklab/supabase` 分叉 | `linklab/supabase/legacy/**` | legacy | 否 | 否 | 否 | 根 `supabase/` 是唯一事實來源；該分叉繼續停止執行或歸檔 |
| 根 Supabase points function | `supabase/functions/points-calculator/`；`supabase/config.toml` | active backend residual / non-MVP | 否 | 不影響 Flutter analyze | 不影響 Flutter test | 交付前標記 legacy 或移出競賽部署清單；不得作爲 F15 展示 |
| 根 Supabase push function | `supabase/functions/push-notifier/`；`supabase/config.toml` | active backend residual / infrastructure | 否 | 不影響 Flutter analyze | 不影響 Flutter test | 僅可作爲後續 F34 基礎設施；競賽 Demo 不依賴真實推送 |
| 根 Supabase 非 MVP 表 | `supabase/migrations/*.sql` 中 `point_transactions`、`call_records`、`available_schedule`、`push_logs` 等 | active backend residual / contamination risk | 否 | 不影響 Flutter analyze | 不影響 Flutter test | MVP schema 後續收口到 `users`、`volunteer_profiles`、`help_requests`、`emergency_contacts`、`virtual_identities` |
| 默認底部導航 | `linklab/lib/screens/home/main_screen.dart` | active / demo-only | 是；僅：首頁 / AI助手 / 我的 | 是；已通過主線 analyze | 是；`widget_test.dart` 覆蓋 | 繼續禁止加入社羣、積分、徽章、排班、後臺等非 MVP tab |
| 配置 feature flags | `linklab/lib/config/app_config.dart` | active / demo-only guard | 間接影響默認入口 | 是 | 是；`widget_test.dart` 新增關閉斷言 | 保持 `isCompetitionDemoOnly = true`；真實模式不得在競賽構建打開 |

## 後續處理優先級

1. **P0 賽前保持**：默認導航、首頁卡片、AI、匹配、通話、SOS 不接入非 MVP 模塊；feature flags 維持關閉。
2. **P1 後端收口**：根 `supabase/` 中 points、recordings、schedule、push 等非 MVP residual 需要拆分爲 legacy 或後續部署清單。
3. **P2 架構清理**：逐步把 legacy `ChangeNotifier` / singleton service 收斂到 provider-backed facade，但不要在 RC 前做大規模重構。
