# Supabase Edge Functions 部署指南

## 概述

本文檔說明如何部署志願者匹配引擎相關的Supabase Edge Functions。

## 包含的Edge Functions

1. **matching-engine** - 志願者匹配引擎
   - 路徑: `/functions/v1/matching-engine`
   - 功能: 計算匹配分數、推送通知、超時處理

2. **push-notifier** - 推送通知服務
   - 路徑: `/functions/v1/push-notifier`
   - 功能: FCM推送、SOS廣播、緊急短信

## 前置條件

1. 安裝Supabase CLI
```bash
npm install -g supabase
```

2. 登錄Supabase
```bash
supabase login
```

3. 鏈接項目
```bash
supabase link --project-ref your-project-ref
```

## 環境變量配置

在Supabase Dashboard中設置以下環境變量:

### 必需變量

```bash
# Supabase配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# FCM配置（用於推送通知）
FCM_PROJECT_ID=your-firebase-project-id
FCM_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FCM_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
```

### 可選變量

```bash
# 短信服務商配置（用於SOS緊急短信）
SMS_PROVIDER=aliyun  # 或 twilio
SMS_ACCESS_KEY=your-access-key
SMS_SECRET_KEY=your-secret-key

# 語音電話配置（用於SOS升級）
VOICE_PROVIDER=twilio
VOICE_ACCOUNT_SID=your-account-sid
VOICE_AUTH_TOKEN=your-auth-token
```

## 部署步驟

### 1. 部署數據庫遷移

```bash
# 在Supabase Dashboard的SQL Editor中執行
# 或運行:
supabase db push
```

### 2. 部署Edge Functions

```bash
# 部署所有函數
supabase functions deploy

# 或單獨部署
supabase functions deploy matching-engine
supabase functions deploy push-notifier
```

### 3. 驗證部署

```bash
# 獲取JWT令牌
supabase tokens create

# 測試匹配引擎
curl -X POST https://your-project.supabase.co/functions/v1/matching-engine \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "seekerId": "test-user-id",
    "urgency": "urgent",
    "location": {"lat": 31.2304, "lng": 121.4737},
    "skills": ["醫療輔助"],
    "helpType": "測試求助"
  }'
```

## API文檔

### matching-engine

#### POST /matching-engine

創建匹配請求。

**請求體:**
```json
{
  "seekerId": "string",
  "urgency": "normal|important|urgent|emergency",
  "location": {"lat": number, "lng": number},
  "skills": ["string"],
  "helpType": "string"
}
```

**響應:**
```json
{
  "success": true,
  "helpRequestId": "uuid",
  "volunteers": [
    {
      "id": "uuid",
      "userId": "uuid",
      "score": 0.85,
      "distance": 1.2,
      "skills": ["醫療輔助"]
    }
  ],
  "timeoutAt": "2025-04-11T12:00:00Z"
}
```

#### POST /matching-engine/timeout

處理匹配超時。

**請求體:**
```json
{
  "helpRequestId": "uuid",
  "expandRange": true|false
}
```

#### POST /matching-engine/accept

志願者接受匹配。

**請求體:**
```json
{
  "helpRequestId": "uuid",
  "volunteerId": "uuid"
}
```

#### POST /matching-engine/reject

志願者拒絕匹配。

**請求體:**
```json
{
  "helpRequestId": "uuid",
  "volunteerId": "uuid"
}
```

### push-notifier

#### POST /push-notifier

發送推送通知。

**請求體 - 匹配請求:**
```json
{
  "type": "matching_request",
  "userId": "uuid",
  "title": "有新的求助需要您的幫助",
  "body": "距離您 1.2km 有人需要幫助",
  "data": {"helpRequestId": "uuid", "type": "matching_request"}
}
```

**請求體 - SOS廣播:**
```json
{
  "type": "sos_broadcast",
  "sosId": "uuid",
  "location": {"lat": 31.2304, "lng": 121.4737},
  "radius": 5,
  "priority": "critical"
}
```

**請求體 - 緊急短信:**
```json
{
  "type": "emergency_sms",
  "contacts": ["+86138xxxxxxxx"],
  "message": "【共感LinkAble緊急求助】您的親友觸發了SOS求助..."
}
```

## 監控和日誌

### 查看函數日誌

```bash
# 實時查看日誌
supabase functions logs matching-engine --tail

# 查看push-notifier日誌
supabase functions logs push-notifier --tail
```

### 在Dashboard中查看

1. 進入Supabase Dashboard
2. 選擇 Edge Functions
3. 點擊函數名稱查看日誌和統計

## 故障排除

### 1. 函數部署失敗

檢查:
- 環境變量是否正確設置
- 代碼語法錯誤
- 依賴包版本兼容性

### 2. FCM推送失敗

檢查:
- FCM_PROJECT_ID是否正確
- FCM_CLIENT_EMAIL和FCM_PRIVATE_KEY是否匹配
- Firebase項目是否啓用了Cloud Messaging API

### 3. 匹配引擎返回空結果

檢查:
- volunteer_profiles表是否有在線志願者
- 志願者位置數據是否正確
- PostGIS函數是否正確創建

### 4. Realtime訂閱不工作

檢查:
- 數據庫表是否啓用了Realtime
- RLS策略是否正確
- 客戶端訂閱代碼是否正確

## 性能優化

### 1. 數據庫索引

確保以下索引已創建:
```sql
CREATE INDEX idx_volunteer_profiles_online ON volunteer_profiles(is_online, is_available);
CREATE INDEX idx_volunteer_profiles_location ON volunteer_profiles(latitude, longitude);
CREATE INDEX idx_help_request_matches_status ON help_request_matches(status);
```

### 2. 函數配置

在`config.toml`中調整:
```toml
[functions.matching-engine]
verify_jwt = true
# 內存限制 (MB)
memory = 256
# 超時時間 (秒)
timeout = 30
```

## 更新和回滾

### 更新函數

```bash
# 修改代碼後重新部署
supabase functions deploy matching-engine
```

### 回滾版本

```bash
# 查看歷史版本
supabase functions list

# 回滾到特定版本（需要手動操作）
# 1. 從git歷史恢復代碼
# 2. 重新部署
```

## 安全注意事項

1. **JWT驗證**: 生產環境必須啓用`verify_jwt = true`
2. **服務角色密鑰**: 僅在Edge Function內部使用，不要暴露給客戶端
3. **FCM私鑰**: 妥善保管，定期輪換
4. **RLS策略**: 確保數據庫表有適當的訪問控制

## 聯繫支持

如有問題，請聯繫:
- 技術負責人: [your-email]
- Supabase文檔: https://supabase.com/docs
