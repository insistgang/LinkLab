# 共感 LinkAble 3 分鐘競賽 Demo 腳本

> 最高事實來源：根目錄 `AGENTS.md` §8
> 關鍵聲明：**競賽 Demo 不依賴外部服務**。腳本必須在無網絡、無真實 API key、無真實 Supabase、無真實推送、無真實 WebRTC 的情況下可重複完成。

## 演示前檢查

- 使用競賽 demo mode 啓動 App；默認應通過演示員預置會話進入首頁，不在現場消耗時間註冊。
- 設備可以關閉網絡或不配置任何真實 API key；OCR、場景描述、匹配、通話、SOS 均使用本地 demo fallback。
- 默認底部導航只展示 `首頁 / AI助手 / 我的`。
- 不打開 admin、真實 WebRTC、真實 Supabase Dashboard、交互式社羣、積分或徽章頁面。

## 時間軸

| 時間 | 必跑動作 | 講解重點 | 預期可見狀態 | 當前代碼入口 |
|---|---|---|---|---|
| `0:00-0:20` | 打開 App，停留首頁，展示大按鈕 | “共感 LinkAble 是 AI Agent 第一響應、人類志願者兜底的無障礙互助 App。競賽 Demo 不依賴外部服務。” | 首頁立即可見；主按鈕“我需要幫助”；底部導航爲 `首頁 / AI助手 / 我的`；主按鈕有讀屏語義、高對比和大觸摸目標 | `linklab/lib/main.dart`；`linklab/lib/app.dart`；`linklab/lib/screens/home/main_screen.dart`；`linklab/lib/screens/home/home_screen.dart` |
| `0:20-0:50` | 點擊首頁大按鈕或進入 AI 助手，輸入/選擇“幫我讀藥品盒” | “AI 先處理日常求助。本地 demo 數據模擬 OCR，即使沒有 OCR key 也能返回穩定結果。” | AI 顯示正在分析；返回藥品 OCR demo 結果，例如阿莫西林膠囊、規格、用法用量、有效期；頁面提供繼續提問或轉人工入口 | `linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`；`linklab/lib/services/demo/demo_ai_service.dart`；`linklab/assets/demo_data/ai_responses.json` |
| `0:50-1:30` | 輸入/選擇“我面前是什麼” | “同一個 AI Agent 入口也承接場景描述，不把 OCR、看圖、導航拆成多個複雜入口。” | AI 顯示場景描述 demo 響應，例如室內/街道/公園/超市場景；有文字結果、狀態變化和繼續求助入口 | `linklab/lib/screens/home/ai_chat_screen.dart`；`linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`；`linklab/lib/services/demo/demo_ai_service.dart` |
| `1:30-2:10` | 輸入複雜需求或點擊轉人工，進入志願者匹配，再進入 demo 通話 | “AI 無法處理時 100% 有人類兜底。F9 接單後進入 F11 Demo Call，展示連接中、已接通、結束通話、完成評價；競賽版不依賴真實 WebRTC。” | 進入匹配頁；展示匹配中、Top 5 候選志願者、匹配成功；自動或手動進入 demo 通話；通話頁顯示連接中、已接通、通話中、掛斷；結束後進入幫助完成評價/結果落點；不建立真實 WebRTC、不錄音、不真實推送 | `linklab/lib/demo_flow/demo_matching_flow.dart`；`linklab/lib/screens/call/demo_matching_screen.dart`；`linklab/lib/screens/call/demo_call_screen.dart`；`linklab/lib/screens/call/demo_call_rating_screen.dart`；`linklab/lib/providers/demo_call_flow_provider.dart` |
| `2:10-2:40` | 返回首頁或通過 AI 緊急意圖觸發 SOS mock 演示 | “SOS 是廣播型緊急流程，不走普通匹配公式。Demo 會讓評審看到誤觸撤銷、廣播和聯繫人通知狀態。” | 進入 SOS 頁面；顯示 10 秒誤觸撤銷窗口；顯示 Mock 廣播演示；顯示聯繫人通知狀態；可撤銷或繼續到志願者響應狀態 | `linklab/lib/screens/call/demo_sos_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoSOSService`；`linklab/lib/demo_flow/demo_sos_flow.dart` |
| `2:40-3:00` | 展示未來藍圖 | “當前已演示的是 MVP 六項：F1/F9/F11/F13/F33/F36。V1.0/V2.0 是路線圖，不冒充已完成能力。” | 只展示或口播後續計劃：真實 WebRTC、真實推送、完整後臺、社羣、積分等屬於後續版本；不進入半成品頁面 | `docs/competition_mvp_delivery_plan.md`；首頁的 MVP 範圍說明；演示 PPT 或靜態藍圖頁 |

## 逐段口播要點

### `0:00-0:20` 首頁

推薦口播：

> 這是共感 LinkAble。我們的核心不是堆功能，而是讓視障或行動不便用戶在需要幫助時，用一個大按鈕進入 AI Agent；AI 能解決就立即解決，解決不了就轉真人志願者。

必須展示：

- 首頁第一屏可見。
- 大按鈕足夠醒目。
- 默認導航沒有社羣、積分、後臺等非 MVP 功能。

### `0:20-0:50` 藥品 OCR

推薦口播：

> 這裏演示“幫我讀藥品盒”。競賽環境不依賴真實 OCR 服務，當前響應來自本地 demo 數據，所以斷網也能穩定復現。

必須展示：

- 用戶輸入或選擇“幫我讀藥品盒”。
- AI 有“正在分析”或類似處理中狀態。
- 結果必須包含藥名、規格、用法用量等可讀信息。

### `0:50-1:30` 場景描述

推薦口播：

> 同一個入口繼續處理“我面前是什麼”。這避免讓用戶在多個功能按鈕裏做選擇，符合低認知負擔原則。

必須展示：

- 場景描述以文字形式展示。
- 如果 AI 沒法處理，必須能轉人工，不能出現死路。

### `1:30-2:10` 匹配與 demo 通話

推薦口播：

> 對複雜問題，AI 不硬答，直接轉人工。F9 接單後進入 F11 Demo Call，現場展示連接中、已接通、結束通話和完成評價；這裏不建立真實 WebRTC，不錄音，也不觸發真實推送。

必須展示：

- 匹配頁狀態變化。
- 至少一個志願者被匹配。
- 通話頁狀態從連接中到已接通、通話中、結束通話。
- 結束後出現評價或結果回看落點。

### `2:10-2:40` SOS mock

推薦口播：

> SOS 是緊急廣播流程，與普通匹配不同。爲了避免誤觸，系統保留 10 秒撤銷窗口；Demo 同時展示廣播和聯繫人通知狀態。

必須展示：

- 10 秒誤觸撤銷窗口。
- Mock 廣播演示。
- 緊急聯繫人通知狀態。
- 用戶能撤銷誤觸，或看到 SOS 繼續推進。

### `2:40-3:00` 未來藍圖

推薦口播：

> 今天驗收的是 MVP：AI Agent、志願者匹配、demo 通話、SOS、登錄偏好和全局無障礙。真實 WebRTC、真實推送、後臺、社羣和積分會進入後續 V1.0/V2.0，不把未完成能力冒充爲當前已上線。

禁止口播：

- “真實 WebRTC 已完整上線。”
- “真實推送和後臺喚醒已經完成。”
- “積分、社羣、後臺是本次 MVP 的核心能力。”
- “當前 Demo 依賴線上 Supabase 才能跑。”

## 失敗降級口徑

- 如果現場無網絡：直接說明競賽 Demo 不依賴外部服務，並繼續跑本地 demo fallback。
- 如果 AI 響應不符合預期：點擊預置場景按鈕或重新輸入腳本詞，確保落到 `assets/demo_data/` 中的穩定響應。
- 如果匹配停留過久：使用默認 demo matching 入口重新進入，避免切到真實匹配頁。
- 如果 SOS 聯繫人爲空：說明當前仍會演示志願者廣播；聯繫人可在“我的 > 緊急聯繫人”中補全，但不阻塞 Demo。
