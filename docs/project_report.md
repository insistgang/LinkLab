# 共感 LinkAble 项目完整报告

> 扫描日期：2026-05-26  
> 扫描范围：`E:\vscode_project\LinkLab` 整个 workspace

---

## 一、项目基本信息

| 属性 | 值 |
|---|---|
| **项目名称** | 共感 LinkAble |
| **项目类型** | Flutter / Dart 移动应用 |
| **版本** | 1.0.0+1 |
| **Dart SDK** | ^3.11.4 |
| **项目定位** | AI + 志愿者无障碍互助平台（面向视障、听障、老年人及肢体障碍者） |
| **竞赛** | 2026 两岸大学生创客大赛 · 逢甲赛区 |
| **当前状态** | Demo-first MVP，竞赛主线可跑通 |

---

## 二、目录结构总览

```
LinkLab/
├─ linklab/                          # 主 Flutter 应用
│  ├─ lib/                           # Dart 源码（289 个文件，~68,343 行手写代码）
│  │  ├─ config/                     # 配置（AppConfig, ApiConfig）
│  │  ├─ core/                       # 核心基础设施（常量、主题、日志）
│  │  ├─ models/                     # 数据模型（32 源文件，3,527 行）
│  │  ├─ providers/                  # Riverpod 状态管理（14 文件，1,935 行）
│  │  ├─ services/                   # 业务服务层（22+ 文件）
│  │  │  ├─ facades/                 # ★ 统一 Facade（5 个门面）
│  │  │  ├─ demo/                    # Demo 实现（默认）
│  │  │  ├─ experimental/            # 实验性真实实现（隔离）
│  │  │  ├─ webrtc/ asr/ tts/ vision/ # 子能力
│  │  │  └─ security/ community/ user_center/
│  │  ├─ screens/                    # 页面 UI（11 个子目录）
│  │  ├─ widgets/                    # 组件（含 6 个无障碍组件）
│  │  ├─ demo_data/                  # 本地 Demo 数据（10 文件）
│  │  └─ demo_flow/                  # Demo 流程控制
│  ├─ test/                          # 测试（16 个文件，含 14 个闭环测试）
│  ├─ assets/                        # 资源（85 个 SVG 图标、4 个 JSON）
│  └─ pubspec.yaml                   # 36 个核心依赖
│
├─ supabase/                         # 唯一 schema source of truth
│  ├─ migrations/                    # 6 个 SQL 迁移文件
│  ├─ functions/                     # 4 个 Edge Functions
│  └─ docs/                          # 数据库文档
│
├─ docs/                             # 项目文档（6 个）
├─ AGENTS.md                         # 工程实施准则（最高优先级）
├─ DEMO_STATUS.md / TODO.md / DEMO_SCRIPT.md
└─ 共感LinkAble_PRD_v1_2.md         # PRD
```

---

## 三、技术架构

### 3.1 分层架构

```
┌─────────────────────────────────────────────────────┐
│                  UI 层 (screens/)                     │
│   home → ai_chat → matching → call → sos → profile   │
├─────────────────────────────────────────────────────┤
│              状态管理层 (providers/Riverpod)           │
│   appSession → demoFlow → matchingFlow → callFlow    │
├─────────────────────────────────────────────────────┤
│            Facade 统一入口层 (services/facades/)      │
│   AgentServiceFacade → VolunteerMatchingFacade       │
│   CallSessionFacade → SosFacade → LocationFacade     │
├─────────────────────────────────────────────────────┤
│               服务实现层 (services/)                   │
│   ┌──────────┐  ┌───────────┐  ┌──────────────┐     │
│   │  demo/   │  │experimental│  │security/tts/ │     │
│   │ (默认)   │  │  /real/    │  │asr/vision/   │     │
│   └──────────┘  └───────────┘  └──────────────┘     │
├─────────────────────────────────────────────────────┤
│             数据层 (models/ + demo_data/)              │
│   AgentInput → AgentResult → HelpRequest → UserModel │
└─────────────────────────────────────────────────────┘
```

### 3.2 核心依赖

| 类别 | 包 | 用途 |
|---|---|---|
| 状态管理 | flutter_riverpod ^2.6.1 | 全局 Riverpod |
| 后端 | supabase_flutter ^2.8.4 | Supabase 集成 |
| 通话 | flutter_webrtc ^0.12.12 | WebRTC |
| 语音 | flutter_tts + speech_to_text | TTS/ASR |
| 图像 | image_picker + camera | OCR/拍照 |
| 推送 | firebase_messaging | 推送通知 |
| 位置 | geolocator | 定位 |
| 序列化 | freezed + json_serializable | 不可变数据类 |

### 3.3 状态管理

- 全局 `ProviderScope(child: LinkLabApp())` 已正确注入
- 核心流程使用 `NotifierProvider` 管理状态机
- 6 个核心 Provider：AppSession、DemoFlow、MatchingFlow、CallFlow、HelpRequestFlow、Community

---

## 四、MVP 六大核心功能实现状态

| ID | 功能 | 状态 | 关键文件 | 代码量 | 主要问题 |
|---|---|---|---|---|---|
| **F1** | AI Agent 智能对话 | ✅ 已实现 | `agent_service_facade.dart` (736行), `demo_ai_chat_screen.dart` (1075行) | ~3,500行 | 旧 singleton 未清理、LLM 无上下文记忆 |
| **F9** | 志愿者匹配引擎 | ✅ 已实现 | `volunteer_matching_facade.dart`, `demo_matching_screen.dart` (948行) | ~2,200行 | **评分函数是简化版**（固定分数），未实现 5 维评分公式 |
| **F11** | 实时语音通话 | ✅ 已实现 | `call_session_facade.dart`, `demo_call_screen.dart` (917行) | ~3,500行 | ChangeNotifier 违规、DemoCallService 职责过重 |
| **F13** | SOS 紧急呼救 | ✅ 已实现 | `sos_facade.dart`, `demo_sos_screen.dart` (1074行) | ~1,800行 | ChangeNotifier 违规、真实 SMS 未接入 |
| **F33** | 登录与偏好 | ✅ 已实现 | `preference_screen.dart` (550行), 8 个 auth 页面 | ~2,500行 | 缺 `SessionFacade`、真实短信未接入 |
| **F36** | 全局无障碍 | ⚠️ 部分实现 | 6 个 accessible 组件 (1,214行) | ~1,200行 | 跨页面覆盖不均匀、对比度未系统验证 |

### Facade 完成度

| Facade | 状态 |
|---|---|
| `AgentServiceFacade` | ✅ 已创建 (736行) |
| `VolunteerMatchingFacade` | ✅ 已创建 (189行) |
| `CallSessionFacade` | ✅ 已创建 (120行) |
| `SosFacade` | ✅ 已创建 (125行) |
| `LocationFacade` | ✅ 已创建 |
| `SessionFacade` | ❌ 未创建 |
| `AccessibilityPrefsFacade` | ❌ 未创建 |

---

## 五、数据库 Schema（Supabase）

### 核心表（11 张）

| 表名 | 用途 |
|---|---|
| `users` | 用户基础表（phone, name, role, disability_type, preferences） |
| `volunteer_profiles` | 志愿者扩展（skills, level, points, credit_score, is_online, location PostGIS） |
| `help_requests` | 求助记录（8 态状态机） |
| `emergency_contacts` | 紧急联系人 |
| `virtual_identities` | 虚拟身份映射 |
| `call_records` | 通话记录 |
| `reports` | 举报 |
| `point_transactions` | 积分流水 |
| `ai_response_cache` | AI 响应缓存 |
| `async_tasks` | 异步任务 |
| `help_request_logs` | 状态变更日志 |

### `help_requests` 状态机

```
created → ai_processing → ai_resolved          (终态)
                      ↘ matching → connected → completed (终态)
                                     ↕ (掉线重连)
                                  → expired    (终态)
                                  → cancelled  (终态)
```

共 8 个状态：`created`, `ai_processing`, `ai_resolved`, `matching`, `connected`, `completed`, `cancelled`, `expired`

### Edge Functions（4 个）

| 函数 | 用途 |
|---|---|
| `matching-engine` | 志愿者匹配引擎 |
| `ai-dispatcher` | AI 意图分发 |
| `push-notifier` | 推送通知（无 FCM key 时自动 mock） |
| `points-calculator` | 积分计算 |

### 关键函数

- `find_matching_volunteers(lat, lng, max_dist, skills, limit)` — PostGIS 地理匹配
- `calculate_distance(lat1, lng1, lat2, lng2)` — Haversine 距离计算
- `calculate_volunteer_level(points)` — 积分 → 等级映射（1-7 级）

---

## 六、测试覆盖

| 测试文件 | 对应功能 |
|---|---|
| `widget_test.dart` | F33, F36 — 初始化、FeatureFlags、200% 字体、读屏语义 |
| `startup_login_closed_loop_test.dart` | F33 — 启动 → 登录 → 首页 |
| `ai_to_human_closed_loop_test.dart` | F1 — AI 低信心 → 转人工 |
| `matching_call_rating_closed_loop_test.dart` | F9, F11 — 匹配 → 通话 → 评价 |
| `sos_closed_loop_test.dart` | F13 — SOS 触发 → 撤销 → 广播 → 联系人通知 |
| `demo_mainline_end_to_end_test.dart` | 全链路 — 3 分钟 Demo 主线 E2E |
| `help_request_state_machine_test.dart` | F1/F9 — 状态机 8 态转移验证 |
| `demo_data_fallback_test.dart` | 全局 — 无 API 时本地数据 fallback |
| `theme_toggle_live_update_test.dart` | F36 — 主题切换实时更新 |
| `demo_call_flow_test.dart` | F11 — 通话流程 |
| `demo_call_screen_test.dart` | F11 — 通话页面 |
| `demo_matching_screen_test.dart` | F9 — 匹配页面 |
| `demo_matching_service_test.dart` | F9 — 匹配服务 |
| `seeker_center_scope_test.dart` | 求助者视角作用域 |
| `real_database_repository_test.dart` | RealMode 基础 |
| `test_harness.dart` | 测试基础设施 |

**合计**：16 个测试文件，6 个 MVP 功能全覆盖

---

## 七、资源文件

| 类别 | 状态 | 说明 |
|---|---|---|
| Brand SVG | ✅ 完整 | `logo.svg` + `link_hand.svg` |
| Demo Data JSON | ✅ 完整 | 4 个 JSON（志愿者、AI 响应、场景） |
| Icon SVG | ✅ 完整 | 85 个图标覆盖所有 MVP 意图 |
| Fonts | ⚠️ 占位 | `placeholder.txt`，未打包自定义字体 |
| Avatar Images | ⚠️ 占位 | 使用文字头像 fallback |
| Sounds | ❌ 空 | 目录存在但无文件 |

---

## 八、环境配置与 FeatureFlags

### 默认状态（竞赛 Demo）

所有 FeatureFlags 默认 **关闭**，确保 Demo 主线不依赖外部服务：

| 开关 | 默认 | 说明 |
|---|---|---|
| `enableSupabaseAuth` | false | 不依赖真实 Supabase |
| `enableWebRTC` | false | 走 Demo Call |
| `enableRealMatching` | false | 走 Demo 匹配 |
| `enableRealAI` | false | 走本地 Demo 响应 |
| `enablePushNotification` | false | 不依赖 Firebase |
| `enableRealSMS` | false | 不依赖短信服务 |
| `enableDatabaseSync` | false | 不同步数据库 |
| `enableLocationService` | false | 不启用真实定位 |
| `enableCommunity` | false | 不开放交互式社区 |
| `enablePoints` | false | 安心积分已砍 |
| `enableBadges` | false | 徽章已砍 |
| `enableSchedule` | false | 排班已砍 |
| `enableAdminDashboard` | false | 后台入口关闭 |
| `enableCallRecording` | false | 通话录音延后 |

### 密钥管理

- `api_config.dart` 已通过 `.gitignore` 双重忽略，不入版本控制
- `api_config.example.dart` 作为唯一入库模板
- 仓库中只保留占位值或公开服务端点，无真实密钥

---

## 九、代码规模统计

| 维度 | 数量 |
|---|---|
| Dart 源文件（lib/） | 289 个 |
| 手写代码行数 | ~68,343 行 |
| 生成代码（.freezed.dart + .g.dart） | 34 个，~19,711 行 |
| 测试文件 | 16 个 |
| SQL 迁移文件 | 6 个 |
| Edge Functions | 4 个 |
| SVG 图标 | 85 个 |
| 核心依赖包 | 36 个 |
| Facade 服务 | 5 个 |

---

## 十、技术债务与风险

### P0 级（影响架构合规）

| 问题 | 位置 | 说明 |
|---|---|---|
| 旧 singleton 未清理 | `services/ai_service.dart` (394行) | `AIServiceManager` 违反 AGENTS.md 禁止新增 singleton |
| ChangeNotifier 违规 | `DemoCallService`, `DemoSOSService` | AGENTS.md 要求全局 Riverpod |
| 缺 `SessionFacade` | — | AGENTS.md §12.2 要求的 6 个 facade 缺 2 个 |
| 缺 `AccessibilityPrefsFacade` | — | 同上 |
| 评分函数简化 | `VolunteerMatchingFacade` | 返回固定分数，未实现 5 维评分公式 |

### P1 级（影响演示质量）

| 问题 | 说明 |
|---|---|
| LLM 无上下文记忆 | `_chatWithLLM` 没有 history 传递 |
| 真实 SMS 未接入 | RealMode 下提示"暂未接入" |
| 跨页面 Semantics 不均匀 | 部分页面仅 1 处 Semantics |
| 对比度 >= 7:1 未系统验证 | 无自动检测 |
| RealMode Phase-3 Schema 分叉 | `profiles` 表与 `users` 表并行 |

### P2 级（交付前收尾）

| 问题 | 说明 |
|---|---|
| flutter analyze 残留 | 历史记录 70 个 lint issues |
| 字体/头像/音效资源缺失 | 通过 fallback 机制不影响 Demo |
| 历史验证未复跑 | 需重新执行 `flutter test` + `flutter build web --release` |

---

## 十一、AI 能力链路

```
AgentServiceFacade.processInput()
  ├─ 有图片 → _processImageInput()
  │   ├─ 智谱 GLM-4-vision 可用 → _visionWithLLM() (多模态)
  │   └─ 降级 → 关键词路由
  │       ├─ 药品 → checkMedicine() → VisionService / DemoAIService
  │       ├─ 颜色 → recognizeColor()
  │       ├─ 钞票 → recognizeMoney()
  │       ├─ 文字 → recognizeText() → BaiduOCR / DemoAIService
  │       ├─ 物体 → identifyObject()
  │       └─ 默认 → describeScene()
  │
  └─ 纯文本 → _chatWithLLM() (智谱 GLM-4-flash)
      └─ 失败 → DemoAIService.process()
```

降级链：智谱 GLM-4 → 百度 OCR → 本地 Demo 响应，确保无 API Key 时仍可演示。

---

## 十二、页面导航流

```
启动 → app.dart _buildInitialScreen()
  ├─ 未初始化 → CircularProgressIndicator
  ├─ 已登录 → MainScreen (底部导航)
  │   ├─ Landing: HomeScreen (选择 求助者/志愿者)
  │   ├─ Seeker模式:
  │   │   ├─ Tab 0: SeekerHomeScreen
  │   │   ├─ Tab 1: DemoAIChatScreen        ← F1
  │   │   ├─ Tab 2: CommunityScreen
  │   │   └─ Tab 3: ProfileScreen
  │   └─ Volunteer模式:
  │       ├─ Tab 0: PendingHelpScreen
  │       ├─ Tab 1: DemoAIChatScreen
  │       ├─ Tab 2: CommunityScreen
  │       └─ Tab 3: ProfileScreen
  │
  └─ Demo 主线流程 (DemoFlowNavigator):
      HomeScreen "我需要帮助" → DemoAIChatScreen (F1)
        → [AI无法处理] → DemoMatchingScreen (F9)
          → [匹配成功] → DemoCallScreen (F11)
            → [通话结束] → DemoCallRatingScreen
      HomeScreen 长按 → DemoSOSScreen (F13)
```

---

## 十三、总结

**共感 LinkAble 是一个架构清晰、MVP 主线完整的 Flutter 无障碍互助平台。** 核心亮点：

1. **Demo-first 双轨架构**：所有能力都有 Demo/Real 两套实现，竞赛版默认走 Demo 主线，不依赖外部服务
2. **Facade 统一入口**：5/7 个 Facade 已创建，UI 层不直接依赖底层实现
3. **严格状态机**：`HelpRequestStatus` 的 8 个状态及转移规则被编码为枚举方法
4. **无障碍优先**：独立 accessible 组件库，75 处 Semantics 调用
5. **完整测试覆盖**：14 个闭环测试覆盖全部 6 个 MVP 功能
6. **AI 能力降级链**：智谱 GLM-4 → 百度 OCR → 本地 Demo，确保无 key 可演示

**主要差距**：评分函数简化、2 个 Facade 缺失、旧 singleton/ChangeNotifier 违规、跨页面无障碍覆盖不均匀。这些是下一步优化的重点方向。

---

## 附录：推荐阅读顺序

1. `AGENTS.md` — 工程实施准则（最高优先级）
2. `DEMO_STATUS.md` — 当前演示状态
3. `TODO.md` — 待办事项
4. `DEMO_SCRIPT.md` — 演示脚本
5. `linklab/lib/main.dart` — 应用入口
6. `linklab/lib/config/app_config.dart` — 配置文件
7. `linklab/lib/services/facades/agent_service_facade.dart` — AI 核心 Facade
8. `supabase/migrations/` — 数据库 schema
