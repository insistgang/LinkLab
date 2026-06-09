# 共感 LinkAble Supabase 部署配置指南

## 前置要求

### 環境要求

| 組件 | 版本要求 | 說明 |
|------|---------|------|
| Node.js | >= 18.0.0 | 運行Supabase CLI和Edge Functions |
| Flutter | >= 3.16.0 | 前端應用開發框架 |
| Dart | >= 3.0.0 | Flutter開發語言 |
| Supabase CLI | >= 1.100.0 | 命令行工具 |

安裝Supabase CLI:
```bash
npm install -g supabase
```

驗證版本:
```bash
node --version    # v18.0.0+
flutter --version # 3.16.0+
dart --version    # 3.0.0+
supabase --version # 1.100.0+
```

---

## 1. Supabase項目創建

### 1.1 登錄Supabase

```bash
supabase login
```

瀏覽器將自動打開，完成OAuth授權。

### 1.2 創建新項目（可選）

如果還沒有Supabase項目，可以通過以下方式創建:

**方式一：通過Supabase Dashboard創建**
1. 訪問 https://app.supabase.io
2. 點擊 "New Project"
3. 選擇組織，填寫項目名稱
4. 設置數據庫密碼（請妥善保存）
5. 選擇區域（建議選擇離用戶最近的區域，如：Singapore）
6. 點擊 "Create new project"
7. 等待項目創建完成（約1-2分鐘）

**方式二：通過CLI創建**
```bash
supabase projects create <project-name> --org-id <org-id> --region ap-southeast-1
```

### 1.3 關聯本地項目

```bash
# 進入項目目錄
cd E:\project\LinkLab

# 初始化Supabase配置
supabase init

# 關聯遠程項目
supabase link --project-ref <your-project-ref>
```

> **獲取Project Ref**: 在Supabase Dashboard -> Project Settings -> General -> Reference ID

---

## 2. 環境變量配置

### 2.1 創建本地.env文件

在項目根目錄創建 `.env` 文件:

```env
# Supabase連接配置
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>

# AI服務API密鑰
BAIDU_OCR_API_KEY=<baidu-api-key>
BAIDU_OCR_SECRET_KEY=<baidu-secret-key>
DASHSCOPE_API_KEY=<dashscope-api-key>
XUNFEI_API_KEY=<xunfei-api-key>
XUNFEI_APP_ID=<xunfei-app-id>

# 推送服務
FCM_SERVER_KEY=<fcm-server-key>
```

### 2.2 獲取環境變量值

| 變量名 | 獲取方式 |
|--------|---------|
| `SUPABASE_URL` | Supabase Dashboard -> Project Settings -> API -> Project URL |
| `SUPABASE_ANON_KEY` | Supabase Dashboard -> Project Settings -> API -> Project API Keys -> `anon` `public` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Dashboard -> Project Settings -> API -> Project API Keys -> `service_role` `secret` |
| `BAIDU_OCR_API_KEY` | 百度智能雲控制檯 -> 應用列表 -> API Key |
| `BAIDU_OCR_SECRET_KEY` | 百度智能雲控制檯 -> 應用列表 -> Secret Key |
| `DASHSCOPE_API_KEY` | 阿里雲DashScope控制檯 -> API-KEY管理 |
| `XUNFEI_API_KEY` | 訊飛開放平臺 -> 應用管理 -> API Key |
| `XUNFEI_APP_ID` | 訊飛開放平臺 -> 應用管理 -> APPID |
| `FCM_SERVER_KEY` | Firebase Console -> 項目設置 -> 雲消息傳遞 -> 服務器密鑰 |

### 2.3 配置Flutter環境變量

在 `lib/core/config/app_config.dart` 中配置:

```dart
class AppConfig {
  static const String supabaseUrl = 'https://<your-project>.supabase.co';
  static const String supabaseAnonKey = '<your-anon-key>';
}
```

---

## 3. 數據庫遷移

### 3.1 遷移文件說明

項目包含4個SQL遷移文件，必須按順序執行:

| 順序 | 文件名 | 說明 |
|------|--------|------|
| 1 | `001_create_tables.sql` | 創建數據庫表結構 |
| 2 | `002_create_indexes.sql` | 創建索引優化查詢 |
| 3 | `003_create_rls_policies.sql` | 創建行級安全策略 |
| 4 | `004_functions_and_triggers.sql` | 創建數據庫函數和觸發器 |

### 3.2 執行遷移命令

**方式一：使用Supabase CLI（推薦）**

```bash
# 確保已關聯項目
supabase link --project-ref <your-project-ref>

# 執行所有遷移
supabase db push
```

**方式二：手動按順序執行**

```bash
# 1. 創建表結構
supabase migration up 001_create_tables

# 2. 創建索引
supabase migration up 002_create_indexes

# 3. 創建RLS策略
supabase migration up 003_create_rls_policies

# 4. 創建函數和觸發器
supabase migration up 004_functions_and_triggers
```

**方式三：通過Supabase Dashboard手動執行**

1. 登錄 https://app.supabase.io
2. 選擇項目 -> SQL Editor
3. 依次複製粘貼執行4個SQL文件內容
4. 按順序執行：001 -> 002 -> 003 -> 004

### 3.3 驗證遷移結果

```sql
-- 檢查所有表
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' ORDER BY table_name;

-- 預期結果:
-- ai_response_cache
-- async_tasks
-- call_records
-- emergency_contacts
-- help_requests
-- point_transactions
-- reports
-- users
-- volunteer_profiles

-- 檢查索引
SELECT indexname FROM pg_indexes WHERE schemaname = 'public';

-- 檢查RLS策略
SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public';

-- 檢查函數
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
```

### 3.4 啓用PostGIS擴展

```sql
-- 啓用PostGIS擴展
CREATE EXTENSION IF NOT EXISTS postgis;

-- 確認PostGIS已啓用
SELECT * FROM pg_extension WHERE extname = 'postgis';
```

---

## 4. Edge Functions部署

### 4.1 部署所有Edge Functions

```bash
# 部署matching-engine（匹配引擎）
supabase functions deploy matching-engine

# 部署ai-dispatcher（AI調度器）
supabase functions deploy ai-dispatcher

# 部署push-notifier（推送通知）
supabase functions deploy push-notifier

# 部署points-calculator（積分計算）
supabase functions deploy points-calculator
```

### 4.2 配置Edge Functions密鑰

```bash
# AI服務配置
supabase secrets set BAIDU_OCR_API_KEY=<your-baidu-api-key>
supabase secrets set BAIDU_OCR_SECRET_KEY=<your-baidu-secret-key>
supabase secrets set DASHSCOPE_API_KEY=<your-dashscope-api-key>
supabase secrets set XUNFEI_API_KEY=<your-xunfei-api-key>
supabase secrets set XUNFEI_APP_ID=<your-xunfei-app-id>

# 推送服務配置
supabase secrets set FCM_SERVER_KEY=<your-fcm-server-key>
```

### 4.3 驗證部署

```bash
# 列出所有已部署的函數
supabase functions list

# 預期輸出:
# ┌───────────────────┬─────────┬──────────────┐
# │ Name              │ Status  │ Updated At   │
# ├───────────────────┼─────────┼──────────────┤
# │ matching-engine   │ ACTIVE  │ 2024-XX-XX   │
# │ ai-dispatcher     │ ACTIVE  │ 2024-XX-XX   │
# │ push-notifier     │ ACTIVE  │ 2024-XX-XX   │
# │ points-calculator │ ACTIVE  │ 2024-XX-XX   │
# └───────────────────┴─────────┴──────────────┘
```

---

## 5. 認證配置

### 5.1 手機號認證

1. 進入Supabase Dashboard -> Authentication -> Providers
2. 啓用 Phone 提供商
3. 配置短信網關:
   - 測試環境: 使用Twilio Test Credentials
   - 生產環境: 配置Twilio或MessageBird

### 5.2 微信OAuth（可選）

1. 在微信開放平臺註冊應用，獲取AppID和AppSecret
2. 在Supabase Dashboard配置:
   - Provider: WeChat
   - Client ID: 微信AppID
   - Client Secret: 微信AppSecret
   - Redirect URL: `https://<your-project>.supabase.co/auth/v1/callback`

### 5.3 匿名認證

1. 進入 Authentication -> Providers
2. 啓用 Anonymous 提供商
3. 配置自動確認: `GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED=true`

---

## 6. Storage存儲桶配置

### 6.1 創建avatars存儲桶

```sql
-- 創建存儲桶
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);

-- 配置RLS策略
CREATE POLICY "Avatar public access" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

### 6.2 創建recordings存儲桶

```sql
-- 創建存儲桶
insert into storage.buckets (id, name, public) values ('recordings', 'recordings', false);

-- 配置RLS策略(僅通話雙方可訪問)
CREATE POLICY "Recording access for participants" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'recordings' AND
    EXISTS (
      SELECT 1 FROM call_records cr
      WHERE cr.id::text = (storage.foldername(name))[1]
      AND (cr.seeker_id = auth.uid() OR cr.volunteer_id = auth.uid())
    )
  );
```

### 6.3 創建attachments存儲桶

```sql
-- 創建存儲桶
insert into storage.buckets (id, name, public) values ('attachments', 'attachments', false);

-- 配置RLS策略
CREATE POLICY "Attachment access" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'attachments' AND
    EXISTS (
      SELECT 1 FROM async_tasks at
      WHERE at.id::text = (storage.foldername(name))[1]
      AND (at.seeker_id = auth.uid() OR at.volunteer_id = auth.uid())
    )
  );
```

---

## 7. Realtime配置

### 7.1 啓用Realtime

```sql
-- 爲關鍵表啓用Realtime
alter publication supabase_realtime add table help_requests;
alter publication supabase_realtime add table volunteer_profiles;
alter publication supabase_realtime add table async_tasks;
alter publication supabase_realtime add table call_records;
```

### 7.2 驗證Realtime配置

```sql
-- 檢查已啓用Realtime的表
SELECT * FROM pg_publication_tables WHERE publication_name = 'supabase_realtime';
```

---

## 8. 驗證部署

### 8.1 數據庫連接測試

```bash
# 使用psql連接測試
psql "postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres"

# 或使用Supabase Dashboard的SQL Editor
```

### 8.2 Edge Function測試

```bash
# 測試matching-engine
curl -X POST https://<your-project>.supabase.co/functions/v1/matching-engine \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "seeker_id": "test-user-id",
    "location": {"lat": 39.9042, "lng": 116.4074},
    "skills_needed": ["guide"],
    "urgency": "normal"
  }'

# 測試ai-dispatcher
curl -X POST https://<your-project>.supabase.co/functions/v1/ai-dispatcher \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "service": "chat",
    "input": "你好",
    "options": {"stream": false}
  }'

# 測試push-notifier
curl -X POST https://<your-project>.supabase.co/functions/v1/push-notifier \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-id",
    "title": "測試通知",
    "body": "這是一條測試消息"
  }'

# 測試points-calculator
curl -X POST https://<your-project>.supabase.co/functions/v1/points-calculator \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "calculate",
    "help_request_id": "test-request-id"
  }'
```

### 8.3 RLS策略測試

```sql
-- 以普通用戶身份測試查詢
SET ROLE authenticated;
SET request.jwt.claim.sub = 'test-user-id';

-- 測試users表訪問
SELECT * FROM users WHERE id = 'test-user-id';

-- 測試volunteer_profiles訪問
SELECT * FROM volunteer_profiles;

-- 恢復管理員角色
SET ROLE postgres;
```

### 8.4 Flutter應用連接測試

在Flutter應用中測試連接:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://<your-project>.supabase.co',
    anonKey: '<your-anon-key>',
  );
  
  // 測試連接
  final response = await Supabase.instance.client.from('users').select().limit(1);
  print('連接成功: $response');
}
```

---

## 9. 監控配置

### 9.1 啓用日誌

在Supabase Dashboard -> Logs中查看:
- Database Logs
- Edge Function Logs
- Auth Logs

### 9.2 設置告警

建議配置的告警規則:
- 數據庫連接數 > 80%
- Edge Function錯誤率 > 5%
- 存儲空間使用率 > 80%

---

## 10. 備份策略

### 10.1 自動備份

Supabase Cloud自動提供:
- 每日完整備份
- PITR (Point-in-Time Recovery) - Pro計劃

### 10.2 手動備份

```bash
# 導出數據庫
pg_dump "postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres" > backup.sql
```

---

## 11. 常見問題及解決方案

### 問題1: Edge Function 404錯誤

**現象**: 調用Edge Function返回404

**解決方案**:
```bash
# 1. 確認函數已部署
supabase functions list

# 2. 檢查URL路徑是否正確
# 正確格式: https://<project>.supabase.co/functions/v1/<function-name>

# 3. 重新部署函數
supabase functions deploy <function-name>

# 4. 檢查項目引用是否正確
supabase status
```

### 問題2: RLS策略導致查詢無結果

**現象**: 查詢返回空結果，但數據確實存在

**解決方案**:
```sql
-- 1. 檢查當前用戶身份
SELECT current_user;

-- 2. 臨時禁用RLS進行測試（僅開發環境）
ALTER TABLE <table_name> DISABLE ROW LEVEL SECURITY;

-- 3. 檢查策略定義
SELECT * FROM pg_policies WHERE tablename = '<table_name>';

-- 4. 修復策略（示例：允許所有認證用戶訪問）
CREATE POLICY "Allow all authenticated" ON <table_name>
  FOR ALL USING (auth.role() = 'authenticated');
```

### 問題3: PostGIS查詢報錯

**現象**: 執行地理查詢時報錯"function st_distance does not exist"

**解決方案**:
```sql
-- 1. 確認擴展已啓用
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. 檢查擴展版本
SELECT PostGIS_Version();

-- 3. 檢查座標格式（注意是經度在前，緯度在後）
-- 正確: ST_SetSRID(ST_MakePoint(116.4074, 39.9042), 4326)
-- 錯誤: ST_SetSRID(ST_MakePoint(39.9042, 116.4074), 4326)

-- 4. 重新啓用擴展（如已損壞）
DROP EXTENSION IF EXISTS postgis CASCADE;
CREATE EXTENSION postgis;
```

### 問題4: 推送通知失敗

**現象**: FCM推送通知發送失敗

**解決方案**:
```bash
# 1. 檢查FCM Server Key配置
supabase secrets list

# 2. 確認密鑰值正確
supabase secrets set FCM_SERVER_KEY=<your-server-key>

# 3. 檢查設備令牌格式
# 設備令牌應該是FCM註冊令牌，長度約152字符

# 4. 查看Edge Function日誌
supabase functions logs push-notifier
```

### 問題5: 數據庫遷移失敗

**現象**: 執行 `supabase db push` 時報錯

**解決方案**:
```bash
# 1. 檢查遷移文件語法
supabase db lint

# 2. 查看具體錯誤
supabase db push --debug

# 3. 重置數據庫（僅開發環境，會丟失數據）
supabase db reset

# 4. 手動執行單個遷移文件
supabase migration up <migration-name>

# 5. 修復遷移狀態（如遷移已執行但記錄丟失）
supabase migration repair <timestamp> --status applied
```

### 問題6: 認證失敗或JWT驗證錯誤

**現象**: API調用返回401或JWT驗證失敗

**解決方案**:
```bash
# 1. 檢查anon key是否正確
# 確認使用的是 anon public key，不是 service_role key

# 2. 檢查token是否過期
# 在Supabase Dashboard -> Authentication -> Users 查看用戶狀態

# 3. 刷新token
# 在Flutter中調用: await Supabase.instance.client.auth.refreshSession()

# 4. 檢查RLS策略是否允許匿名訪問
```

### 問題7: Edge Function環境變量未生效

**現象**: Edge Function中讀取secrets返回undefined

**解決方案**:
```bash
# 1. 確認secret已設置
supabase secrets list

# 2. 重新設置secret
supabase secrets set SECRET_NAME=value

# 3. 重新部署函數（修改secret後需要重新部署）
supabase functions deploy <function-name>

# 4. 在代碼中正確讀取
# const secret = Deno.env.get('SECRET_NAME')
```

### 問題8: Realtime訂閱不生效

**現象**: Flutter應用中無法收到Realtime更新

**解決方案**:
```sql
-- 1. 確認表已添加到publication
SELECT * FROM pg_publication_tables WHERE publication_name = 'supabase_realtime';

-- 2. 重新添加表
alter publication supabase_realtime add table <table_name>;

-- 3. 檢查RLS策略是否允許Realtime
-- Realtime同樣需要遵守RLS策略
```

---

## 參考鏈接

- [Supabase文檔](https://supabase.com/docs)
- [PostGIS文檔](https://postgis.net/documentation/)
- [Deno Deploy文檔](https://deno.com/deploy/docs)
- [Flutter Supabase文檔](https://supabase.com/docs/reference/dart/introduction)
