# Supabase Edge Functions 部署指南

## 概述

本文档说明如何部署志愿者匹配引擎相关的Supabase Edge Functions。

## 包含的Edge Functions

1. **matching-engine** - 志愿者匹配引擎
   - 路径: `/functions/v1/matching-engine`
   - 功能: 计算匹配分数、推送通知、超时处理

2. **push-notifier** - 推送通知服务
   - 路径: `/functions/v1/push-notifier`
   - 功能: FCM推送、SOS广播、紧急短信

## 前置条件

1. 安装Supabase CLI
```bash
npm install -g supabase
```

2. 登录Supabase
```bash
supabase login
```

3. 链接项目
```bash
supabase link --project-ref your-project-ref
```

## 环境变量配置

在Supabase Dashboard中设置以下环境变量:

### 必需变量

```bash
# Supabase配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# FCM配置（用于推送通知）
FCM_PROJECT_ID=your-firebase-project-id
FCM_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FCM_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
```

### 可选变量

```bash
# 短信服务商配置（用于SOS紧急短信）
SMS_PROVIDER=aliyun  # 或 twilio
SMS_ACCESS_KEY=your-access-key
SMS_SECRET_KEY=your-secret-key

# 语音电话配置（用于SOS升级）
VOICE_PROVIDER=twilio
VOICE_ACCOUNT_SID=your-account-sid
VOICE_AUTH_TOKEN=your-auth-token
```

## 部署步骤

### 1. 部署数据库迁移

```bash
# 在Supabase Dashboard的SQL Editor中执行
# 或运行:
supabase db push
```

### 2. 部署Edge Functions

```bash
# 部署所有函数
supabase functions deploy

# 或单独部署
supabase functions deploy matching-engine
supabase functions deploy push-notifier
```

### 3. 验证部署

```bash
# 获取JWT令牌
supabase tokens create

# 测试匹配引擎
curl -X POST https://your-project.supabase.co/functions/v1/matching-engine \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "seekerId": "test-user-id",
    "urgency": "urgent",
    "location": {"lat": 31.2304, "lng": 121.4737},
    "skills": ["医疗辅助"],
    "helpType": "测试求助"
  }'
```

## API文档

### matching-engine

#### POST /matching-engine

创建匹配请求。

**请求体:**
```json
{
  "seekerId": "string",
  "urgency": "normal|important|urgent|emergency",
  "location": {"lat": number, "lng": number},
  "skills": ["string"],
  "helpType": "string"
}
```

**响应:**
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
      "skills": ["医疗辅助"]
    }
  ],
  "timeoutAt": "2025-04-11T12:00:00Z"
}
```

#### POST /matching-engine/timeout

处理匹配超时。

**请求体:**
```json
{
  "helpRequestId": "uuid",
  "expandRange": true|false
}
```

#### POST /matching-engine/accept

志愿者接受匹配。

**请求体:**
```json
{
  "helpRequestId": "uuid",
  "volunteerId": "uuid"
}
```

#### POST /matching-engine/reject

志愿者拒绝匹配。

**请求体:**
```json
{
  "helpRequestId": "uuid",
  "volunteerId": "uuid"
}
```

### push-notifier

#### POST /push-notifier

发送推送通知。

**请求体 - 匹配请求:**
```json
{
  "type": "matching_request",
  "userId": "uuid",
  "title": "有新的求助需要您的帮助",
  "body": "距离您 1.2km 有人需要帮助",
  "data": {"helpRequestId": "uuid", "type": "matching_request"}
}
```

**请求体 - SOS广播:**
```json
{
  "type": "sos_broadcast",
  "sosId": "uuid",
  "location": {"lat": 31.2304, "lng": 121.4737},
  "radius": 5,
  "priority": "critical"
}
```

**请求体 - 紧急短信:**
```json
{
  "type": "emergency_sms",
  "contacts": ["+86138xxxxxxxx"],
  "message": "【共感LinkAble紧急求助】您的亲友触发了SOS求助..."
}
```

## 监控和日志

### 查看函数日志

```bash
# 实时查看日志
supabase functions logs matching-engine --tail

# 查看push-notifier日志
supabase functions logs push-notifier --tail
```

### 在Dashboard中查看

1. 进入Supabase Dashboard
2. 选择 Edge Functions
3. 点击函数名称查看日志和统计

## 故障排除

### 1. 函数部署失败

检查:
- 环境变量是否正确设置
- 代码语法错误
- 依赖包版本兼容性

### 2. FCM推送失败

检查:
- FCM_PROJECT_ID是否正确
- FCM_CLIENT_EMAIL和FCM_PRIVATE_KEY是否匹配
- Firebase项目是否启用了Cloud Messaging API

### 3. 匹配引擎返回空结果

检查:
- volunteer_profiles表是否有在线志愿者
- 志愿者位置数据是否正确
- PostGIS函数是否正确创建

### 4. Realtime订阅不工作

检查:
- 数据库表是否启用了Realtime
- RLS策略是否正确
- 客户端订阅代码是否正确

## 性能优化

### 1. 数据库索引

确保以下索引已创建:
```sql
CREATE INDEX idx_volunteer_profiles_online ON volunteer_profiles(is_online, is_available);
CREATE INDEX idx_volunteer_profiles_location ON volunteer_profiles(latitude, longitude);
CREATE INDEX idx_help_request_matches_status ON help_request_matches(status);
```

### 2. 函数配置

在`config.toml`中调整:
```toml
[functions.matching-engine]
verify_jwt = true
# 内存限制 (MB)
memory = 256
# 超时时间 (秒)
timeout = 30
```

## 更新和回滚

### 更新函数

```bash
# 修改代码后重新部署
supabase functions deploy matching-engine
```

### 回滚版本

```bash
# 查看历史版本
supabase functions list

# 回滚到特定版本（需要手动操作）
# 1. 从git历史恢复代码
# 2. 重新部署
```

## 安全注意事项

1. **JWT验证**: 生产环境必须启用`verify_jwt = true`
2. **服务角色密钥**: 仅在Edge Function内部使用，不要暴露给客户端
3. **FCM私钥**: 妥善保管，定期轮换
4. **RLS策略**: 确保数据库表有适当的访问控制

## 联系支持

如有问题，请联系:
- 技术负责人: [your-email]
- Supabase文档: https://supabase.com/docs
