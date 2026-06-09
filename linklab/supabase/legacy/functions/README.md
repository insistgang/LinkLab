# Supabase Edge Functions - 志願者匹配引擎

## 已實現功能

### 1. matching-engine (匹配引擎)

**文件位置**: `/supabase/functions/matching-engine/index.ts`

**功能**:
- 多維匹配算法: `匹配分 = 0.30×緊急度 + 0.25×地理距離 + 0.20×技能匹配 + 0.15×信譽分 + 0.10×歷史親密度`
- Haversine公式計算地理距離
- Top 5志願者篩選
- 30秒超時擴大搜索範圍
- 60秒轉爲異步留言
- 志願者接單/拒絕處理

**API端點**:
- `POST /matching-engine` - 創建匹配請求
- `POST /matching-engine/timeout` - 處理超時
- `POST /matching-engine/accept` - 志願者接單
- `POST /matching-engine/reject` - 志願者拒絕

### 2. push-notifier (推送通知服務)

**文件位置**: `/supabase/functions/push-notifier/index.ts`

**功能**:
- FCM推送通知（匹配請求、匹配確認）
- SOS廣播推送（5km範圍內）
- 緊急聯繫人短信通知
- SOS升級策略（5分鐘全城廣播）

**API端點**:
- `POST /push-notifier` - 發送推送通知

**支持的通知類型**:
- `matching_request` - 匹配請求
- `matching_confirmed` - 匹配確認
- `sos_broadcast` - SOS廣播
- `emergency_sms` - 緊急短信
- `sos_escalation` - SOS升級

### 3. Dart端服務

**RealMatchingService** (`lib/services/real_matching_service.dart`):
- 調用Edge Function進行匹配
- 匹配狀態管理
- 超時處理
- 心跳維護
- 志願者在線狀態管理

**RealtimeSyncService** (`lib/services/realtime_sync_service.dart`):
- 志願者狀態實時訂閱
- 求助狀態實時同步
- 通話信令傳輸
- SOS狀態訂閱

## 數據庫表

### 新增表

1. **help_request_matches** - 匹配記錄表
2. **user_devices** - 用戶設備表（FCM Token）
3. **sos_broadcast_logs** - SOS廣播日誌
4. **user_presence** - 用戶在線狀態
5. **help_request_heartbeats** - 求助心跳

### 擴展表

- **volunteer_profiles** - 添加`is_available`和`last_heartbeat_at`字段
- **help_requests** - 添加`required_skills`和`help_type`字段

### PostGIS函數

- `get_volunteers_in_radius(lat, lng, radius_km)` - 獲取範圍內的志願者
- `update_volunteer_heartbeat(user_id, lat, lng)` - 更新志願者心跳

## 部署說明

詳見 [DEPLOYMENT.md](./DEPLOYMENT.md)

## 匹配算法詳解

### 權重配置

```typescript
const MATCHING_WEIGHTS = {
  urgency: 0.30,      // 緊急度
  distance: 0.25,     // 地理距離
  skills: 0.20,       // 技能匹配
  credit: 0.15,       // 信譽分
  intimacy: 0.10,     // 歷史親密度
};
```

### 各維度計算

1. **緊急度**: normal=0.4, important=0.6, urgent=0.8, emergency=1.0
2. **地理距離**: `1 - min(距離/5km, 1)`
3. **技能匹配**: 匹配標籤數 / 需求標籤數
4. **信譽分**: credit_score / 5.0
5. **歷史親密度**: 簡化版，默認0.5

## 流程圖

```
求助者發起請求
    │
    ▼
創建help_requests記錄
    │
    ▼
獲取在線志願者（5km內）
    │
    ▼
計算匹配分數（Top 5）
    │
    ▼
創建help_request_matches記錄
    │
    ▼
並行發送FCM推送
    │
    ▼
等待志願者響應（30秒）
    │
    ├── 有人接單 → 建立連接
    │
    └── 無人響應 → 擴大範圍（Top 10）
            │
            ├── 有人接單 → 建立連接
            │
            └── 仍無響應（60秒）→ 轉爲異步
```

## 環境變量

```bash
# Supabase
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# FCM
FCM_PROJECT_ID=
FCM_CLIENT_EMAIL=
FCM_PRIVATE_KEY=
```

## 測試

```bash
# 測試匹配引擎
curl -X POST https://your-project.supabase.co/functions/v1/matching-engine \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "seekerId": "test-user-id",
    "urgency": "urgent",
    "location": {"lat": 31.2304, "lng": 121.4737},
    "skills": ["醫療輔助"],
    "helpType": "測試求助"
  }'

# 測試推送通知
curl -X POST https://your-project.supabase.co/functions/v1/push-notifier \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "matching_request",
    "userId": "volunteer-user-id",
    "title": "有新的求助",
    "body": "距離您1km有人需要幫助"
  }'
```
