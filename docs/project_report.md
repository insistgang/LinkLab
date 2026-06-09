# 共感 LinkAble 項目完整報告

> 掃描日期：2026-05-26  
> 掃描範圍：`E:\vscode_project\LinkLab` 整個 workspace

---

## 一、項目基本信息

| 屬性 | 值 |
|---|---|
| **項目名稱** | 共感 LinkAble |
| **項目類型** | Flutter / Dart 移動應用 |
| **版本** | 1.0.0+1 |
| **Dart SDK** | ^3.11.4 |
| **項目定位** | AI + 志願者無障礙互助平臺（面向視障、聽障、老年人及肢體障礙者） |
| **競賽** | 2026 兩岸大學生創客大賽 · 逢甲賽區 |
| **當前狀態** | Demo-first MVP，競賽主線可跑通 |

---

## 二、目錄結構總覽

```
LinkLab/
├─ linklab/                          # 主 Flutter 應用
│  ├─ lib/                           # Dart 源碼（289 個文件，~68,343 行手寫代碼）
│  │  ├─ config/                     # 配置（AppConfig, ApiConfig）
│  │  ├─ core/                       # 核心基礎設施（常量、主題、日誌）
│  │  ├─ models/                     # 數據模型（32 源文件，3,527 行）
│  │  ├─ providers/                  # Riverpod 狀態管理（14 文件，1,935 行）
│  │  ├─ services/                   # 業務服務層（22+ 文件）
│  │  │  ├─ facades/                 # ★ 統一 Facade（5 個門面）
│  │  │  ├─ demo/                    # Demo 實現（默認）
│  │  │  ├─ experimental/            # 實驗性真實實現（隔離）
│  │  │  ├─ webrtc/ asr/ tts/ vision/ # 子能力
│  │  │  └─ security/ community/ user_center/
│  │  ├─ screens/                    # 頁面 UI（11 個子目錄）
│  │  ├─ widgets/                    # 組件（含 6 個無障礙組件）
│  │  ├─ demo_data/                  # 本地 Demo 數據（10 文件）
│  │  └─ demo_flow/                  # Demo 流程控制
│  ├─ test/                          # 測試（16 個文件，含 14 個閉環測試）
│  ├─ assets/                        # 資源（85 個 SVG 圖標、4 個 JSON）
│  └─ pubspec.yaml                   # 36 個核心依賴
│
├─ supabase/                         # 唯一 schema source of truth
│  ├─ migrations/                    # 6 個 SQL 遷移文件
│  ├─ functions/                     # 4 個 Edge Functions
│  └─ docs/                          # 數據庫文檔
│
├─ docs/                             # 項目文檔（6 個）
├─ AGENTS.md                         # 工程實施準則（最高優先級）
├─ DEMO_STATUS.md / TODO.md / DEMO_SCRIPT.md
└─ 共感LinkAble_PRD_v1_2.md         # PRD
```

---

## 三、技術架構

### 3.1 分層架構

```
┌─────────────────────────────────────────────────────┐
│                  UI 層 (screens/)                     │
│   home → ai_chat → matching → call → sos → profile   │
├─────────────────────────────────────────────────────┤
│              狀態管理層 (providers/Riverpod)           │
│   appSession → demoFlow → matchingFlow → callFlow    │
├─────────────────────────────────────────────────────┤
│            Facade 統一入口層 (services/facades/)      │
│   AgentServiceFacade → VolunteerMatchingFacade       │
│   CallSessionFacade → SosFacade → LocationFacade     │
├─────────────────────────────────────────────────────┤
│               服務實現層 (services/)                   │
│   ┌──────────┐  ┌───────────┐  ┌──────────────┐     │
│   │  demo/   │  │experimental│  │security/tts/ │     │
│   │ (默認)   │  │  /real/    │  │asr/vision/   │     │
│   └──────────┘  └───────────┘  └──────────────┘     │
├─────────────────────────────────────────────────────┤
│             數據層 (models/ + demo_data/)              │
│   AgentInput → AgentResult → HelpRequest → UserModel │
└─────────────────────────────────────────────────────┘
```

### 3.2 核心依賴

| 類別 | 包 | 用途 |
|---|---|---|
| 狀態管理 | flutter_riverpod ^2.6.1 | 全局 Riverpod |
| 後端 | supabase_flutter ^2.8.4 | Supabase 集成 |
| 通話 | flutter_webrtc ^0.12.12 | WebRTC |
| 語音 | flutter_tts + speech_to_text | TTS/ASR |
| 圖像 | image_picker + camera | OCR/拍照 |
| 推送 | firebase_messaging | 推送通知 |
| 位置 | geolocator | 定位 |
| 序列化 | freezed + json_serializable | 不可變數據類 |

### 3.3 狀態管理

- 全局 `ProviderScope(child: LinkLabApp())` 已正確注入
- 核心流程使用 `NotifierProvider` 管理狀態機
- 6 個核心 Provider：AppSession、DemoFlow、MatchingFlow、CallFlow、HelpRequestFlow、Community

---

## 四、MVP 六大核心功能實現狀態

| ID | 功能 | 狀態 | 關鍵文件 | 代碼量 | 主要問題 |
|---|---|---|---|---|---|
| **F1** | AI Agent 智能對話 | ✅ 已實現 | `agent_service_facade.dart` (736行), `demo_ai_chat_screen.dart` (1075行) | ~3,500行 | 舊 singleton 未清理、LLM 無上下文記憶 |
| **F9** | 志願者匹配引擎 | ✅ 已實現 | `volunteer_matching_facade.dart`, `demo_matching_screen.dart` (948行) | ~2,200行 | **評分函數是簡化版**（固定分數），未實現 5 維評分公式 |
| **F11** | 實時語音通話 | ✅ 已實現 | `call_session_facade.dart`, `demo_call_screen.dart` (917行) | ~3,500行 | ChangeNotifier 違規、DemoCallService 職責過重 |
| **F13** | SOS 緊急呼救 | ✅ 已實現 | `sos_facade.dart`, `demo_sos_screen.dart` (1074行) | ~1,800行 | ChangeNotifier 違規、真實 SMS 未接入 |
| **F33** | 登錄與偏好 | ✅ 已實現 | `preference_screen.dart` (550行), 8 個 auth 頁面 | ~2,500行 | 缺 `SessionFacade`、真實短信未接入 |
| **F36** | 全局無障礙 | ⚠️ 部分實現 | 6 個 accessible 組件 (1,214行) | ~1,200行 | 跨頁面覆蓋不均勻、對比度未系統驗證 |

### Facade 完成度

| Facade | 狀態 |
|---|---|
| `AgentServiceFacade` | ✅ 已創建 (736行) |
| `VolunteerMatchingFacade` | ✅ 已創建 (189行) |
| `CallSessionFacade` | ✅ 已創建 (120行) |
| `SosFacade` | ✅ 已創建 (125行) |
| `LocationFacade` | ✅ 已創建 |
| `SessionFacade` | ❌ 未創建 |
| `AccessibilityPrefsFacade` | ❌ 未創建 |

---

## 五、數據庫 Schema（Supabase）

### 核心表（11 張）

| 表名 | 用途 |
|---|---|
| `users` | 用戶基礎表（phone, name, role, disability_type, preferences） |
| `volunteer_profiles` | 志願者擴展（skills, level, points, credit_score, is_online, location PostGIS） |
| `help_requests` | 求助記錄（8 態狀態機） |
| `emergency_contacts` | 緊急聯繫人 |
| `virtual_identities` | 虛擬身份映射 |
| `call_records` | 通話記錄 |
| `reports` | 舉報 |
| `point_transactions` | 積分流水 |
| `ai_response_cache` | AI 響應緩存 |
| `async_tasks` | 異步任務 |
| `help_request_logs` | 狀態變更日誌 |

### `help_requests` 狀態機

```
created → ai_processing → ai_resolved          (終態)
                      ↘ matching → connected → completed (終態)
                                     ↕ (掉線重連)
                                  → expired    (終態)
                                  → cancelled  (終態)
```

共 8 個狀態：`created`, `ai_processing`, `ai_resolved`, `matching`, `connected`, `completed`, `cancelled`, `expired`

### Edge Functions（4 個）

| 函數 | 用途 |
|---|---|
| `matching-engine` | 志願者匹配引擎 |
| `ai-dispatcher` | AI 意圖分發 |
| `push-notifier` | 推送通知（無 FCM key 時自動 mock） |
| `points-calculator` | 積分計算 |

### 關鍵函數

- `find_matching_volunteers(lat, lng, max_dist, skills, limit)` — PostGIS 地理匹配
- `calculate_distance(lat1, lng1, lat2, lng2)` — Haversine 距離計算
- `calculate_volunteer_level(points)` — 積分 → 等級映射（1-7 級）

---

## 六、測試覆蓋

| 測試文件 | 對應功能 |
|---|---|
| `widget_test.dart` | F33, F36 — 初始化、FeatureFlags、200% 字體、讀屏語義 |
| `startup_login_closed_loop_test.dart` | F33 — 啓動 → 登錄 → 首頁 |
| `ai_to_human_closed_loop_test.dart` | F1 — AI 低信心 → 轉人工 |
| `matching_call_rating_closed_loop_test.dart` | F9, F11 — 匹配 → 通話 → 評價 |
| `sos_closed_loop_test.dart` | F13 — SOS 觸發 → 撤銷 → 廣播 → 聯繫人通知 |
| `demo_mainline_end_to_end_test.dart` | 全鏈路 — 3 分鐘 Demo 主線 E2E |
| `help_request_state_machine_test.dart` | F1/F9 — 狀態機 8 態轉移驗證 |
| `demo_data_fallback_test.dart` | 全局 — 無 API 時本地數據 fallback |
| `theme_toggle_live_update_test.dart` | F36 — 主題切換實時更新 |
| `demo_call_flow_test.dart` | F11 — 通話流程 |
| `demo_call_screen_test.dart` | F11 — 通話頁面 |
| `demo_matching_screen_test.dart` | F9 — 匹配頁面 |
| `demo_matching_service_test.dart` | F9 — 匹配服務 |
| `seeker_center_scope_test.dart` | 求助者視角作用域 |
| `real_database_repository_test.dart` | RealMode 基礎 |
| `test_harness.dart` | 測試基礎設施 |

**合計**：16 個測試文件，6 個 MVP 功能全覆蓋

---

## 七、資源文件

| 類別 | 狀態 | 說明 |
|---|---|---|
| Brand SVG | ✅ 完整 | `logo.svg` + `link_hand.svg` |
| Demo Data JSON | ✅ 完整 | 4 個 JSON（志願者、AI 響應、場景） |
| Icon SVG | ✅ 完整 | 85 個圖標覆蓋所有 MVP 意圖 |
| Fonts | ⚠️ 佔位 | `placeholder.txt`，未打包自定義字體 |
| Avatar Images | ⚠️ 佔位 | 使用文字頭像 fallback |
| Sounds | ❌ 空 | 目錄存在但無文件 |

---

## 八、環境配置與 FeatureFlags

### 默認狀態（競賽 Demo）

所有 FeatureFlags 默認 **關閉**，確保 Demo 主線不依賴外部服務：

| 開關 | 默認 | 說明 |
|---|---|---|
| `enableSupabaseAuth` | false | 不依賴真實 Supabase |
| `enableWebRTC` | false | 走 Demo Call |
| `enableRealMatching` | false | 走 Demo 匹配 |
| `enableRealAI` | false | 走本地 Demo 響應 |
| `enablePushNotification` | false | 不依賴 Firebase |
| `enableRealSMS` | false | 不依賴短信服務 |
| `enableDatabaseSync` | false | 不同步數據庫 |
| `enableLocationService` | false | 不啓用真實定位 |
| `enableCommunity` | false | 不開放交互式社區 |
| `enablePoints` | false | 安心積分已砍 |
| `enableBadges` | false | 徽章已砍 |
| `enableSchedule` | false | 排班已砍 |
| `enableAdminDashboard` | false | 後臺入口關閉 |
| `enableCallRecording` | false | 通話錄音延後 |

### 密鑰管理

- `api_config.dart` 已通過 `.gitignore` 雙重忽略，不入版本控制
- `api_config.example.dart` 作爲唯一入庫模板
- 倉庫中只保留佔位值或公開服務端點，無真實密鑰

---

## 九、代碼規模統計

| 維度 | 數量 |
|---|---|
| Dart 源文件（lib/） | 289 個 |
| 手寫代碼行數 | ~68,343 行 |
| 生成代碼（.freezed.dart + .g.dart） | 34 個，~19,711 行 |
| 測試文件 | 16 個 |
| SQL 遷移文件 | 6 個 |
| Edge Functions | 4 個 |
| SVG 圖標 | 85 個 |
| 核心依賴包 | 36 個 |
| Facade 服務 | 5 個 |

---

## 十、技術債務與風險

### P0 級（影響架構合規）

| 問題 | 位置 | 說明 |
|---|---|---|
| 舊 singleton 未清理 | `services/ai_service.dart` (394行) | `AIServiceManager` 違反 AGENTS.md 禁止新增 singleton |
| ChangeNotifier 違規 | `DemoCallService`, `DemoSOSService` | AGENTS.md 要求全局 Riverpod |
| 缺 `SessionFacade` | — | AGENTS.md §12.2 要求的 6 個 facade 缺 2 個 |
| 缺 `AccessibilityPrefsFacade` | — | 同上 |
| 評分函數簡化 | `VolunteerMatchingFacade` | 返回固定分數，未實現 5 維評分公式 |

### P1 級（影響演示質量）

| 問題 | 說明 |
|---|---|
| LLM 無上下文記憶 | `_chatWithLLM` 沒有 history 傳遞 |
| 真實 SMS 未接入 | RealMode 下提示"暫未接入" |
| 跨頁面 Semantics 不均勻 | 部分頁面僅 1 處 Semantics |
| 對比度 >= 7:1 未系統驗證 | 無自動檢測 |
| RealMode Phase-3 Schema 分叉 | `profiles` 表與 `users` 表並行 |

### P2 級（交付前收尾）

| 問題 | 說明 |
|---|---|
| flutter analyze 殘留 | 歷史記錄 70 個 lint issues |
| 字體/頭像/音效資源缺失 | 通過 fallback 機制不影響 Demo |
| 歷史驗證未復跑 | 需重新執行 `flutter test` + `flutter build web --release` |

---

## 十一、AI 能力鏈路

```
AgentServiceFacade.processInput()
  ├─ 有圖片 → _processImageInput()
  │   ├─ 智譜 GLM-4-vision 可用 → _visionWithLLM() (多模態)
  │   └─ 降級 → 關鍵詞路由
  │       ├─ 藥品 → checkMedicine() → VisionService / DemoAIService
  │       ├─ 顏色 → recognizeColor()
  │       ├─ 鈔票 → recognizeMoney()
  │       ├─ 文字 → recognizeText() → BaiduOCR / DemoAIService
  │       ├─ 物體 → identifyObject()
  │       └─ 默認 → describeScene()
  │
  └─ 純文本 → _chatWithLLM() (智譜 GLM-4-flash)
      └─ 失敗 → DemoAIService.process()
```

降級鏈：智譜 GLM-4 → 百度 OCR → 本地 Demo 響應，確保無 API Key 時仍可演示。

---

## 十二、頁面導航流

```
啓動 → app.dart _buildInitialScreen()
  ├─ 未初始化 → CircularProgressIndicator
  ├─ 已登錄 → MainScreen (底部導航)
  │   ├─ Landing: HomeScreen (選擇 求助者/志願者)
  │   ├─ Seeker模式:
  │   │   ├─ Tab 0: SeekerHomeScreen
  │   │   ├─ Tab 1: DemoAIChatScreen        ← F1
  │   │   ├─ Tab 2: CommunityScreen
  │   │   └─ Tab 3: ProfileScreen
  │   └─ Volunteer模式:
  │       ├─ Tab 0: PendingHelpScreen
  │       ├─ Tab 1: DemoAIChatScreen
  │       ├─ Tab 2: CommunityScreen
  │       └─ Tab 3: ProfileScreen
  │
  └─ Demo 主線流程 (DemoFlowNavigator):
      HomeScreen "我需要幫助" → DemoAIChatScreen (F1)
        → [AI無法處理] → DemoMatchingScreen (F9)
          → [匹配成功] → DemoCallScreen (F11)
            → [通話結束] → DemoCallRatingScreen
      HomeScreen 長按 → DemoSOSScreen (F13)
```

---

## 十三、總結

**共感 LinkAble 是一個架構清晰、MVP 主線完整的 Flutter 無障礙互助平臺。** 核心亮點：

1. **Demo-first 雙軌架構**：所有能力都有 Demo/Real 兩套實現，競賽版默認走 Demo 主線，不依賴外部服務
2. **Facade 統一入口**：5/7 個 Facade 已創建，UI 層不直接依賴底層實現
3. **嚴格狀態機**：`HelpRequestStatus` 的 8 個狀態及轉移規則被編碼爲枚舉方法
4. **無障礙優先**：獨立 accessible 組件庫，75 處 Semantics 調用
5. **完整測試覆蓋**：14 個閉環測試覆蓋全部 6 個 MVP 功能
6. **AI 能力降級鏈**：智譜 GLM-4 → 百度 OCR → 本地 Demo，確保無 key 可演示

**主要差距**：評分函數簡化、2 個 Facade 缺失、舊 singleton/ChangeNotifier 違規、跨頁面無障礙覆蓋不均勻。這些是下一步優化的重點方向。

---

## 附錄：推薦閱讀順序

1. `AGENTS.md` — 工程實施準則（最高優先級）
2. `DEMO_STATUS.md` — 當前演示狀態
3. `TODO.md` — 待辦事項
4. `DEMO_SCRIPT.md` — 演示腳本
5. `linklab/lib/main.dart` — 應用入口
6. `linklab/lib/config/app_config.dart` — 配置文件
7. `linklab/lib/services/facades/agent_service_facade.dart` — AI 核心 Facade
8. `supabase/migrations/` — 數據庫 schema
