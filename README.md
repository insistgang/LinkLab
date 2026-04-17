# 共感 LinkAble

**AI + 志愿者无障碍互助平台**

面向视障、听障、老年人及肢体障碍者的「AI 先处理 + 真人兜底」互助 Demo。

> 2026 两岸大学生创客大赛 · 逢甲赛区竞赛交付版本  
> 当前仓库状态：**MVP 已完全收敛** / **Demo 主线 100% 可跑通** / **无障碍优先** / **已完成 AGENTS.md 全部修复项**

## 项目定位

共感 LinkAble 的目标不是做“功能很多但都半成品”的助残应用，而是把竞赛版严格收口为一条能稳定演示、可重复验证、对无障碍用户真正友好的 MVP 主线：

- AI 优先处理标准化需求
- 真人志愿者兜底复杂和高风险需求
- 所有主流程都具备可见状态变化与结束落点
- 所有演示链路默认不依赖外部不可控服务

当前版本严格遵循根目录 [AGENTS.md](./AGENTS.md) 作为唯一技术实施事实来源。

## MVP 6 大核心功能

| 功能 | 描述 | 对应范围 |
|---|---|---|
| **F1 AI Agent 智能对话** | 语音 / 文字 / 拍照统一入口，处理 OCR、场景描述、颜色识别、翻译、紧急词检测等 | MVP 核心 |
| **F9 志愿者匹配** | AI 无法解决时，进入 Demo 匹配流程并展示明确的状态变化 | MVP 核心 |
| **F11 实时语音通话** | 匹配成功后进入语音通话闭环；竞赛版默认走 Demo 通话 | MVP 核心 |
| **F13 SOS 紧急呼救** | 一键触发、10 秒误触撤销窗口、Mock 广播和联系人通知 | MVP 核心 |
| **F33 登录与无障碍偏好** | 手机号验证码登录、首次引导、偏好恢复 | MVP 核心 |
| **F36 全局无障碍** | `Semantics`、高对比度、48x48 触摸目标、动态字体、错误三重表达 | 强制约束 |

一句话总结：**AI 处理 80% 标准化需求，志愿者兜底 20% 复杂 / 紧急需求。**

## 当前交付状态

截至 `2026-04-17`，仓库已经完成 `P0 + P1 + P2` 全部收口工作：

- 竞赛版入口已强制锁定 `Demo Mode`
- 全局已补齐 `ProviderScope`
- 默认导航只保留 `Home / AIChat / Profile`
- 社区 / 社群 / 复杂后台能力已降级或移出默认主链路
- Supabase 以根目录 `supabase/` 为唯一 schema source of truth
- `real_*` 真实链路已隔离到 `services/experimental/real/`
- 5 条关键 Demo 闭环测试已补齐并通过
- 日志已统一收口到 `AppLogger`
- `api_config.dart` 已停止 Git 追踪，改为本地实验配置

## 快速启动

### 1. 运行主应用 Demo

```bash
cd linklab
flutter pub get
flutter run
```

说明：

- 当前入口在 [`linklab/lib/main.dart`](./linklab/lib/main.dart) 中已强制执行 `AppConfig.demoMode = true`
- 默认不需要真实 API Key、真实 Supabase、真实推送或真实 WebRTC
- 竞赛版默认只保证 Demo 主线

### 2. 运行闭环测试

```bash
cd linklab
flutter test --tags demo
```

### 3. 运行静态检查

```bash
cd linklab
flutter analyze lib
```

```bash
cd linklab/admin_dashboard
flutter analyze lib
```

当前仓库验证结果：

- 主应用 `flutter analyze lib`：`70 issues found`
- `admin_dashboard`：`9 issues found`
- `flutter test --tags demo`：**All tests passed**

## 3 分钟竞赛演示主线

当前默认演示闭环为：

1. 打开 App，进入首页大按钮主界面
2. 语音或文字发起 AI 求助
3. AI 能处理时直接返回答案
4. AI 无法处理时进入志愿者匹配页
5. 匹配成功后进入 Demo 通话
6. 通话结束后提交评价并回写历史
7. 演示 SOS：广播、联系人通知、10 秒撤销窗口

对应仓内文档可参考：

- [DEMO_SCRIPT.md](./DEMO_SCRIPT.md)
- [TODO.md](./TODO.md)
- [AGENTS.md](./AGENTS.md)

## 仓库结构

```text
LinkLab/
├─ linklab/                  # 主 Flutter 应用（竞赛 MVP 主交付）
│  ├─ lib/
│  │  ├─ config/             # Demo / 网络 / API 配置
│  │  ├─ core/               # 主题、常量、日志等基础设施
│  │  ├─ demo_data/          # 本地演示数据
│  │  ├─ demo_flow/          # Demo 状态流与闭环追踪
│  │  ├─ models/             # 核心数据模型
│  │  ├─ providers/          # Riverpod provider
│  │  ├─ screens/            # 页面
│  │  ├─ services/           # 业务服务与 unified facade
│  │  └─ widgets/            # 无障碍组件与通用 UI
│  └─ test/closed_loop/      # 5 条关键闭环测试
├─ supabase/                 # 唯一 schema source of truth
│  ├─ migrations/
│  └─ functions/
├─ docs/                     # 说明文档
├─ prd-analysis/             # PRD / 分析辅助材料
├─ 共感LinkAble_PRD_v1_2.md
├─ 项目深度分析报告.md
├─ AGENTS.md
└─ TODO.md
```

补充说明：

- `linklab/admin_dashboard/` 保留为历史后台工程，不属于竞赛 MVP 主交付
- `linklab/lib/services/experimental/real/` 为实验性真实链路，默认不进入导航和演示脚本
- `linklab/supabase/legacy/` 为历史归档，后续不得再作为事实来源

## 技术栈

### 主应用

- Flutter
- Riverpod
- Supabase Flutter
- WebRTC
- Firebase Messaging
- Shared Preferences
- Geolocator
- Flutter TTS / Speech To Text
- Logger

### 数据与后端

- Supabase Postgres
- Supabase Edge Functions
- 根目录 `supabase/migrations/` 统一管理 schema

### 工程质量

- `flutter analyze`
- `flutter test --tags demo`
- `AppLogger` 统一日志
- Demo-first fallback 策略

## Demo / Real 边界

当前项目采用明确的双轨策略，但**竞赛版只保留 Demo 主线**：

- 默认导航、默认首页、默认测试只走 Demo 主线
- `unified_*` 服务默认强制走 Demo 分支
- 真实链路仅保留在 `services/experimental/real/`
- 如果真实依赖未初始化、缺失或不稳定，必须自动回退到 Demo 数据

这意味着：

- 你可以稳定演示 `F1 -> F9 -> F11 -> 评价 -> 历史`
- 你也可以稳定演示 `F13 SOS`
- 但不应该把真实 WebRTC、真实 Supabase、真实推送当作现场依赖

## 无障碍约束

当前版本不是“先做功能、最后补无障碍”，而是将无障碍作为强制实施基线：

- 交互元素需要 `Semantics`
- 触摸目标尽量接近或达到 `48x48dp`
- 高对比度优先于视觉装饰
- 支持字体缩放和读屏
- 错误状态必须使用颜色 + 图标 + 文字三重表达
- 图片必须有可理解的替代文本或回退组件

仓内可以关注这些实现：

- [`linklab/lib/widgets/accessible/`](./linklab/lib/widgets/accessible)
- [`linklab/lib/widgets/accessible/accessible_image.dart`](./linklab/lib/widgets/accessible/accessible_image.dart)

## 测试覆盖

当前已补齐 5 条关键闭环测试，位于 [`linklab/test/closed_loop/`](./linklab/test/closed_loop)：

- `startup_login_closed_loop_test.dart`
- `ai_to_human_closed_loop_test.dart`
- `matching_call_rating_closed_loop_test.dart`
- `sos_closed_loop_test.dart`
- `demo_mainline_end_to_end_test.dart`

这些测试覆盖的核心目标包括：

- `AppSessionService` 初始化与偏好恢复
- AI 无法处理时转人工
- `help_request` 状态机从 `ai_processing -> matching -> connected -> completed`
- SOS 的 `created -> cancelled / matching`
- 首页到历史回看的完整 Demo 主线

## 配置与密钥管理

### Demo 运行

竞赛版 Demo 运行默认**不需要**真实密钥。

### 本地实验真实链路

如果你只是本地实验真实 AI 配置：

1. 参考 [`linklab/lib/config/api_config.example.dart`](./linklab/lib/config/api_config.example.dart)
2. 复制生成本地 `linklab/lib/config/api_config.dart`
3. 填入自己的实验配置
4. **不要提交该文件**

仓库已经通过 `.gitignore` 忽略：

- `linklab/lib/config/api_config.dart`

### Supabase 规则

- 根目录 [`supabase/`](./supabase) 是唯一 schema source of truth
- 任何字段 / 表结构调整都应先改 migration，再改客户端代码
- 竞赛版主流程默认不依赖真实 Supabase 初始化

## 非 MVP 范围说明

以下内容当前不属于竞赛默认交付主线：

- 交互式社区 / 群聊 / 地区社群
- 多级认证和复杂审核
- 积分、徽章、排班、时间线
- 录音 AI 检测
- 独立运营后台能力
- 真实 WebRTC / 真实推送 / 真实匹配的生产级可用性

这些代码可能仍保留在仓库中，但已经被隐藏、隔离或降级，不应进入默认演示流程。

## 推荐阅读顺序

如果你第一次接手这个项目，建议按下面顺序阅读：

1. [AGENTS.md](./AGENTS.md)
2. [TODO.md](./TODO.md)
3. [DEMO_SCRIPT.md](./DEMO_SCRIPT.md)
4. [`linklab/lib/main.dart`](./linklab/lib/main.dart)
5. [`linklab/lib/config/app_config.dart`](./linklab/lib/config/app_config.dart)
6. [`supabase/migrations/005_unify_root_schema_source_of_truth.sql`](./supabase/migrations/005_unify_root_schema_source_of_truth.sql)

## 一句话总结

**共感 LinkAble 当前不是“全功能平台原型”，而是一条严格收口、无障碍优先、可稳定演示的 AI + 志愿者协助 MVP 主线。**
