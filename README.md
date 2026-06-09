# 共感 LinkAble

**AI + 志願者無障礙互助平臺**

面向視障、聽障、老年人及肢體障礙者的「AI 先處理 + 真人兜底」互助 Demo。

> 2026 兩岸大學生創客大賽 · 逢甲賽區競賽交付版本  
> 當前倉庫狀態：**Demo-first MVP** / **Web 與 Chrome 是主要演示路徑** / **真實 WebRTC、Supabase、推送、SOS 生產鏈路仍爲實驗或後續能力**

> 最新狀態索引見 [DEMO_STATUS.md](./DEMO_STATUS.md)。本輪文檔整理不運行 Flutter，也不把歷史測試記錄重新聲明爲當前複驗結果。

## 項目定位

共感 LinkAble 的目標不是做“功能很多但都半成品”的助殘應用，而是把競賽版嚴格收口爲一條能穩定演示、可重複驗證、對無障礙用戶真正友好的 MVP 主線：

- AI 優先處理標準化需求
- 真人志願者兜底複雜和高風險需求
- 所有主流程都具備可見狀態變化與結束落點
- 所有演示鏈路默認不依賴外部不可控服務

當前版本嚴格遵循根目錄 [AGENTS.md](./AGENTS.md) 作爲唯一技術實施事實來源。

## MVP 6 大核心功能

| 功能 | 描述 | 對應範圍 |
|---|---|---|
| **F1 AI Agent 智能對話** | 語音 / 文字 / 拍照統一入口，處理 OCR、場景描述、顏色識別、翻譯、緊急詞檢測等 | MVP 核心 |
| **F9 志願者匹配** | AI 無法解決時，進入 Demo 匹配流程並展示明確的狀態變化 | MVP 核心 |
| **F11 實時語音通話** | 匹配成功後進入語音通話閉環；競賽版默認走 Demo 通話 | MVP 核心 |
| **F13 SOS 緊急呼救** | 一鍵觸發、10 秒誤觸撤銷窗口、Mock 廣播和聯繫人通知 | MVP 核心 |
| **F33 登錄與無障礙偏好** | 手機號驗證碼登錄、首次引導、偏好恢復 | MVP 核心 |
| **F36 全局無障礙** | `Semantics`、高對比度、48x48 觸摸目標、動態字體、錯誤三重表達 | 強制約束 |

一句話總結：**AI 處理 80% 標準化需求，志願者兜底 20% 複雜 / 緊急需求。**

## 當前交付狀態

截至 `2026-04-17` 的歷史執行記錄顯示，倉庫曾完成 `P0 + P1 + P2` 收口工作；`2026-05-01` 文檔口徑整理後，統一將當前項目標註爲 Demo-first MVP：

- 競賽版入口已強制鎖定 `Demo Mode`
- 全局已補齊 `ProviderScope`
- 默認導航只保留 `Home / AIChat / Profile`
- 社區 / 社羣 / 複雜後臺能力已降級或移出默認主鏈路
- Supabase 以根目錄 `supabase/` 爲唯一 schema source of truth
- `real_*` 真實鏈路已隔離到 `services/experimental/real/`
- 5 條關鍵 Demo 閉環測試已補齊並通過
- 日誌已統一收口到 `AppLogger`
- `api_config.dart` 已停止 Git 追蹤，改爲本地實驗配置

## 快速啓動

### 1. 運行主應用 Demo（首選 Web / Chrome）

```bash
cd linklab
flutter pub get
flutter run -d chrome
```

說明：

- 當前入口在 [`linklab/lib/main.dart`](./linklab/lib/main.dart) 中已強制執行 `AppConfig.demoMode = true`
- 默認不需要真實 API Key、真實 Supabase、真實推送或真實 WebRTC
- 競賽版默認只保證 Demo 主線
- Windows 桌面端不是首選演示路徑；如需 `flutter run -d windows`，本機必須安裝 Visual Studio C++ 桌面開發工具鏈

### 2. Web 構建複驗

```bash
cd linklab
flutter build web --release
```

說明：Web build 是推薦交付複驗口徑之一。本輪文檔整理未運行該命令，交付前應重新執行並把結果補入 [`docs/rc_acceptance_evidence.md`](./docs/rc_acceptance_evidence.md)。

### 3. 運行閉環測試

```bash
cd linklab
flutter test --tags demo
```

### 4. 運行靜態檢查

```bash
cd linklab
flutter analyze lib
```

```bash
cd linklab/admin_dashboard
flutter analyze lib
```

已有驗證記錄口徑：

- `README.md` / `TODO.md` 的 2026-04-17 歷史記錄曾寫明：主應用 `flutter analyze lib` 仍有 `70 issues found`，`admin_dashboard` 有 `9 issues found`，`flutter test --tags demo` 爲 **All tests passed**。
- [`docs/rc_acceptance_evidence.md`](./docs/rc_acceptance_evidence.md) 的較新 RC 記錄曾寫明：`flutter analyze` 爲 `No issues found`，`flutter test --reporter compact` 爲 `All tests passed`（60 tests）。
- [`docs/competition_mvp_delivery_plan.md`](./docs/competition_mvp_delivery_plan.md) 將 `flutter build web --debug` / `flutter build web --release` 納入 Web 演示驗收口徑。
- 本輪僅整理文檔，沒有復跑 `flutter test`、`flutter analyze` 或 `flutter build web`；交付前以 Web / Chrome 路徑重新複驗爲準。

## 3 分鐘競賽演示主線

當前默認演示閉環爲：

1. 打開 App，進入首頁大按鈕主界面
2. 語音或文字發起 AI 求助
3. AI 能處理時直接返回答案
4. AI 無法處理時進入志願者匹配頁
5. 匹配成功後進入 Demo 通話
6. 通話結束後提交評價並回寫歷史
7. 演示 SOS：廣播、聯繫人通知、10 秒撤銷窗口

對應倉內文檔可參考：

- [DEMO_SCRIPT.md](./DEMO_SCRIPT.md)
- [TODO.md](./TODO.md)
- [AGENTS.md](./AGENTS.md)

## 倉庫結構

```text
LinkLab/
├─ linklab/                  # 主 Flutter 應用（競賽 MVP 主交付）
│  ├─ lib/
│  │  ├─ config/             # Demo / 網絡 / API 配置
│  │  ├─ core/               # 主題、常量、日誌等基礎設施
│  │  ├─ demo_data/          # 本地演示數據
│  │  ├─ demo_flow/          # Demo 狀態流與閉環追蹤
│  │  ├─ models/             # 核心數據模型
│  │  ├─ providers/          # Riverpod provider
│  │  ├─ screens/            # 頁面
│  │  ├─ services/           # 業務服務與 unified facade
│  │  └─ widgets/            # 無障礙組件與通用 UI
│  └─ test/closed_loop/      # 5 條關鍵閉環測試
├─ supabase/                 # 唯一 schema source of truth
│  ├─ migrations/
│  └─ functions/
├─ docs/                     # 說明文檔
├─ prd-analysis/             # PRD / 分析輔助材料
├─ 共感LinkAble_PRD_v1_2.md
├─ 項目深度分析報告.md
├─ AGENTS.md
└─ TODO.md
```

補充說明：

- `linklab/admin_dashboard/` 保留爲歷史後臺工程，不屬於競賽 MVP 主交付
- `linklab/lib/services/experimental/real/` 爲實驗性真實鏈路，默認不進入導航和演示腳本
- `linklab/supabase/legacy/` 爲歷史歸檔，後續不得再作爲事實來源

## 技術棧

### 主應用

- Flutter
- Riverpod
- Supabase Flutter
- WebRTC
- Firebase Messaging
- Shared Preferences
- Geolocator
- Flutter TTS / Speech To Text
- Logger

### 數據與後端

- Supabase Postgres
- Supabase Edge Functions
- 根目錄 `supabase/migrations/` 統一管理 schema

### 工程質量

- `flutter analyze`
- `flutter test --tags demo`
- `AppLogger` 統一日誌
- Demo-first fallback 策略

## Demo / Real 邊界

當前項目採用明確的雙軌策略，但**競賽版只保留 Demo 主線**：

- 默認導航、默認首頁、默認測試只走 Demo 主線
- `unified_*` 服務默認強制走 Demo 分支
- 真實鏈路僅保留在 `services/experimental/real/`
- 如果真實依賴未初始化、缺失或不穩定，必須自動回退到 Demo 數據

這意味着：

- 你可以穩定演示 `F1 -> F9 -> F11 -> 評價 -> 歷史`
- 你也可以穩定演示 `F13 SOS`
- 但不應該把真實 WebRTC、真實 Supabase、真實推送、真實短信、真實報警或生產級 SOS 當作現場依賴
- 真實鏈路只能作爲實驗能力或後續版本說明，不能在文檔、口播或驗收中冒充當前已生產完成

## 無障礙約束

當前版本不是“先做功能、最後補無障礙”，而是將無障礙作爲強制實施基線：

- 交互元素需要 `Semantics`
- 觸摸目標儘量接近或達到 `48x48dp`
- 高對比度優先於視覺裝飾
- 支持字體縮放和讀屏
- 錯誤狀態必須使用顏色 + 圖標 + 文字三重表達
- 圖片必須有可理解的替代文本或回退組件

倉內可以關注這些實現：

- [`linklab/lib/widgets/accessible/`](./linklab/lib/widgets/accessible)
- [`linklab/lib/widgets/accessible/accessible_image.dart`](./linklab/lib/widgets/accessible/accessible_image.dart)

## 測試覆蓋

當前已補齊 5 條關鍵閉環測試，位於 [`linklab/test/closed_loop/`](./linklab/test/closed_loop)：

- `startup_login_closed_loop_test.dart`
- `ai_to_human_closed_loop_test.dart`
- `matching_call_rating_closed_loop_test.dart`
- `sos_closed_loop_test.dart`
- `demo_mainline_end_to_end_test.dart`

這些測試覆蓋的核心目標包括：

- `AppSessionService` 初始化與偏好恢復
- AI 無法處理時轉人工
- `help_request` 狀態機從 `ai_processing -> matching -> connected -> completed`
- SOS 的 `created -> cancelled / matching`
- 首頁到歷史回看的完整 Demo 主線

## 配置與密鑰管理

### Demo 運行

競賽版 Demo 運行默認**不需要**真實密鑰。

### 本地實驗真實鏈路

如果你只是本地實驗真實 AI 配置：

1. 參考 [`linklab/lib/config/api_config.example.dart`](./linklab/lib/config/api_config.example.dart)
2. 複製生成本地 `linklab/lib/config/api_config.dart`
3. 填入自己的實驗配置
4. **不要提交該文件**

倉庫已經通過 `.gitignore` 忽略：

- `linklab/lib/config/api_config.dart`

### Supabase 規則

- 根目錄 [`supabase/`](./supabase) 是唯一 schema source of truth
- 任何字段 / 表結構調整都應先改 migration，再改客戶端代碼
- 競賽版主流程默認不依賴真實 Supabase 初始化

## 非 MVP 範圍說明

以下內容當前不屬於競賽默認交付主線：

- 交互式社區 / 羣聊 / 地區社羣
- 多級認證和複雜審覈
- 積分、徽章、排班、時間線
- 錄音 AI 檢測
- 獨立運營後臺能力
- 真實 WebRTC / 真實推送 / 真實匹配的生產級可用性

這些代碼可能仍保留在倉庫中，但已經被隱藏、隔離或降級，不應進入默認演示流程。

## 推薦閱讀順序

如果你第一次接手這個項目，建議按下面順序閱讀：

1. [DEMO_STATUS.md](./DEMO_STATUS.md)
2. [AGENTS.md](./AGENTS.md)
3. [TODO.md](./TODO.md)
4. [DEMO_SCRIPT.md](./DEMO_SCRIPT.md)
5. [`linklab/lib/main.dart`](./linklab/lib/main.dart)
6. [`linklab/lib/config/app_config.dart`](./linklab/lib/config/app_config.dart)
7. [`supabase/migrations/005_unify_root_schema_source_of_truth.sql`](./supabase/migrations/005_unify_root_schema_source_of_truth.sql)

## 一句話總結

**共感 LinkAble 當前不是“全功能平臺原型”，而是一條嚴格收口、無障礙優先、可穩定演示的 AI + 志願者協助 MVP 主線。**
