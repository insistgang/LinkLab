# 共感 LinkAble 数据库设计文档

## 数据库关系图

```mermaid
erDiagram
    users ||--o| volunteer_profiles : "1:1 志愿者扩展"
    users ||--o{ help_requests : "1:N 发起求助"
    users ||--o{ help_requests : "1:N 作为志愿者帮助"
    users ||--o{ async_tasks : "1:N 发起任务"
    users ||--o{ point_transactions : "1:N 积分流水"
    users ||--o{ emergency_contacts : "1:N 紧急联系人"
    users ||--o{ reports : "1:N 举报"
    users ||--o{ reports : "1:N 被举报"
    
    help_requests ||--o{ async_tasks : "1:N 关联任务"
    help_requests ||--o{ call_records : "1:N 通话记录"
    
    volunteer_profiles ||--o{ async_tasks : "1:N 接单"
    
    users {
        uuid id PK
        string phone UK
        string name
        string avatar_url
        string[] role
        string[] disability_type
        jsonb preferences
        timestamp last_login_at
        boolean is_deleted
        timestamp created_at
        timestamp updated_at
    }
    
    volunteer_profiles {
        uuid user_id PK,FK
        string[] skills
        int level
        int points
        decimal credit_score
        boolean is_verified
        jsonb available_schedule
        boolean is_online
        timestamp last_heartbeat_at
        int total_help_count
        geography location
        timestamp created_at
        timestamp updated_at
    }
    
    help_requests {
        uuid id PK
        uuid seeker_id FK
        string type
        string intent
        string urgency
        string status
        jsonb ai_response
        uuid volunteer_id FK
        geography location
        int duration_seconds
        int seeker_rating
        int volunteer_rating
        string seeker_feedback
        string volunteer_feedback
        string cancel_reason
        timestamp matched_at
        timestamp completed_at
        timestamp created_at
        timestamp updated_at
    }
    
    async_tasks {
        uuid id PK
        uuid request_id FK
        uuid seeker_id FK
        uuid volunteer_id FK
        string title
        string description
        string type
        jsonb attachments
        string status
        string priority
        string result
        jsonb result_attachments
        timestamp deadline_at
        timestamp accepted_at
        timestamp completed_at
        timestamp created_at
        timestamp updated_at
    }
    
    point_transactions {
        uuid id PK
        uuid user_id FK
        string type
        int amount
        int balance
        string source
        uuid source_id
        string description
        timestamp created_at
    }
    
    emergency_contacts {
        uuid id PK
        uuid user_id FK
        string name
        string phone
        string relationship
        int priority
        boolean is_active
        boolean notify_on_sos
        timestamp created_at
        timestamp updated_at
    }
    
    reports {
        uuid id PK
        uuid reporter_id FK
        uuid reported_id FK
        string target_type
        uuid target_id
        string reason
        string description
        jsonb evidence
        string status
        string result
        uuid handled_by FK
        timestamp handled_at
        timestamp created_at
        timestamp updated_at
    }
    
    call_records {
        uuid id PK
        uuid request_id FK
        uuid seeker_id FK
        uuid volunteer_id FK
        string call_type
        string status
        timestamp started_at
        timestamp ended_at
        int duration_seconds
        string end_reason
        int ice_candidate_count
        int quality_score
        timestamp created_at
    }
    
    ai_response_cache {
        string query_hash PK
        string query_type
        jsonb response
        int hit_count
        timestamp created_at
        timestamp expires_at
    }
```

## 表结构详细说明

### 1. users (用户基础表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键，用户唯一标识 |
| phone | TEXT | 手机号，用于登录，唯一 |
| name | TEXT | 用户昵称 |
| avatar_url | TEXT | 头像URL |
| role | TEXT[] | 角色数组：seeker(求助者), volunteer(志愿者)，支持双角色 |
| disability_type | TEXT[] | 障碍类型：visual(视障), hearing(听障), physical(肢体), elderly(老年), temporary(临时) |
| preferences | JSONB | 无障碍偏好配置 |
| last_login_at | TIMESTAMPTZ | 最后登录时间 |
| is_deleted | BOOLEAN | 软删除标记 |

### 2. volunteer_profiles (志愿者扩展表)

| 字段 | 类型 | 说明 |
|------|------|------|
| user_id | UUID | 主键/外键，关联users.id |
| skills | TEXT[] | 技能标签：medical(医疗), guide(导盲), tech(技术), sign(手语), elderly(敬老), child(儿童), daily(日常) |
| level | INT | 等级1-7，根据积分自动计算 |
| points | INT | 当前积分 |
| credit_score | DECIMAL(2,1) | 信用分1-5 |
| is_verified | BOOLEAN | 是否实名认证 |
| available_schedule | JSONB | 可服务时间段配置 |
| is_online | BOOLEAN | 在线状态 |
| last_heartbeat_at | TIMESTAMPTZ | 最后心跳时间 |
| total_help_count | INT | 累计帮助次数 |
| location | GEOGRAPHY(POINT,4326) | 实时位置坐标(WGS84) |

### 3. help_requests (求助记录表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| seeker_id | UUID | 求助者ID |
| type | TEXT | 类型：ai_auto, async, realtime_voice, realtime_video, sos |
| intent | TEXT | AI识别的意图 |
| urgency | TEXT | 紧急程度：normal, important, urgent, emergency |
| status | TEXT | 状态：pending, ai_resolved, matching, matched, connected, completed, cancelled |
| ai_response | JSONB | AI处理结果缓存 |
| volunteer_id | UUID | 匹配的志愿者ID |
| location | GEOGRAPHY(POINT,4326) | 求助位置 |
| duration_seconds | INT | 通话时长(秒) |
| seeker_rating | INT | 求助者给志愿者的评分1-5 |
| volunteer_rating | INT | 志愿者给求助者的评分1-5 |
| matched_at | TIMESTAMPTZ | 匹配成功时间 |
| completed_at | TIMESTAMPTZ | 完成时间 |

### 4. async_tasks (异步任务表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| request_id | UUID | 关联的求助记录ID |
| seeker_id | UUID | 求助者ID |
| volunteer_id | UUID | 接单的志愿者ID |
| title | TEXT | 任务标题 |
| description | TEXT | 任务描述 |
| type | TEXT | 类型：ocr, scene_desc, translation, guidance, other |
| status | TEXT | 状态：pending, accepted, processing, completed, cancelled, expired |
| priority | TEXT | 优先级：low, normal, high, urgent |
| result | TEXT | 处理结果 |
| deadline_at | TIMESTAMPTZ | 截止时间 |

### 5. point_transactions (积分流水表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| user_id | UUID | 用户ID |
| type | TEXT | 类型：earn(获得), spend(消耗), bonus(奖励), penalty(扣除) |
| amount | INT | 积分变化量(正数增加，负数减少) |
| balance | INT | 变动后余额 |
| source | TEXT | 来源：help_complete, task_complete, sign_in, exchange, system |
| source_id | UUID | 关联记录ID |

### 6. emergency_contacts (紧急联系人表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| user_id | UUID | 用户ID |
| name | TEXT | 联系人姓名 |
| phone | TEXT | 联系人电话 |
| relationship | TEXT | 关系 |
| priority | INT | 优先级(1最高) |
| is_active | BOOLEAN | 是否启用 |
| notify_on_sos | BOOLEAN | SOS时是否通知 |

### 7. reports (举报表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| reporter_id | UUID | 举报人ID |
| reported_id | UUID | 被举报人ID |
| target_type | TEXT | 举报对象类型：user, help_request, async_task |
| target_id | UUID | 举报对象ID |
| reason | TEXT | 举报原因：harassment, fraud, inappropriate, spam, other |
| description | TEXT | 详细描述 |
| evidence | JSONB | 证据附件 |
| status | TEXT | 状态：pending, investigating, resolved, rejected |
| result | TEXT | 处理结果 |
| handled_by | UUID | 处理人ID |
| handled_at | TIMESTAMPTZ | 处理时间 |

### 8. call_records (通话记录表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| request_id | UUID | 关联的求助记录ID |
| seeker_id | UUID | 求助者ID |
| volunteer_id | UUID | 志愿者ID |
| call_type | TEXT | 通话类型：voice, video |
| status | TEXT | 状态：initiated, connected, ended, failed |
| started_at | TIMESTAMPTZ | 开始时间 |
| ended_at | TIMESTAMPTZ | 结束时间 |
| duration_seconds | INT | 通话时长(秒) |
| end_reason | TEXT | 结束原因：normal, network_error, user_hangup, timeout |
| ice_candidate_count | INT | ICE候选数量(网络质量指标) |
| quality_score | INT | 通话质量评分1-5 |

### 9. ai_response_cache (AI响应缓存表)

| 字段 | 类型 | 说明 |
|------|------|------|
| query_hash | TEXT | 主键，查询内容的哈希值 |
| query_type | TEXT | 查询类型：ocr, scene_desc, asr, translation |
| response | JSONB | AI响应结果 |
| hit_count | INT | 命中次数 |
| created_at | TIMESTAMPTZ | 创建时间 |
| expires_at | TIMESTAMPTZ | 过期时间 |

## 索引列表

### 性能关键索引

| 表名 | 索引名 | 类型 | 用途 |
|------|--------|------|------|
| users | idx_users_phone | B-Tree | 手机号登录查询，支持快速用户认证 |
| users | idx_users_role | GIN | 角色筛选，支持多角色查询 |
| users | idx_users_created_at | B-Tree | 用户注册时间排序 |
| volunteer_profiles | idx_volunteer_location | GIST | 地理位置空间查询，用于附近志愿者匹配 |
| volunteer_profiles | idx_volunteer_online | B-Tree | 在线志愿者查询，配合is_online字段 |
| volunteer_profiles | idx_volunteer_skills | GIN | 技能标签匹配，支持多技能筛选 |
| volunteer_profiles | idx_volunteer_points | B-Tree | 积分排行查询 |
| volunteer_profiles | idx_volunteer_heartbeat | B-Tree | 清理离线志愿者时查询 |
| help_requests | idx_help_status_urgency | B-Tree | 匹配查询，按状态和紧急程度筛选 |
| help_requests | idx_help_location | GIST | 附近求助空间查询 |
| help_requests | idx_help_seeker_id | B-Tree | 查询用户的求助历史 |
| help_requests | idx_help_volunteer_id | B-Tree | 查询志愿者的帮助记录 |
| help_requests | idx_help_created_at | B-Tree | 求助记录时间排序 |
| async_tasks | idx_async_status | B-Tree | 任务队列查询，按状态筛选 |
| async_tasks | idx_async_volunteer_id | B-Tree | 查询志愿者的任务列表 |
| async_tasks | idx_async_deadline | B-Tree | 即将过期任务提醒 |
| point_transactions | idx_points_user_id | B-Tree | 查询用户积分流水 |
| point_transactions | idx_points_created_at | B-Tree | 积分记录时间排序 |
| emergency_contacts | idx_emergency_user_id | B-Tree | 查询用户的紧急联系人 |
| reports | idx_reports_status | B-Tree | 待处理举报查询 |
| reports | idx_reports_target | B-Tree | 查询针对特定对象的举报 |
| call_records | idx_call_request_id | B-Tree | 查询求助关联的通话记录 |
| ai_response_cache | idx_cache_expires | B-Tree | 清理过期缓存 |

## RLS策略摘要

### 策略详细说明

| 表名 | 策略名 | 操作 | 说明 |
|------|--------|------|------|
| users | user_self_full_access | ALL | 用户只能修改自己的数据，`auth.uid() = id` |
| users | user_public_read | SELECT | 认证用户可查看其他用户基本信息，排除敏感字段 |
| volunteer_profiles | volunteer_self_access | ALL | 志愿者管理自己的资料，`auth.uid() = user_id` |
| volunteer_profiles | volunteer_public_read | SELECT | 公开信息(不含精确位置)，仅返回必要字段 |
| volunteer_profiles | volunteer_location_for_matching | SELECT | 匹配过程中求助者可查看位置，需通过匹配验证 |
| help_requests | help_seeker_access | ALL | 求助者管理自己的求助，`auth.uid() = seeker_id` |
| help_requests | help_volunteer_access | SELECT,UPDATE | 志愿者查看和更新分配到的求助，`auth.uid() = volunteer_id` |
| async_tasks | task_seeker_access | ALL | 求助者管理自己的任务 |
| async_tasks | task_volunteer_access | SELECT,UPDATE | 志愿者查看和接受任务 |
| point_transactions | points_self_read | SELECT | 用户只能查看自己的积分流水 |
| emergency_contacts | emergency_self_access | ALL | 用户管理自己的紧急联系人 |
| reports | reporter_access | SELECT,INSERT | 举报人可查看自己提交的举报 |
| reports | admin_access | ALL | 管理员可处理所有举报 |
| call_records | call_participant_access | SELECT | 通话参与者可查看记录 |
| ai_response_cache | public_read | SELECT | 所有认证用户可读缓存 |

## 触发器和函数

### 数据库触发器

| 触发器名 | 表名 | 触发时机 | 功能说明 |
|----------|------|----------|----------|
| trg_update_volunteer_level | volunteer_profiles | AFTER UPDATE | 根据积分自动计算志愿者等级 (1-7级) |
| trg_update_help_count | help_requests | AFTER UPDATE | 求助完成时更新志愿者的累计帮助次数 |
| trg_calculate_credit_score | help_requests | AFTER UPDATE | 根据评分自动计算志愿者信用分 |
| trg_task_expired_check | async_tasks | BEFORE UPDATE | 检查任务是否已过期，自动更新状态 |
| trg_user_soft_delete | users | BEFORE UPDATE | 软删除时清理敏感信息 |
| trg_cache_hit_increment | ai_response_cache | BEFORE SELECT | 缓存命中时自动增加hit_count |

### 数据库函数

| 函数名 | 参数 | 返回值 | 功能说明 |
|--------|------|--------|----------|
| calculate_volunteer_level | points INT | INT | 根据积分计算等级：1级(0-99), 2级(100-299), 3级(300-599), 4级(600-999), 5级(1000-1499), 6级(1500-2099), 7级(2100+) |
| calculate_credit_score | ratings INT[] | DECIMAL | 根据历史评分计算信用分(1-5分) |
| find_nearest_volunteers | lat FLOAT, lng FLOAT, radius_meters INT, skills TEXT[] | TABLE | 查找附近符合条件的志愿者 |
| get_user_points_balance | user_id UUID | INT | 获取用户当前积分余额 |
| add_point_transaction | user_id UUID, type TEXT, amount INT, source TEXT, source_id UUID | VOID | 添加积分流水并更新余额 |
| cleanup_expired_cache | VOID | INT | 清理过期的AI缓存，返回清理数量 |

### Edge Functions

| 函数名 | 功能 | 触发方式 |
|--------|------|----------|
| matching-engine | 志愿者匹配算法 | HTTP POST |
| ai-dispatcher | AI服务调度(OCR/ASR/TTS/VL) | HTTP POST |
| push-notifier | 推送通知(FCM) | HTTP POST |
| points-calculator | 积分计算和等级更新 | HTTP POST / Webhook |
