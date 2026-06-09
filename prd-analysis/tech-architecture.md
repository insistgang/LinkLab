# 共感 LinkAble 技術架構分析報告

> **分析範圍**：PRD 第四章至第七章  
> **生成日期**：2026-04-10  
> **版本**：v1.0

---

## 目錄

- [1. 技術棧梳理](#1-技術棧梳理)
- [2. 數據庫設計評審](#2-數據庫設計評審)
- [3. 開發里程碑](#3-開發里程碑)
- [4. 性能指標與技術方案對應](#4-性能指標與技術方案對應)
- [5. 第三方服務成本明細](#5-第三方服務成本明細)
- [6. 風險與應對](#6-風險與應對)
- [7. 總結與建議](#7-總結與建議)

---

## 1. 技術棧梳理

### 1.1 整體架構圖

```text
┌─────────────────────────────────────────────────────────────┐
│                      客戶端層 (Flutter)                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │   無障礙UI    │ │   語音交互    │ │     相機模塊          │ │
│  │  - Semantics │ │  - ASR/TTS   │ │   - OCR/識別/顏色    │ │
│  │  - 高對比度   │ │  - 語音喚醒   │ │   - 多模態輸入       │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │  WebRTC通話   │ │  狀態管理     │ │     本地AI推理       │ │
│  │  - P2P語音   │ │  - Riverpod  │ │   - PaddleOCR Lite   │ │
│  │  - 視頻/屏幕  │ │  - 類型安全   │ │   - 顏色識別         │ │
│  └──────┬───────┘ └──────────────┘ └──────────────────────┘ │
└─────────┼───────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                     BaaS層 (Supabase)                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │    Auth      │ │   Database   │ │      Realtime        │ │
│  │  - 手機號    │ │ - PostgreSQL │ │    - WebSocket       │ │
│  │  - 微信登錄  │ │ - RLS策略    │ │    - 信令通道        │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
│  ┌──────────────┐ ┌────────────────────────────────────────┐ │
│  │   Storage    │ │        Edge Functions (Deno)           │ │
│  │  - 文件存儲  │ │  - 匹配算法 / 積分計算 / 推送觸發      │ │
│  │  - 錄音存儲  │ │  - AI調度 / 緊急檢測                   │ │
│  └──────────────┘ └────────────────────────────────────────┘ │
└──────────────────────────────┬──────────────────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│    AI服務層      │  │    地圖服務      │  │    推送服務      │
│  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │
│  │  百度OCR   │  │  │  │  高德地圖  │  │  │ │    FCM    │  │
│  │ PaddleOCR │  │  │  │  - 定位   │  │  │ │ 廠商SDK   │  │
│  └───────────┘  │  │  │  - 導航   │  │  │ │ 華爲/小米 │  │
│  ┌───────────┐  │  │  └───────────┘  │  │ │ OPPO/vivo │  │
│  │ 科大訊飛   │  │  └─────────────────┘  │ └───────────┘  │
│  │ ASR + TTS │  │                       └─────────────────┘
│  └───────────┘  │
│  ┌───────────┐  │
│  │ 通義千問VL │  │
│  │Kimi Vision│  │
│  └───────────┘  │
└─────────────────┘
```

### 1.2 技術選型明細表

| 層級 | 技術 | 版本/方案 | 選型理由 | 風險點 |
|------|------|-----------|----------|--------|
| **前端框架** | Flutter | 3.x + Dart | 跨平臺(iOS/Android)，內置Semantics無障礙支持，熱重載開發效率高 | 包體積較大，需優化 |
| **狀態管理** | Riverpod | 2.x | 類型安全，編譯時錯誤檢測，適合複雜狀態 | 學習曲線較陡 |
| **後端BaaS** | Supabase | Cloud/自託管 | PostgreSQL+Auth+Realtime+Storage一體，降低後端開發成本 | 國內訪問需CDN加速 |
| **實時通信** | WebRTC | flutter_webrtc | P2P直連低延遲，Supabase Realtime做信令 | NAT穿透需TURN服務器 |
| **地圖服務** | 高德地圖 | Flutter插件 | 中國合規，室內定位+步行導航完善 | 僅中國可用 |
| **OCR在線** | 百度OCR | REST API | 中文識別率高，免費額度5萬次/月 | 離線不可用 |
| **OCR離線** | PaddleOCR | Lite本地模型 | 無網絡可用，保護隱私 | 精度略低於在線 |
| **語音ASR/TTS** | 科大訊飛 | 流式API | 中文識別最優，支持方言 | 費用較高 |
| **視覺理解** | 通義千問VL | API | 多模態場景描述能力強 | Token費用需控制 |
| **視覺備選** | Kimi Vision | API | 備選方案，防止單點故障 | 同上 |
| **推送服務** | FCM + 廠商SDK | 華爲/小米/OPPO/vivo | FCM免費，國內必須走廠商通道 | 集成複雜度高 |

### 1.3 無障礙技術方案

| 需求 | 技術實現 | 優先級 |
|------|----------|--------|
| 屏幕閱讀器支持 | Flutter Semantics + TalkBack/VoiceOver | P0 |
| 高對比度 | WCAG 2.1 AAA標準 (≥7:1) | P0 |
| 觸摸目標 | ≥48×48 dp | P0 |
| 動態字體 | 支持系統級字體縮放 | P0 |
| 語音喚醒 | "Hey 智動"喚醒詞檢測 | P0 |
| 緊急快捷 | 連按電源鍵3次觸發SOS | P0 |
| 焦點順序 | 邏輯一致的Tab順序 | P0 |
| 錯誤提示 | 顏色+圖標+文字三重提示 | P0 |

---

## 2. 數據庫設計評審

### 2.1 核心表結構分析

```text
┌─────────────────────────────────────────────────────────────────┐
│                        數據庫關係圖                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────┐         ┌──────────────────┐                 │
│   │    users    │◄────────┤ volunteer_profiles│                 │
│   │  (用戶基礎)  │   1:1   │   (志願者擴展)    │                 │
│   └──────┬──────┘         └──────────────────┘                 │
│          │                                                      │
│          │ 1:N                                                  │
│          ▼                                                      │
│   ┌─────────────┐         ┌──────────────────┐                 │
│   │help_requests│◄────────┤   async_tasks    │                 │
│   │  (求助記錄)  │         │   (異步任務)      │                 │
│   └──────┬──────┘         └──────────────────┘                 │
│          │                                                      │
│          │ 1:N                                                  │
│          ▼                                                      │
│   ┌─────────────────┐    ┌──────────────────┐                  │
│   │point_transactions │   │     reports      │                  │
│   │    (積分流水)    │    │     (舉報)       │                  │
│   └─────────────────┘    └──────────────────┘                  │
│                                                                 │
│   ┌─────────────────────────────────────────┐                  │
│   │        emergency_contacts               │                  │
│   │           (緊急聯繫人)                   │                  │
│   └─────────────────────────────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 表結構詳細設計

#### users (用戶基礎表)
```sql
users (
  id UUID PK,
  phone TEXT UNIQUE,          -- 手機號登錄
  name TEXT,                  -- 暱稱
  avatar_url TEXT,            -- 頭像URL
  role TEXT[],                -- ['seeker', 'volunteer'] 可雙角色
  disability_type TEXT[],     -- ['visual', 'hearing', 'physical', 'elderly', 'temporary']
  preferences JSONB,          -- 無障礙偏好配置
  created_at TIMESTAMPTZ
)
```
**評審意見**：
- ✅ role使用數組支持雙角色場景
- ✅ preferences用JSONB支持靈活配置
- ⚠️ 建議添加 `last_login_at` 字段用於活躍度分析
- ⚠️ 建議添加 `is_deleted` 軟刪除標記

#### volunteer_profiles (志願者擴展表)
```sql
volunteer_profiles (
  user_id UUID FK → users,
  skills TEXT[],              -- 技能標籤數組
  level INT DEFAULT 1,        -- 等級 1-7
  points INT DEFAULT 0,       -- 積分
  credit_score DECIMAL DEFAULT 5.0,  -- 信用分 1-5
  is_verified BOOLEAN DEFAULT FALSE, -- 實名認證
  available_schedule JSONB,   -- 排班配置
  is_online BOOLEAN DEFAULT FALSE,   -- 在線狀態
  location GEOGRAPHY(POINT)   -- PostGIS地理座標
)
```
**評審意見**：
- ✅ 使用PostGIS支持地理查詢
- ✅ JSONB存儲排班靈活可擴展
- ⚠️ `is_online` 需配合心跳機制，建議增加 `last_heartbeat_at`
- ⚠️ 建議添加 `total_help_count` 累計幫助次數，避免實時計算

#### help_requests (求助記錄表)
```sql
help_requests (
  id UUID PK,
  seeker_id UUID FK → users,
  type TEXT,                  -- 'ai_auto', 'async', 'realtime_voice', 'realtime_video', 'sos'
  intent TEXT,                -- AI識別的意圖
  urgency TEXT,               -- 'normal', 'important', 'urgent', 'emergency'
  status TEXT,                -- 'pending', 'ai_resolved', 'matching', 'connected', 'completed', 'cancelled'
  ai_response JSONB,          -- AI處理結果緩存
  volunteer_id UUID FK → users,
  location GEOGRAPHY(POINT),
  duration_seconds INT,       -- 通話時長
  seeker_rating INT,          -- 1-5星評價
  volunteer_rating INT,
  created_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
)
```
**評審意見**：
- ✅ 狀態機設計完整
- ✅ JSONB存儲AI響應支持多模態結果
- ⚠️ 建議添加 `matched_at` 記錄匹配成功時間（用於計算匹配耗時KPI）
- ⚠️ 建議添加 `cancel_reason` 取消原因分析

### 2.3 索引建議

```sql
-- 用戶表索引
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users USING GIN(role);
CREATE INDEX idx_users_disability ON users USING GIN(disability_type);

-- 志願者表索引
CREATE INDEX idx_volunteer_location ON volunteer_profiles USING GIST(location);
CREATE INDEX idx_volunteer_online ON volunteer_profiles(is_online, is_verified);
CREATE INDEX idx_volunteer_skills ON volunteer_profiles USING GIN(skills);
CREATE INDEX idx_volunteer_credit ON volunteer_profiles(credit_score DESC);

-- 求助記錄表索引
CREATE INDEX idx_help_seeker ON help_requests(seeker_id, created_at DESC);
CREATE INDEX idx_help_volunteer ON help_requests(volunteer_id, created_at DESC);
CREATE INDEX idx_help_status ON help_requests(status, urgency);
CREATE INDEX idx_help_location ON help_requests USING GIST(location);
CREATE INDEX idx_help_created ON help_requests(created_at DESC);

-- 異步任務表索引
CREATE INDEX idx_async_status ON async_tasks(status, created_at);
CREATE INDEX idx_async_volunteer ON async_tasks(volunteer_id);

-- 積分流水錶索引
CREATE INDEX idx_points_user ON point_transactions(user_id, created_at DESC);
```

### 2.4 RLS (Row Level Security) 策略建議

```sql
-- 用戶只能查看自己的敏感信息
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_self_access ON users
  FOR ALL
  USING (auth.uid() = id);

-- 志願者位置僅匹配時可見
ALTER TABLE volunteer_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY volunteer_location_access ON volunteer_profiles
  FOR SELECT
  USING (
    auth.uid() = user_id OR 
    EXISTS (
      SELECT 1 FROM help_requests 
      WHERE volunteer_id = user_id 
      AND seeker_id = auth.uid()
      AND status IN ('matching', 'connected')
    )
  );
```

---

## 3. 開發里程碑

### 3.1 MVP 4周詳細計劃拆解

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MVP 開發時間線                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  W1: 項目搭建 + 基礎UI                                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ [Day 1-2] 項目初始化                                                  │   │
│  │  - Flutter項目搭建 + 目錄結構                                         │   │
│  │  - Supabase項目創建 + 數據庫初始化                                    │   │
│  │  - CI/CD配置 (GitHub Actions)                                         │   │
│  │                                                                       │   │
│  │ [Day 3-4] 認證模塊                                                    │   │
│  │  - 手機號+驗證碼登錄                                                  │   │
│  │  - 微信登錄集成                                                       │   │
│  │  - 首次引導流程 (身份/障礙/偏好)                                      │   │
│  │                                                                       │   │
│  │ [Day 5-7] 首頁框架 + 無障礙適配                                       │   │
│  │  - 底部導航 (4 Tab)                                                   │   │
│  │  - 超大按鈕組件                                                       │   │
│  │  - 全局Semantics適配                                                  │   │
│  │  - 高對比度主題                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  W2: AI Agent 核心                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ [Day 8-9] OCR文字識別                                                 │   │
│  │  - 相機拍照模塊                                                       │   │
│  │  - 百度OCR API集成                                                    │   │
│  │  - TTS朗讀結果                                                        │   │
│  │                                                                       │   │
│  │ [Day 10-11] 場景描述 (多模態)                                         │   │
│  │  - 通義千問VL API集成                                                 │   │
│  │  - 圖片上傳 + 結果解析                                                │   │
│  │                                                                       │   │
│  │ [Day 12] 顏色識別                                                     │   │
│  │  - 本地CV算法實現                                                     │   │
│  │  - 色盲友好描述                                                       │   │
│  │                                                                       │   │
│  │ [Day 13-14] 智能對話框架                                              │   │
│  │  - 意圖識別基礎                                                       │   │
│  │  - 多輪對話上下文                                                     │   │
│  │  - 緊急關鍵詞檢測                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  W3: 志願者匹配 + 通話                                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ [Day 15-16] 匹配算法 (簡化版)                                         │   │
│  │  - 在線志願者查詢                                                     │   │
│  │  - 基礎匹配分計算                                                     │   │
│  │  - Top 5推送邏輯                                                      │   │
│  │                                                                       │   │
│  │ [Day 17-18] WebRTC語音通話                                            │   │
│  │  - 信令服務器 (Supabase Realtime)                                     │   │
│  │  - P2P連接建立                                                        │   │
│  │  - 語音通話UI                                                         │   │
│  │                                                                       │   │
│  │ [Day 19-20] 推送通知                                                  │   │
│  │  - FCM集成                                                            │   │
│  │  - 廠商推送SDK調研                                                    │   │
│  │  - 志願者接單推送                                                     │   │
│  │  - 雙向評價系統                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  W4: 打磨 + 演示                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ [Day 21-22] SOS流程                                                   │   │
│  │  - 緊急關鍵詞檢測優化                                                 │   │
│  │  - 電源鍵快捷觸發                                                     │   │
│  │  - 廣播推送邏輯                                                       │   │
│  │  - 緊急聯繫人通知                                                     │   │
│  │                                                                       │   │
│  │ [Day 23-24] 異步求助 (簡化)                                           │   │
│  │  - 任務提交                                                           │   │
│  │  - 任務隊列展示                                                       │   │
│  │                                                                       │   │
│  │ [Day 25-26] Bug修復 + 優化                                            │   │
│  │  - 性能優化                                                           │   │
│  │  - 無障礙測試                                                         │   │
│  │                                                                       │   │
│  │ [Day 27-28] 演示視頻錄製                                              │   │
│  │  - 演示腳本準備                                                       │   │
│  │  - 視頻錄製 + 剪輯                                                    │   │
│  │  - 競賽材料提交                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 MVP 功能清單 (P0)

| 模塊 | 功能 | PRD編號 | 負責人 | 狀態 |
|------|------|---------|--------|------|
| 首頁 | 首頁框架 | F0 | TBD | 待開發 |
| AI Agent | 智能對話 | F1 | TBD | 待開發 |
| AI Agent | OCR識別+朗讀 | F2 | TBD | 待開發 |
| AI Agent | 場景識別 | F3 | TBD | 待開發 |
| AI Agent | 顏色識別 | F4 | TBD | 待開發 |
| AI Agent | 緊急檢測 | F8 | TBD | 待開發 |
| 志願者 | 匹配引擎 | F9 | TBD | 待開發 |
| 志願者 | 語音通話 | F11 | TBD | 待開發 |
| 志願者 | SOS廣播 | F13 | TBD | 待開發 |
| 用戶中心 | 偏好設置 | F17 | TBD | 待開發 |
| 安全 | 認證體系 | F28 | TBD | 待開發 |
| 安全 | 雙向互評 | F30 | TBD | 待開發 |
| 系統 | 登錄註冊 | F33 | TBD | 待開發 |
| 系統 | 消息推送 | F34 | TBD | 待開發 |
| 系統 | 無障礙適配 | F36 | TBD | 貫穿全程 |

### 3.3 V1.0 階段任務清單

| 模塊 | 任務 | 預計工期 | 依賴 |
|------|------|----------|------|
| **AI增強** | 鈔票識別 | 1周 | MVP完成 |
| | 翻譯功能 | 1周 | MVP完成 |
| | 離線OCR (PaddleOCR) | 2周 | MVP完成 |
| | 多輪對話優化 | 1周 | MVP完成 |
| **通信增強** | 視頻通話 | 2周 | WebRTC基礎 |
| | 屏幕共享 | 1周 | 視頻通話 |
| **志願者體系** | 完整等級系統 | 1周 | MVP完成 |
| | 積分/徽章系統 | 1周 | 等級系統 |
| | 排班管理 | 1周 | - |
| | 異步任務隊列 | 2周 | - |
| **社羣** | 精選故事 | 1周 | - |
| | 新手村 | 1周 | - |
| | 興趣小組 | 2周 | - |
| **安全** | 通話錄音+AI檢測 | 2周 | 視頻通話 |
| | 舉報處理流程 | 1周 | - |
| **運營** | Web後臺-用戶管理 | 1周 | - |
| | Web後臺-數據看板 | 2周 | - |

### 3.4 依賴關係圖

```text
MVP基礎
  │
  ├──► AI增強功能 ────────┐
  │                        │
  ├──► 通信增強 ──► 安全增強 │
  │       │                │
  │       └──────────────► V1.0完整版
  │                        ▲
  ├──► 志願者體系完善 ─────┘
  │
  └──► 社羣功能 ───────────┘
```

---

## 4. 性能指標與技術方案對應

### 4.1 性能指標達成方案

| 指標 | 目標值 | 技術實現方案 | 監控方案 |
|------|--------|--------------|----------|
| **AI首次響應** | ≤3秒 | 1. 流式API響應，首包時間<1s<br>2. 本地意圖識別緩存<br>3. 輕量模型優先策略 | Supabase Logs + 自定義埋點 |
| **匹配耗時** | ≤30秒 | 1. PostGIS地理索引加速查詢<br>2. 在線志願者Redis緩存<br>3. 並行推送FCM | 匹配流程埋點，記錄各階段耗時 |
| **通話建立** | ≤5秒 | 1. WebRTC P2P直連<br>2. Supabase Realtime信令<br>3. ICE服務器預連接 | WebRTC統計API |
| **App冷啓動** | ≤3秒 | 1. Flutter引擎預加載<br>2. 首屏數據並行加載<br>3. 圖片懶加載 | Flutter性能監控 |
| **推送延遲** | ≤2秒 | 1. FCM高優先級通道<br>2. 廠商推送並行<br>3. 本地推送兜底 | FCM送達回執 |

### 4.2 性能優化技術細節

#### AI響應優化

```dart
// 流式響應處理
class AIStreamService {
  Stream<String> getStreamResponse(String input) async* {
    final response = await http.Client().send(
      http.Request('POST', Uri.parse(apiUrl))
        ..body = jsonEncode({'input': input, 'stream': true})
    );

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      yield chunk; // 逐字輸出，降低 perceived latency
    }
  }
}
```

#### 匹配查詢優化

```sql
-- 使用PostGIS + 在線狀態索引
SELECT
  vp.user_id,
  vp.skills,
  ST_Distance(vp.location, seeker_location) as distance,
  vp.credit_score
FROM volunteer_profiles vp
WHERE
  vp.is_online = true
  AND vp.is_verified = true
  AND ST_DWithin(vp.location, seeker_location, 50000) -- 50km內
  AND vp.skills && ARRAY['medical'] -- 技能匹配
ORDER BY
  vp.credit_score DESC,
  ST_Distance(vp.location, seeker_location)
LIMIT 5;
```

#### WebRTC連接優化

```dart
// ICE配置優化
final iceServers = [
  {'urls': 'stun:stun.l.google.com:19302'},
  {'urls': 'turn:turn.supabase.co:3478', 'username': '...', 'credential': '...'},
];

// 預連接策略
class WebRTCManager {
  RTCPeerConnection? _preparedConnection;

  Future<void> prepareConnection() async {
    _preparedConnection = await createPeerConnection({
      'iceServers': iceServers,
      'iceTransportPolicy': 'all',
    });
    // 提前收集ICE候選
  }
}
```

---

## 5. 第三方服務成本明細

### 5.1 MVP階段費用預估 (月)

| 服務 | 免費額度 | 預估用量 | 單價 | 月費用 | 備註 |
|------|----------|----------|------|--------|------|
| **Supabase** | 500MB/月 | 1GB | Pro $25 | ¥175 | 或先用Free tier |
| **百度OCR** | 50,000次/月 | 30,000次 | ¥0 | ¥0 | 通用文字識別 |
| **科大訊飛ASR** | 20,000次/月 | 15,000次 | ¥0 | ¥0 | 免費額度內 |
| **科大訊飛TTS** | 20,000次/月 | 10,000次 | ¥0 | ¥0 | 免費額度內 |
| **通義千問VL** | - | 50,000 tokens | ¥0.003/1K | ¥150 | 按Token計費 |
| **高德地圖** | 50,000次/天 | 10,000次/天 | ¥0 | ¥0 | 免費額度足夠 |
| **FCM推送** | 無限制 | - | 免費 | ¥0 | 完全免費 |
| **廠商推送** | - | - | - | ¥0 | SDK免費 |
| **WebRTC** | - | - | - | ¥0 | P2P免費 |
| **合計** | - | - | - | **¥175-325** | 可控範圍 |

### 5.2 V1.0階段費用預估 (月)

| 服務 | 預估用量 | 單價 | 月費用 | 增長原因 |
|------|----------|------|--------|----------|
| **Supabase** | 10GB + 100萬請求 | Pro $25 | ¥175 | 數據增長 |
| **百度OCR** | 100,000次 | ¥0.002/次 | ¥200 | 超免費額度 |
| **科大訊飛ASR** | 100,000次 | ¥0.008/次 | ¥640 | 用量增長 |
| **科大訊飛TTS** | 80,000次 | ¥0.005/次 | ¥320 | 用量增長 |
| **通義千問VL** | 500,000 tokens | ¥0.003/1K | ¥1,500 | 功能增強 |
| **PaddleOCR** | 本地運行 | - | ¥0 | 離線方案 |
| **高德地圖** | 50,000次/天 | ¥0 | ¥0 | 仍在免費額 |
| **FCM推送** | 500,000次 | 免費 | ¥0 | 免費 |
| **合計** | - | - | **¥2,835** | 需控制成本 |

### 5.3 成本控制建議

#### 策略1: 分級AI調用

```dart
class AICostController {
  Future<String> process(String input, {String? imageUrl}) async {
    // 簡單任務用輕量模型
    if (isSimpleQuery(input)) {
      return await callLightModel(input); // 成本低
    }

    // 視覺任務用VL模型
    if (imageUrl != null) {
      return await callVLModel(input, imageUrl); // 成本高但必要
    }

    // 默認用中等模型
    return await callStandardModel(input);
  }
}
```

#### 策略2: 緩存常見查詢

```sql
-- 創建查詢結果緩存表
CREATE TABLE ai_response_cache (
  query_hash TEXT PRIMARY KEY,  -- 查詢內容哈希
  response JSONB,               -- 緩存結果
  hit_count INT DEFAULT 1,      -- 命中次數
  created_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ        -- 過期時間
);

-- 查詢時先查緩存
SELECT response FROM ai_response_cache
WHERE query_hash = '...' AND expires_at > NOW();
```

#### 策略3: 離線能力優先
| 功能 | 在線方案 | 離線方案 | 建議 |
|------|----------|----------|------|
| OCR | 百度OCR | PaddleOCR Lite | 離線優先，失敗轉在線 |
| 顏色識別 | 雲端CV | 本地算法 | 完全離線 |
| 意圖識別 | 大模型 | 本地規則引擎 | 簡單意圖本地處理 |
| TTS | 訊飛API | 系統TTS | 非關鍵場景用系統TTS |

### 5.4 成本監控Dashboard指標

```yaml
# 監控指標配置
監控指標:
  - 每日API調用次數 (按服務分類)
  - 每日Token消耗量
  - 緩存命中率
  - 平均每次求助成本
  - 月度成本趨勢

告警閾值:
  - 單日API調用 > 5000次
  - 單日成本 > ¥100
  - 月度成本 > 預算的80%
```

---

## 6. 風險與應對

### 6.1 技術風險

| 風險 | 概率 | 影響 | 應對策略 |
|------|------|------|----------|
| Supabase國內訪問慢 | 高 | 高 | 配置CDN加速，準備自託管方案 |
| WebRTC NAT穿透失敗 | 中 | 高 | 部署TURN服務器，P2P失敗轉中繼 |
| AI API限流/故障 | 中 | 高 | 多供應商備選，本地降級方案 |
| Flutter包體積過大 | 中 | 中 | 啓用代碼裁剪，資源壓縮 |
| 廠商推送集成複雜 | 高 | 中 | 使用第三方推送聚合服務 |

### 6.2 合規風險

| 風險 | 應對 |
|------|------|
| 個人信息保護法 | 數據加密存儲，7天自動刪除錄音，提供數據導出 |
| 無障礙合規 | 遵循WCAG 2.1 AAA標準，通過屏幕閱讀器測試 |
| 地圖合規 | 使用高德地圖，符合國內法規 |

---

## 7. 總結與建議

### 7.1 技術架構亮點
1. **雙引擎架構**: AI處理80%標準化需求 + 志願者處理20%複雜需求，成本與體驗平衡
2. **BaaS優先**: Supabase大幅降低後端開發成本，適合MVP快速驗證
3. **無障礙優先設計**: 從架構層面考慮視障/聽障用戶需求，而非事後補丁
4. **漸進式AI策略**: 在線API + 離線模型 + 緩存，控制成本同時保證可用性

### 7.2 關鍵建議
1. **Week1必須完成**: 項目腳手架 + Supabase連接 + 無障礙基礎組件
2. **AI成本控制**: MVP階段嚴格監控通義千問VL調用量，設置每日上限
3. **匹配算法簡化**: MVP先用SQL查詢+簡單排序，V1.0再引入複雜算法
4. **WebRTC備選**: 準備P2P失敗時的電話回撥備選方案
5. **種子志願者**: 技術上線前1周必須招募10-20名種子志願者

### 7.3 下一步行動
- [ ] 創建Flutter項目腳手架
- [ ] 註冊Supabase並初始化數據庫
- [ ] 申請各AI服務API Key
- [ ] 制定詳細的無障礙測試清單
- [ ] 招募種子志願者

---

*報告生成時間: 2026-04-10*
*基於PRD版本: v1.0*
