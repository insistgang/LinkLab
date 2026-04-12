# 共感 LinkAble 技术架构分析报告

> **分析范围**：PRD 第四章至第七章  
> **生成日期**：2026-04-10  
> **版本**：v1.0

---

## 目录

- [1. 技术栈梳理](#1-技术栈梳理)
- [2. 数据库设计评审](#2-数据库设计评审)
- [3. 开发里程碑](#3-开发里程碑)
- [4. 性能指标与技术方案对应](#4-性能指标与技术方案对应)
- [5. 第三方服务成本明细](#5-第三方服务成本明细)
- [6. 风险与应对](#6-风险与应对)
- [7. 总结与建议](#7-总结与建议)

---

## 1. 技术栈梳理

### 1.1 整体架构图

```text
┌─────────────────────────────────────────────────────────────┐
│                      客户端层 (Flutter)                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │   无障碍UI    │ │   语音交互    │ │     相机模块          │ │
│  │  - Semantics │ │  - ASR/TTS   │ │   - OCR/识别/颜色    │ │
│  │  - 高对比度   │ │  - 语音唤醒   │ │   - 多模态输入       │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │  WebRTC通话   │ │  状态管理     │ │     本地AI推理       │ │
│  │  - P2P语音   │ │  - Riverpod  │ │   - PaddleOCR Lite   │ │
│  │  - 视频/屏幕  │ │  - 类型安全   │ │   - 颜色识别         │ │
│  └──────┬───────┘ └──────────────┘ └──────────────────────┘ │
└─────────┼───────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                     BaaS层 (Supabase)                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │    Auth      │ │   Database   │ │      Realtime        │ │
│  │  - 手机号    │ │ - PostgreSQL │ │    - WebSocket       │ │
│  │  - 微信登录  │ │ - RLS策略    │ │    - 信令通道        │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
│  ┌──────────────┐ ┌────────────────────────────────────────┐ │
│  │   Storage    │ │        Edge Functions (Deno)           │ │
│  │  - 文件存储  │ │  - 匹配算法 / 积分计算 / 推送触发      │ │
│  │  - 录音存储  │ │  - AI调度 / 紧急检测                   │ │
│  └──────────────┘ └────────────────────────────────────────┘ │
└──────────────────────────────┬──────────────────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│    AI服务层      │  │    地图服务      │  │    推送服务      │
│  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │
│  │  百度OCR   │  │  │  │  高德地图  │  │  │ │    FCM    │  │
│  │ PaddleOCR │  │  │  │  - 定位   │  │  │ │ 厂商SDK   │  │
│  └───────────┘  │  │  │  - 导航   │  │  │ │ 华为/小米 │  │
│  ┌───────────┐  │  │  └───────────┘  │  │ │ OPPO/vivo │  │
│  │ 科大讯飞   │  │  └─────────────────┘  │ └───────────┘  │
│  │ ASR + TTS │  │                       └─────────────────┘
│  └───────────┘  │
│  ┌───────────┐  │
│  │ 通义千问VL │  │
│  │Kimi Vision│  │
│  └───────────┘  │
└─────────────────┘
```

### 1.2 技术选型明细表

| 层级 | 技术 | 版本/方案 | 选型理由 | 风险点 |
|------|------|-----------|----------|--------|
| **前端框架** | Flutter | 3.x + Dart | 跨平台(iOS/Android)，内置Semantics无障碍支持，热重载开发效率高 | 包体积较大，需优化 |
| **状态管理** | Riverpod | 2.x | 类型安全，编译时错误检测，适合复杂状态 | 学习曲线较陡 |
| **后端BaaS** | Supabase | Cloud/自托管 | PostgreSQL+Auth+Realtime+Storage一体，降低后端开发成本 | 国内访问需CDN加速 |
| **实时通信** | WebRTC | flutter_webrtc | P2P直连低延迟，Supabase Realtime做信令 | NAT穿透需TURN服务器 |
| **地图服务** | 高德地图 | Flutter插件 | 中国合规，室内定位+步行导航完善 | 仅中国可用 |
| **OCR在线** | 百度OCR | REST API | 中文识别率高，免费额度5万次/月 | 离线不可用 |
| **OCR离线** | PaddleOCR | Lite本地模型 | 无网络可用，保护隐私 | 精度略低于在线 |
| **语音ASR/TTS** | 科大讯飞 | 流式API | 中文识别最优，支持方言 | 费用较高 |
| **视觉理解** | 通义千问VL | API | 多模态场景描述能力强 | Token费用需控制 |
| **视觉备选** | Kimi Vision | API | 备选方案，防止单点故障 | 同上 |
| **推送服务** | FCM + 厂商SDK | 华为/小米/OPPO/vivo | FCM免费，国内必须走厂商通道 | 集成复杂度高 |

### 1.3 无障碍技术方案

| 需求 | 技术实现 | 优先级 |
|------|----------|--------|
| 屏幕阅读器支持 | Flutter Semantics + TalkBack/VoiceOver | P0 |
| 高对比度 | WCAG 2.1 AAA标准 (≥7:1) | P0 |
| 触摸目标 | ≥48×48 dp | P0 |
| 动态字体 | 支持系统级字体缩放 | P0 |
| 语音唤醒 | "Hey 智动"唤醒词检测 | P0 |
| 紧急快捷 | 连按电源键3次触发SOS | P0 |
| 焦点顺序 | 逻辑一致的Tab顺序 | P0 |
| 错误提示 | 颜色+图标+文字三重提示 | P0 |

---

## 2. 数据库设计评审

### 2.1 核心表结构分析

```text
┌─────────────────────────────────────────────────────────────────┐
│                        数据库关系图                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────┐         ┌──────────────────┐                 │
│   │    users    │◄────────┤ volunteer_profiles│                 │
│   │  (用户基础)  │   1:1   │   (志愿者扩展)    │                 │
│   └──────┬──────┘         └──────────────────┘                 │
│          │                                                      │
│          │ 1:N                                                  │
│          ▼                                                      │
│   ┌─────────────┐         ┌──────────────────┐                 │
│   │help_requests│◄────────┤   async_tasks    │                 │
│   │  (求助记录)  │         │   (异步任务)      │                 │
│   └──────┬──────┘         └──────────────────┘                 │
│          │                                                      │
│          │ 1:N                                                  │
│          ▼                                                      │
│   ┌─────────────────┐    ┌──────────────────┐                  │
│   │point_transactions │   │     reports      │                  │
│   │    (积分流水)    │    │     (举报)       │                  │
│   └─────────────────┘    └──────────────────┘                  │
│                                                                 │
│   ┌─────────────────────────────────────────┐                  │
│   │        emergency_contacts               │                  │
│   │           (紧急联系人)                   │                  │
│   └─────────────────────────────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 表结构详细设计

#### users (用户基础表)
```sql
users (
  id UUID PK,
  phone TEXT UNIQUE,          -- 手机号登录
  name TEXT,                  -- 昵称
  avatar_url TEXT,            -- 头像URL
  role TEXT[],                -- ['seeker', 'volunteer'] 可双角色
  disability_type TEXT[],     -- ['visual', 'hearing', 'physical', 'elderly', 'temporary']
  preferences JSONB,          -- 无障碍偏好配置
  created_at TIMESTAMPTZ
)
```
**评审意见**：
- ✅ role使用数组支持双角色场景
- ✅ preferences用JSONB支持灵活配置
- ⚠️ 建议添加 `last_login_at` 字段用于活跃度分析
- ⚠️ 建议添加 `is_deleted` 软删除标记

#### volunteer_profiles (志愿者扩展表)
```sql
volunteer_profiles (
  user_id UUID FK → users,
  skills TEXT[],              -- 技能标签数组
  level INT DEFAULT 1,        -- 等级 1-7
  points INT DEFAULT 0,       -- 积分
  credit_score DECIMAL DEFAULT 5.0,  -- 信用分 1-5
  is_verified BOOLEAN DEFAULT FALSE, -- 实名认证
  available_schedule JSONB,   -- 排班配置
  is_online BOOLEAN DEFAULT FALSE,   -- 在线状态
  location GEOGRAPHY(POINT)   -- PostGIS地理坐标
)
```
**评审意见**：
- ✅ 使用PostGIS支持地理查询
- ✅ JSONB存储排班灵活可扩展
- ⚠️ `is_online` 需配合心跳机制，建议增加 `last_heartbeat_at`
- ⚠️ 建议添加 `total_help_count` 累计帮助次数，避免实时计算

#### help_requests (求助记录表)
```sql
help_requests (
  id UUID PK,
  seeker_id UUID FK → users,
  type TEXT,                  -- 'ai_auto', 'async', 'realtime_voice', 'realtime_video', 'sos'
  intent TEXT,                -- AI识别的意图
  urgency TEXT,               -- 'normal', 'important', 'urgent', 'emergency'
  status TEXT,                -- 'pending', 'ai_resolved', 'matching', 'connected', 'completed', 'cancelled'
  ai_response JSONB,          -- AI处理结果缓存
  volunteer_id UUID FK → users,
  location GEOGRAPHY(POINT),
  duration_seconds INT,       -- 通话时长
  seeker_rating INT,          -- 1-5星评价
  volunteer_rating INT,
  created_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
)
```
**评审意见**：
- ✅ 状态机设计完整
- ✅ JSONB存储AI响应支持多模态结果
- ⚠️ 建议添加 `matched_at` 记录匹配成功时间（用于计算匹配耗时KPI）
- ⚠️ 建议添加 `cancel_reason` 取消原因分析

### 2.3 索引建议

```sql
-- 用户表索引
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users USING GIN(role);
CREATE INDEX idx_users_disability ON users USING GIN(disability_type);

-- 志愿者表索引
CREATE INDEX idx_volunteer_location ON volunteer_profiles USING GIST(location);
CREATE INDEX idx_volunteer_online ON volunteer_profiles(is_online, is_verified);
CREATE INDEX idx_volunteer_skills ON volunteer_profiles USING GIN(skills);
CREATE INDEX idx_volunteer_credit ON volunteer_profiles(credit_score DESC);

-- 求助记录表索引
CREATE INDEX idx_help_seeker ON help_requests(seeker_id, created_at DESC);
CREATE INDEX idx_help_volunteer ON help_requests(volunteer_id, created_at DESC);
CREATE INDEX idx_help_status ON help_requests(status, urgency);
CREATE INDEX idx_help_location ON help_requests USING GIST(location);
CREATE INDEX idx_help_created ON help_requests(created_at DESC);

-- 异步任务表索引
CREATE INDEX idx_async_status ON async_tasks(status, created_at);
CREATE INDEX idx_async_volunteer ON async_tasks(volunteer_id);

-- 积分流水表索引
CREATE INDEX idx_points_user ON point_transactions(user_id, created_at DESC);
```

### 2.4 RLS (Row Level Security) 策略建议

```sql
-- 用户只能查看自己的敏感信息
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_self_access ON users
  FOR ALL
  USING (auth.uid() = id);

-- 志愿者位置仅匹配时可见
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

## 3. 开发里程碑

### 3.1 MVP 4周详细计划拆解

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MVP 开发时间线                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  W1: 项目搭建 + 基础UI                                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ [Day 1-2] 项目初始化                                                  │   │
│  │  - Flutter项目搭建 + 目录结构                                         │   │
│  │  - Supabase项目创建 + 数据库初始化                                    │   │
│  │  - CI/CD配置 (GitHub Actions)                                         │   │
│  │                                                                       │   │
│  │ [Day 3-4] 认证模块                                                    │   │
│  │  - 手机号+验证码登录                                                  │   │
│  │  - 微信登录集成                                                       │   │
│  │  - 首次引导流程 (身份/障碍/偏好)                                      │   │
│  │                                                                       │   │
│  │ [Day 5-7] 首页框架 + 无障碍适配                                       │   │
│  │  - 底部导航 (4 Tab)                                                   │   │
│  │  - 超大按钮组件                                                       │   │
│  │  - 全局Semantics适配                                                  │   │
│  │  - 高对比度主题                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  W2: AI Agent 核心                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ [Day 8-9] OCR文字识别                                                 │   │
│  │  - 相机拍照模块                                                       │   │
│  │  - 百度OCR API集成                                                    │   │
│  │  - TTS朗读结果                                                        │   │
│  │                                                                       │   │
│  │ [Day 10-11] 场景描述 (多模态)                                         │   │
│  │  - 通义千问VL API集成                                                 │   │
│  │  - 图片上传 + 结果解析                                                │   │
│  │                                                                       │   │
│  │ [Day 12] 颜色识别                                                     │   │
│  │  - 本地CV算法实现                                                     │   │
│  │  - 色盲友好描述                                                       │   │
│  │                                                                       │   │
│  │ [Day 13-14] 智能对话框架                                              │   │
│  │  - 意图识别基础                                                       │   │
│  │  - 多轮对话上下文                                                     │   │
│  │  - 紧急关键词检测                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  W3: 志愿者匹配 + 通话                                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ [Day 15-16] 匹配算法 (简化版)                                         │   │
│  │  - 在线志愿者查询                                                     │   │
│  │  - 基础匹配分计算                                                     │   │
│  │  - Top 5推送逻辑                                                      │   │
│  │                                                                       │   │
│  │ [Day 17-18] WebRTC语音通话                                            │   │
│  │  - 信令服务器 (Supabase Realtime)                                     │   │
│  │  - P2P连接建立                                                        │   │
│  │  - 语音通话UI                                                         │   │
│  │                                                                       │   │
│  │ [Day 19-20] 推送通知                                                  │   │
│  │  - FCM集成                                                            │   │
│  │  - 厂商推送SDK调研                                                    │   │
│  │  - 志愿者接单推送                                                     │   │
│  │  - 双向评价系统                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  W4: 打磨 + 演示                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ [Day 21-22] SOS流程                                                   │   │
│  │  - 紧急关键词检测优化                                                 │   │
│  │  - 电源键快捷触发                                                     │   │
│  │  - 广播推送逻辑                                                       │   │
│  │  - 紧急联系人通知                                                     │   │
│  │                                                                       │   │
│  │ [Day 23-24] 异步求助 (简化)                                           │   │
│  │  - 任务提交                                                           │   │
│  │  - 任务队列展示                                                       │   │
│  │                                                                       │   │
│  │ [Day 25-26] Bug修复 + 优化                                            │   │
│  │  - 性能优化                                                           │   │
│  │  - 无障碍测试                                                         │   │
│  │                                                                       │   │
│  │ [Day 27-28] 演示视频录制                                              │   │
│  │  - 演示脚本准备                                                       │   │
│  │  - 视频录制 + 剪辑                                                    │   │
│  │  - 竞赛材料提交                                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 MVP 功能清单 (P0)

| 模块 | 功能 | PRD编号 | 负责人 | 状态 |
|------|------|---------|--------|------|
| 首页 | 首页框架 | F0 | TBD | 待开发 |
| AI Agent | 智能对话 | F1 | TBD | 待开发 |
| AI Agent | OCR识别+朗读 | F2 | TBD | 待开发 |
| AI Agent | 场景识别 | F3 | TBD | 待开发 |
| AI Agent | 颜色识别 | F4 | TBD | 待开发 |
| AI Agent | 紧急检测 | F8 | TBD | 待开发 |
| 志愿者 | 匹配引擎 | F9 | TBD | 待开发 |
| 志愿者 | 语音通话 | F11 | TBD | 待开发 |
| 志愿者 | SOS广播 | F13 | TBD | 待开发 |
| 用户中心 | 偏好设置 | F17 | TBD | 待开发 |
| 安全 | 认证体系 | F28 | TBD | 待开发 |
| 安全 | 双向互评 | F30 | TBD | 待开发 |
| 系统 | 登录注册 | F33 | TBD | 待开发 |
| 系统 | 消息推送 | F34 | TBD | 待开发 |
| 系统 | 无障碍适配 | F36 | TBD | 贯穿全程 |

### 3.3 V1.0 阶段任务清单

| 模块 | 任务 | 预计工期 | 依赖 |
|------|------|----------|------|
| **AI增强** | 钞票识别 | 1周 | MVP完成 |
| | 翻译功能 | 1周 | MVP完成 |
| | 离线OCR (PaddleOCR) | 2周 | MVP完成 |
| | 多轮对话优化 | 1周 | MVP完成 |
| **通信增强** | 视频通话 | 2周 | WebRTC基础 |
| | 屏幕共享 | 1周 | 视频通话 |
| **志愿者体系** | 完整等级系统 | 1周 | MVP完成 |
| | 积分/徽章系统 | 1周 | 等级系统 |
| | 排班管理 | 1周 | - |
| | 异步任务队列 | 2周 | - |
| **社群** | 精选故事 | 1周 | - |
| | 新手村 | 1周 | - |
| | 兴趣小组 | 2周 | - |
| **安全** | 通话录音+AI检测 | 2周 | 视频通话 |
| | 举报处理流程 | 1周 | - |
| **运营** | Web后台-用户管理 | 1周 | - |
| | Web后台-数据看板 | 2周 | - |

### 3.4 依赖关系图

```text
MVP基础
  │
  ├──► AI增强功能 ────────┐
  │                        │
  ├──► 通信增强 ──► 安全增强 │
  │       │                │
  │       └──────────────► V1.0完整版
  │                        ▲
  ├──► 志愿者体系完善 ─────┘
  │
  └──► 社群功能 ───────────┘
```

---

## 4. 性能指标与技术方案对应

### 4.1 性能指标达成方案

| 指标 | 目标值 | 技术实现方案 | 监控方案 |
|------|--------|--------------|----------|
| **AI首次响应** | ≤3秒 | 1. 流式API响应，首包时间<1s<br>2. 本地意图识别缓存<br>3. 轻量模型优先策略 | Supabase Logs + 自定义埋点 |
| **匹配耗时** | ≤30秒 | 1. PostGIS地理索引加速查询<br>2. 在线志愿者Redis缓存<br>3. 并行推送FCM | 匹配流程埋点，记录各阶段耗时 |
| **通话建立** | ≤5秒 | 1. WebRTC P2P直连<br>2. Supabase Realtime信令<br>3. ICE服务器预连接 | WebRTC统计API |
| **App冷启动** | ≤3秒 | 1. Flutter引擎预加载<br>2. 首屏数据并行加载<br>3. 图片懒加载 | Flutter性能监控 |
| **推送延迟** | ≤2秒 | 1. FCM高优先级通道<br>2. 厂商推送并行<br>3. 本地推送兜底 | FCM送达回执 |

### 4.2 性能优化技术细节

#### AI响应优化

```dart
// 流式响应处理
class AIStreamService {
  Stream<String> getStreamResponse(String input) async* {
    final response = await http.Client().send(
      http.Request('POST', Uri.parse(apiUrl))
        ..body = jsonEncode({'input': input, 'stream': true})
    );

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      yield chunk; // 逐字输出，降低 perceived latency
    }
  }
}
```

#### 匹配查询优化

```sql
-- 使用PostGIS + 在线状态索引
SELECT
  vp.user_id,
  vp.skills,
  ST_Distance(vp.location, seeker_location) as distance,
  vp.credit_score
FROM volunteer_profiles vp
WHERE
  vp.is_online = true
  AND vp.is_verified = true
  AND ST_DWithin(vp.location, seeker_location, 50000) -- 50km内
  AND vp.skills && ARRAY['medical'] -- 技能匹配
ORDER BY
  vp.credit_score DESC,
  ST_Distance(vp.location, seeker_location)
LIMIT 5;
```

#### WebRTC连接优化

```dart
// ICE配置优化
final iceServers = [
  {'urls': 'stun:stun.l.google.com:19302'},
  {'urls': 'turn:turn.supabase.co:3478', 'username': '...', 'credential': '...'},
];

// 预连接策略
class WebRTCManager {
  RTCPeerConnection? _preparedConnection;

  Future<void> prepareConnection() async {
    _preparedConnection = await createPeerConnection({
      'iceServers': iceServers,
      'iceTransportPolicy': 'all',
    });
    // 提前收集ICE候选
  }
}
```

---

## 5. 第三方服务成本明细

### 5.1 MVP阶段费用预估 (月)

| 服务 | 免费额度 | 预估用量 | 单价 | 月费用 | 备注 |
|------|----------|----------|------|--------|------|
| **Supabase** | 500MB/月 | 1GB | Pro $25 | ¥175 | 或先用Free tier |
| **百度OCR** | 50,000次/月 | 30,000次 | ¥0 | ¥0 | 通用文字识别 |
| **科大讯飞ASR** | 20,000次/月 | 15,000次 | ¥0 | ¥0 | 免费额度内 |
| **科大讯飞TTS** | 20,000次/月 | 10,000次 | ¥0 | ¥0 | 免费额度内 |
| **通义千问VL** | - | 50,000 tokens | ¥0.003/1K | ¥150 | 按Token计费 |
| **高德地图** | 50,000次/天 | 10,000次/天 | ¥0 | ¥0 | 免费额度足够 |
| **FCM推送** | 无限制 | - | 免费 | ¥0 | 完全免费 |
| **厂商推送** | - | - | - | ¥0 | SDK免费 |
| **WebRTC** | - | - | - | ¥0 | P2P免费 |
| **合计** | - | - | - | **¥175-325** | 可控范围 |

### 5.2 V1.0阶段费用预估 (月)

| 服务 | 预估用量 | 单价 | 月费用 | 增长原因 |
|------|----------|------|--------|----------|
| **Supabase** | 10GB + 100万请求 | Pro $25 | ¥175 | 数据增长 |
| **百度OCR** | 100,000次 | ¥0.002/次 | ¥200 | 超免费额度 |
| **科大讯飞ASR** | 100,000次 | ¥0.008/次 | ¥640 | 用量增长 |
| **科大讯飞TTS** | 80,000次 | ¥0.005/次 | ¥320 | 用量增长 |
| **通义千问VL** | 500,000 tokens | ¥0.003/1K | ¥1,500 | 功能增强 |
| **PaddleOCR** | 本地运行 | - | ¥0 | 离线方案 |
| **高德地图** | 50,000次/天 | ¥0 | ¥0 | 仍在免费额 |
| **FCM推送** | 500,000次 | 免费 | ¥0 | 免费 |
| **合计** | - | - | **¥2,835** | 需控制成本 |

### 5.3 成本控制建议

#### 策略1: 分级AI调用

```dart
class AICostController {
  Future<String> process(String input, {String? imageUrl}) async {
    // 简单任务用轻量模型
    if (isSimpleQuery(input)) {
      return await callLightModel(input); // 成本低
    }

    // 视觉任务用VL模型
    if (imageUrl != null) {
      return await callVLModel(input, imageUrl); // 成本高但必要
    }

    // 默认用中等模型
    return await callStandardModel(input);
  }
}
```

#### 策略2: 缓存常见查询

```sql
-- 创建查询结果缓存表
CREATE TABLE ai_response_cache (
  query_hash TEXT PRIMARY KEY,  -- 查询内容哈希
  response JSONB,               -- 缓存结果
  hit_count INT DEFAULT 1,      -- 命中次数
  created_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ        -- 过期时间
);

-- 查询时先查缓存
SELECT response FROM ai_response_cache
WHERE query_hash = '...' AND expires_at > NOW();
```

#### 策略3: 离线能力优先
| 功能 | 在线方案 | 离线方案 | 建议 |
|------|----------|----------|------|
| OCR | 百度OCR | PaddleOCR Lite | 离线优先，失败转在线 |
| 颜色识别 | 云端CV | 本地算法 | 完全离线 |
| 意图识别 | 大模型 | 本地规则引擎 | 简单意图本地处理 |
| TTS | 讯飞API | 系统TTS | 非关键场景用系统TTS |

### 5.4 成本监控Dashboard指标

```yaml
# 监控指标配置
监控指标:
  - 每日API调用次数 (按服务分类)
  - 每日Token消耗量
  - 缓存命中率
  - 平均每次求助成本
  - 月度成本趋势

告警阈值:
  - 单日API调用 > 5000次
  - 单日成本 > ¥100
  - 月度成本 > 预算的80%
```

---

## 6. 风险与应对

### 6.1 技术风险

| 风险 | 概率 | 影响 | 应对策略 |
|------|------|------|----------|
| Supabase国内访问慢 | 高 | 高 | 配置CDN加速，准备自托管方案 |
| WebRTC NAT穿透失败 | 中 | 高 | 部署TURN服务器，P2P失败转中继 |
| AI API限流/故障 | 中 | 高 | 多供应商备选，本地降级方案 |
| Flutter包体积过大 | 中 | 中 | 启用代码裁剪，资源压缩 |
| 厂商推送集成复杂 | 高 | 中 | 使用第三方推送聚合服务 |

### 6.2 合规风险

| 风险 | 应对 |
|------|------|
| 个人信息保护法 | 数据加密存储，7天自动删除录音，提供数据导出 |
| 无障碍合规 | 遵循WCAG 2.1 AAA标准，通过屏幕阅读器测试 |
| 地图合规 | 使用高德地图，符合国内法规 |

---

## 7. 总结与建议

### 7.1 技术架构亮点
1. **双引擎架构**: AI处理80%标准化需求 + 志愿者处理20%复杂需求，成本与体验平衡
2. **BaaS优先**: Supabase大幅降低后端开发成本，适合MVP快速验证
3. **无障碍优先设计**: 从架构层面考虑视障/听障用户需求，而非事后补丁
4. **渐进式AI策略**: 在线API + 离线模型 + 缓存，控制成本同时保证可用性

### 7.2 关键建议
1. **Week1必须完成**: 项目脚手架 + Supabase连接 + 无障碍基础组件
2. **AI成本控制**: MVP阶段严格监控通义千问VL调用量，设置每日上限
3. **匹配算法简化**: MVP先用SQL查询+简单排序，V1.0再引入复杂算法
4. **WebRTC备选**: 准备P2P失败时的电话回拨备选方案
5. **种子志愿者**: 技术上线前1周必须招募10-20名种子志愿者

### 7.3 下一步行动
- [ ] 创建Flutter项目脚手架
- [ ] 注册Supabase并初始化数据库
- [ ] 申请各AI服务API Key
- [ ] 制定详细的无障碍测试清单
- [ ] 招募种子志愿者

---

*报告生成时间: 2026-04-10*
*基于PRD版本: v1.0*
