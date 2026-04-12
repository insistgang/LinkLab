# 共感 LinkAble Supabase 部署配置指南

## 前置要求

### 环境要求

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| Node.js | >= 18.0.0 | 运行Supabase CLI和Edge Functions |
| Flutter | >= 3.16.0 | 前端应用开发框架 |
| Dart | >= 3.0.0 | Flutter开发语言 |
| Supabase CLI | >= 1.100.0 | 命令行工具 |

安装Supabase CLI:
```bash
npm install -g supabase
```

验证版本:
```bash
node --version    # v18.0.0+
flutter --version # 3.16.0+
dart --version    # 3.0.0+
supabase --version # 1.100.0+
```

---

## 1. Supabase项目创建

### 1.1 登录Supabase

```bash
supabase login
```

浏览器将自动打开，完成OAuth授权。

### 1.2 创建新项目（可选）

如果还没有Supabase项目，可以通过以下方式创建:

**方式一：通过Supabase Dashboard创建**
1. 访问 https://app.supabase.io
2. 点击 "New Project"
3. 选择组织，填写项目名称
4. 设置数据库密码（请妥善保存）
5. 选择区域（建议选择离用户最近的区域，如：Singapore）
6. 点击 "Create new project"
7. 等待项目创建完成（约1-2分钟）

**方式二：通过CLI创建**
```bash
supabase projects create <project-name> --org-id <org-id> --region ap-southeast-1
```

### 1.3 关联本地项目

```bash
# 进入项目目录
cd E:\project\LinkLab

# 初始化Supabase配置
supabase init

# 关联远程项目
supabase link --project-ref <your-project-ref>
```

> **获取Project Ref**: 在Supabase Dashboard -> Project Settings -> General -> Reference ID

---

## 2. 环境变量配置

### 2.1 创建本地.env文件

在项目根目录创建 `.env` 文件:

```env
# Supabase连接配置
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>

# AI服务API密钥
BAIDU_OCR_API_KEY=<baidu-api-key>
BAIDU_OCR_SECRET_KEY=<baidu-secret-key>
DASHSCOPE_API_KEY=<dashscope-api-key>
XUNFEI_API_KEY=<xunfei-api-key>
XUNFEI_APP_ID=<xunfei-app-id>

# 推送服务
FCM_SERVER_KEY=<fcm-server-key>
```

### 2.2 获取环境变量值

| 变量名 | 获取方式 |
|--------|---------|
| `SUPABASE_URL` | Supabase Dashboard -> Project Settings -> API -> Project URL |
| `SUPABASE_ANON_KEY` | Supabase Dashboard -> Project Settings -> API -> Project API Keys -> `anon` `public` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Dashboard -> Project Settings -> API -> Project API Keys -> `service_role` `secret` |
| `BAIDU_OCR_API_KEY` | 百度智能云控制台 -> 应用列表 -> API Key |
| `BAIDU_OCR_SECRET_KEY` | 百度智能云控制台 -> 应用列表 -> Secret Key |
| `DASHSCOPE_API_KEY` | 阿里云DashScope控制台 -> API-KEY管理 |
| `XUNFEI_API_KEY` | 讯飞开放平台 -> 应用管理 -> API Key |
| `XUNFEI_APP_ID` | 讯飞开放平台 -> 应用管理 -> APPID |
| `FCM_SERVER_KEY` | Firebase Console -> 项目设置 -> 云消息传递 -> 服务器密钥 |

### 2.3 配置Flutter环境变量

在 `lib/core/config/app_config.dart` 中配置:

```dart
class AppConfig {
  static const String supabaseUrl = 'https://<your-project>.supabase.co';
  static const String supabaseAnonKey = '<your-anon-key>';
}
```

---

## 3. 数据库迁移

### 3.1 迁移文件说明

项目包含4个SQL迁移文件，必须按顺序执行:

| 顺序 | 文件名 | 说明 |
|------|--------|------|
| 1 | `001_create_tables.sql` | 创建数据库表结构 |
| 2 | `002_create_indexes.sql` | 创建索引优化查询 |
| 3 | `003_create_rls_policies.sql` | 创建行级安全策略 |
| 4 | `004_functions_and_triggers.sql` | 创建数据库函数和触发器 |

### 3.2 执行迁移命令

**方式一：使用Supabase CLI（推荐）**

```bash
# 确保已关联项目
supabase link --project-ref <your-project-ref>

# 执行所有迁移
supabase db push
```

**方式二：手动按顺序执行**

```bash
# 1. 创建表结构
supabase migration up 001_create_tables

# 2. 创建索引
supabase migration up 002_create_indexes

# 3. 创建RLS策略
supabase migration up 003_create_rls_policies

# 4. 创建函数和触发器
supabase migration up 004_functions_and_triggers
```

**方式三：通过Supabase Dashboard手动执行**

1. 登录 https://app.supabase.io
2. 选择项目 -> SQL Editor
3. 依次复制粘贴执行4个SQL文件内容
4. 按顺序执行：001 -> 002 -> 003 -> 004

### 3.3 验证迁移结果

```sql
-- 检查所有表
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' ORDER BY table_name;

-- 预期结果:
-- ai_response_cache
-- async_tasks
-- call_records
-- emergency_contacts
-- help_requests
-- point_transactions
-- reports
-- users
-- volunteer_profiles

-- 检查索引
SELECT indexname FROM pg_indexes WHERE schemaname = 'public';

-- 检查RLS策略
SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public';

-- 检查函数
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
```

### 3.4 启用PostGIS扩展

```sql
-- 启用PostGIS扩展
CREATE EXTENSION IF NOT EXISTS postgis;

-- 确认PostGIS已启用
SELECT * FROM pg_extension WHERE extname = 'postgis';
```

---

## 4. Edge Functions部署

### 4.1 部署所有Edge Functions

```bash
# 部署matching-engine（匹配引擎）
supabase functions deploy matching-engine

# 部署ai-dispatcher（AI调度器）
supabase functions deploy ai-dispatcher

# 部署push-notifier（推送通知）
supabase functions deploy push-notifier

# 部署points-calculator（积分计算）
supabase functions deploy points-calculator
```

### 4.2 配置Edge Functions密钥

```bash
# AI服务配置
supabase secrets set BAIDU_OCR_API_KEY=<your-baidu-api-key>
supabase secrets set BAIDU_OCR_SECRET_KEY=<your-baidu-secret-key>
supabase secrets set DASHSCOPE_API_KEY=<your-dashscope-api-key>
supabase secrets set XUNFEI_API_KEY=<your-xunfei-api-key>
supabase secrets set XUNFEI_APP_ID=<your-xunfei-app-id>

# 推送服务配置
supabase secrets set FCM_SERVER_KEY=<your-fcm-server-key>
```

### 4.3 验证部署

```bash
# 列出所有已部署的函数
supabase functions list

# 预期输出:
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

## 5. 认证配置

### 5.1 手机号认证

1. 进入Supabase Dashboard -> Authentication -> Providers
2. 启用 Phone 提供商
3. 配置短信网关:
   - 测试环境: 使用Twilio Test Credentials
   - 生产环境: 配置Twilio或MessageBird

### 5.2 微信OAuth（可选）

1. 在微信开放平台注册应用，获取AppID和AppSecret
2. 在Supabase Dashboard配置:
   - Provider: WeChat
   - Client ID: 微信AppID
   - Client Secret: 微信AppSecret
   - Redirect URL: `https://<your-project>.supabase.co/auth/v1/callback`

### 5.3 匿名认证

1. 进入 Authentication -> Providers
2. 启用 Anonymous 提供商
3. 配置自动确认: `GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED=true`

---

## 6. Storage存储桶配置

### 6.1 创建avatars存储桶

```sql
-- 创建存储桶
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

### 6.2 创建recordings存储桶

```sql
-- 创建存储桶
insert into storage.buckets (id, name, public) values ('recordings', 'recordings', false);

-- 配置RLS策略(仅通话双方可访问)
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

### 6.3 创建attachments存储桶

```sql
-- 创建存储桶
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

### 7.1 启用Realtime

```sql
-- 为关键表启用Realtime
alter publication supabase_realtime add table help_requests;
alter publication supabase_realtime add table volunteer_profiles;
alter publication supabase_realtime add table async_tasks;
alter publication supabase_realtime add table call_records;
```

### 7.2 验证Realtime配置

```sql
-- 检查已启用Realtime的表
SELECT * FROM pg_publication_tables WHERE publication_name = 'supabase_realtime';
```

---

## 8. 验证部署

### 8.1 数据库连接测试

```bash
# 使用psql连接测试
psql "postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres"

# 或使用Supabase Dashboard的SQL Editor
```

### 8.2 Edge Function测试

```bash
# 测试matching-engine
curl -X POST https://<your-project>.supabase.co/functions/v1/matching-engine \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "seeker_id": "test-user-id",
    "location": {"lat": 39.9042, "lng": 116.4074},
    "skills_needed": ["guide"],
    "urgency": "normal"
  }'

# 测试ai-dispatcher
curl -X POST https://<your-project>.supabase.co/functions/v1/ai-dispatcher \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "service": "chat",
    "input": "你好",
    "options": {"stream": false}
  }'

# 测试push-notifier
curl -X POST https://<your-project>.supabase.co/functions/v1/push-notifier \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-id",
    "title": "测试通知",
    "body": "这是一条测试消息"
  }'

# 测试points-calculator
curl -X POST https://<your-project>.supabase.co/functions/v1/points-calculator \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "calculate",
    "help_request_id": "test-request-id"
  }'
```

### 8.3 RLS策略测试

```sql
-- 以普通用户身份测试查询
SET ROLE authenticated;
SET request.jwt.claim.sub = 'test-user-id';

-- 测试users表访问
SELECT * FROM users WHERE id = 'test-user-id';

-- 测试volunteer_profiles访问
SELECT * FROM volunteer_profiles;

-- 恢复管理员角色
SET ROLE postgres;
```

### 8.4 Flutter应用连接测试

在Flutter应用中测试连接:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://<your-project>.supabase.co',
    anonKey: '<your-anon-key>',
  );
  
  // 测试连接
  final response = await Supabase.instance.client.from('users').select().limit(1);
  print('连接成功: $response');
}
```

---

## 9. 监控配置

### 9.1 启用日志

在Supabase Dashboard -> Logs中查看:
- Database Logs
- Edge Function Logs
- Auth Logs

### 9.2 设置告警

建议配置的告警规则:
- 数据库连接数 > 80%
- Edge Function错误率 > 5%
- 存储空间使用率 > 80%

---

## 10. 备份策略

### 10.1 自动备份

Supabase Cloud自动提供:
- 每日完整备份
- PITR (Point-in-Time Recovery) - Pro计划

### 10.2 手动备份

```bash
# 导出数据库
pg_dump "postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres" > backup.sql
```

---

## 11. 常见问题及解决方案

### 问题1: Edge Function 404错误

**现象**: 调用Edge Function返回404

**解决方案**:
```bash
# 1. 确认函数已部署
supabase functions list

# 2. 检查URL路径是否正确
# 正确格式: https://<project>.supabase.co/functions/v1/<function-name>

# 3. 重新部署函数
supabase functions deploy <function-name>

# 4. 检查项目引用是否正确
supabase status
```

### 问题2: RLS策略导致查询无结果

**现象**: 查询返回空结果，但数据确实存在

**解决方案**:
```sql
-- 1. 检查当前用户身份
SELECT current_user;

-- 2. 临时禁用RLS进行测试（仅开发环境）
ALTER TABLE <table_name> DISABLE ROW LEVEL SECURITY;

-- 3. 检查策略定义
SELECT * FROM pg_policies WHERE tablename = '<table_name>';

-- 4. 修复策略（示例：允许所有认证用户访问）
CREATE POLICY "Allow all authenticated" ON <table_name>
  FOR ALL USING (auth.role() = 'authenticated');
```

### 问题3: PostGIS查询报错

**现象**: 执行地理查询时报错"function st_distance does not exist"

**解决方案**:
```sql
-- 1. 确认扩展已启用
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. 检查扩展版本
SELECT PostGIS_Version();

-- 3. 检查坐标格式（注意是经度在前，纬度在后）
-- 正确: ST_SetSRID(ST_MakePoint(116.4074, 39.9042), 4326)
-- 错误: ST_SetSRID(ST_MakePoint(39.9042, 116.4074), 4326)

-- 4. 重新启用扩展（如已损坏）
DROP EXTENSION IF EXISTS postgis CASCADE;
CREATE EXTENSION postgis;
```

### 问题4: 推送通知失败

**现象**: FCM推送通知发送失败

**解决方案**:
```bash
# 1. 检查FCM Server Key配置
supabase secrets list

# 2. 确认密钥值正确
supabase secrets set FCM_SERVER_KEY=<your-server-key>

# 3. 检查设备令牌格式
# 设备令牌应该是FCM注册令牌，长度约152字符

# 4. 查看Edge Function日志
supabase functions logs push-notifier
```

### 问题5: 数据库迁移失败

**现象**: 执行 `supabase db push` 时报错

**解决方案**:
```bash
# 1. 检查迁移文件语法
supabase db lint

# 2. 查看具体错误
supabase db push --debug

# 3. 重置数据库（仅开发环境，会丢失数据）
supabase db reset

# 4. 手动执行单个迁移文件
supabase migration up <migration-name>

# 5. 修复迁移状态（如迁移已执行但记录丢失）
supabase migration repair <timestamp> --status applied
```

### 问题6: 认证失败或JWT验证错误

**现象**: API调用返回401或JWT验证失败

**解决方案**:
```bash
# 1. 检查anon key是否正确
# 确认使用的是 anon public key，不是 service_role key

# 2. 检查token是否过期
# 在Supabase Dashboard -> Authentication -> Users 查看用户状态

# 3. 刷新token
# 在Flutter中调用: await Supabase.instance.client.auth.refreshSession()

# 4. 检查RLS策略是否允许匿名访问
```

### 问题7: Edge Function环境变量未生效

**现象**: Edge Function中读取secrets返回undefined

**解决方案**:
```bash
# 1. 确认secret已设置
supabase secrets list

# 2. 重新设置secret
supabase secrets set SECRET_NAME=value

# 3. 重新部署函数（修改secret后需要重新部署）
supabase functions deploy <function-name>

# 4. 在代码中正确读取
# const secret = Deno.env.get('SECRET_NAME')
```

### 问题8: Realtime订阅不生效

**现象**: Flutter应用中无法收到Realtime更新

**解决方案**:
```sql
-- 1. 确认表已添加到publication
SELECT * FROM pg_publication_tables WHERE publication_name = 'supabase_realtime';

-- 2. 重新添加表
alter publication supabase_realtime add table <table_name>;

-- 3. 检查RLS策略是否允许Realtime
-- Realtime同样需要遵守RLS策略
```

---

## 参考链接

- [Supabase文档](https://supabase.com/docs)
- [PostGIS文档](https://postgis.net/documentation/)
- [Deno Deploy文档](https://deno.com/deploy/docs)
- [Flutter Supabase文档](https://supabase.com/docs/reference/dart/introduction)
