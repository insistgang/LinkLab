# Supabase Edge Functions - 志愿者匹配引擎

## 已实现功能

### 1. matching-engine (匹配引擎)

**文件位置**: `/supabase/functions/matching-engine/index.ts`

**功能**:
- 多维匹配算法: `匹配分 = 0.30×紧急度 + 0.25×地理距离 + 0.20×技能匹配 + 0.15×信誉分 + 0.10×历史亲密度`
- Haversine公式计算地理距离
- Top 5志愿者筛选
- 30秒超时扩大搜索范围
- 60秒转为异步留言
- 志愿者接单/拒绝处理

**API端点**:
- `POST /matching-engine` - 创建匹配请求
- `POST /matching-engine/timeout` - 处理超时
- `POST /matching-engine/accept` - 志愿者接单
- `POST /matching-engine/reject` - 志愿者拒绝

### 2. push-notifier (推送通知服务)

**文件位置**: `/supabase/functions/push-notifier/index.ts`

**功能**:
- FCM推送通知（匹配请求、匹配确认）
- SOS广播推送（5km范围内）
- 紧急联系人短信通知
- SOS升级策略（5分钟全城广播）

**API端点**:
- `POST /push-notifier` - 发送推送通知

**支持的通知类型**:
- `matching_request` - 匹配请求
- `matching_confirmed` - 匹配确认
- `sos_broadcast` - SOS广播
- `emergency_sms` - 紧急短信
- `sos_escalation` - SOS升级

### 3. Dart端服务

**RealMatchingService** (`lib/services/real_matching_service.dart`):
- 调用Edge Function进行匹配
- 匹配状态管理
- 超时处理
- 心跳维护
- 志愿者在线状态管理

**RealtimeSyncService** (`lib/services/realtime_sync_service.dart`):
- 志愿者状态实时订阅
- 求助状态实时同步
- 通话信令传输
- SOS状态订阅

## 数据库表

### 新增表

1. **help_request_matches** - 匹配记录表
2. **user_devices** - 用户设备表（FCM Token）
3. **sos_broadcast_logs** - SOS广播日志
4. **user_presence** - 用户在线状态
5. **help_request_heartbeats** - 求助心跳

### 扩展表

- **volunteer_profiles** - 添加`is_available`和`last_heartbeat_at`字段
- **help_requests** - 添加`required_skills`和`help_type`字段

### PostGIS函数

- `get_volunteers_in_radius(lat, lng, radius_km)` - 获取范围内的志愿者
- `update_volunteer_heartbeat(user_id, lat, lng)` - 更新志愿者心跳

## 部署说明

详见 [DEPLOYMENT.md](./DEPLOYMENT.md)

## 匹配算法详解

### 权重配置

```typescript
const MATCHING_WEIGHTS = {
  urgency: 0.30,      // 紧急度
  distance: 0.25,     // 地理距离
  skills: 0.20,       // 技能匹配
  credit: 0.15,       // 信誉分
  intimacy: 0.10,     // 历史亲密度
};
```

### 各维度计算

1. **紧急度**: normal=0.4, important=0.6, urgent=0.8, emergency=1.0
2. **地理距离**: `1 - min(距离/5km, 1)`
3. **技能匹配**: 匹配标签数 / 需求标签数
4. **信誉分**: credit_score / 5.0
5. **历史亲密度**: 简化版，默认0.5

## 流程图

```
求助者发起请求
    │
    ▼
创建help_requests记录
    │
    ▼
获取在线志愿者（5km内）
    │
    ▼
计算匹配分数（Top 5）
    │
    ▼
创建help_request_matches记录
    │
    ▼
并行发送FCM推送
    │
    ▼
等待志愿者响应（30秒）
    │
    ├── 有人接单 → 建立连接
    │
    └── 无人响应 → 扩大范围（Top 10）
            │
            ├── 有人接单 → 建立连接
            │
            └── 仍无响应（60秒）→ 转为异步
```

## 环境变量

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

## 测试

```bash
# 测试匹配引擎
curl -X POST https://your-project.supabase.co/functions/v1/matching-engine \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "seekerId": "test-user-id",
    "urgency": "urgent",
    "location": {"lat": 31.2304, "lng": 121.4737},
    "skills": ["医疗辅助"],
    "helpType": "测试求助"
  }'

# 测试推送通知
curl -X POST https://your-project.supabase.co/functions/v1/push-notifier \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "matching_request",
    "userId": "volunteer-user-id",
    "title": "有新的求助",
    "body": "距离您1km有人需要帮助"
  }'
```
