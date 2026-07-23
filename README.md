# 共感 LinkAble

**AI + 志愿者无障碍互助平台**

面向视障、听障、老年人及肢体障碍者的「AI 先处理 + 真人兜底」互助 Demo。

> 2026 两岸大学生创客大赛 · 逢甲赛区竞赛交付版本
> 当前仓库状态：**Demo-first MVP** / **Web 与 Chrome 是主要演示路径** / **真实 WebRTC、Supabase、推送、SOS 生产链路仍为实验或后续能力**

> 当前唯一总索引见 [docs/PROJECT_MASTER_PLAN.md](./docs/PROJECT_MASTER_PLAN.md)；[DEMO_STATUS.md](./DEMO_STATUS.md) 是精简运行状态页，其他带日期的数字均按历史记录理解。

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
| **F33 登录与无障碍偏好** | 演示员会话、首次引导、偏好恢复；真实 Auth 仅在显式 RealMode 使用 | MVP 核心 |
| **F36 全局无障碍** | `Semantics`、高对比度、48x48 触摸目标、动态字体、错误三重表达 | 强制约束 |

一句话总结：**AI 处理 80% 标准化需求，志愿者兜底 20% 复杂 / 紧急需求。**

## 当前交付状态

截至 `2026-07-24` 的当前核对结果：

- 竞赛版入口已强制锁定 `Demo Mode`
- 全局已补齐 `ProviderScope`
- 默认导航保留 `Home / AIChat / 社群精选 / Profile`
- 社群仅展示精选互助故事，不开放发帖、群聊或地区社群；复杂后台能力已移出默认主链路
- 根目录 `supabase/` 已完成本地隔离：活跃目录只保留最小三表 migration，历史全量 schema 与不可部署函数位于 `supabase/legacy/`
- `real_*` 真实链路已隔离到 `services/experimental/real/`
- 最近本地复验为 114 项测试通过、`flutter analyze` 无问题、Web Release 构建成功
- 日志已统一收口到 `AppLogger`
- `api_config.dart` 已改为可跟踪的无密钥兼容配置，真实 AI 只经服务端代理
- 线上 Supabase 当前为三张空业务表、0 条迁移记录、0 个 Edge Function；未执行本轮生产写入

## 项目中心与正式资料

本仓库根目录是源码、测试和项目资料的唯一维护中心：

- [`docs/submission/`](./docs/submission) 保存三份正式简体提交材料：项目企划书、参赛作品简介、技术可行性与指标评测。
- `dist/LinkLab_简体中文交付包_2026-07-10/` 保存本地完整交付成品，包括 APK、演示视频、源码快照和校验清单；`dist/` 已被 Git 忽略。
- APK、AAB、演示视频、评测生成结果和完整交付包不再进入当前版本树或后续提交，需要共享时使用 `dist/` 成品或 GitHub Release。
- 源码 ZIP 只作为交付快照生成，不在仓库源码目录中另存一份。

当前整合基线以本仓库 `main` 分支为准。

## 快速启动

### 1. 运行主应用 Demo（首选 Web / Chrome）

```bash
cd linklab
flutter pub get
flutter run -d chrome
```

说明：

- 当前入口在 [`linklab/lib/main.dart`](./linklab/lib/main.dart) 中已强制执行 `AppConfig.demoMode = true`
- 默认不需要真实 API Key、真实 Supabase、真实推送或真实 WebRTC
- 竞赛版默认只保证 Demo 主线
- Windows 桌面端不是首选演示路径；如需 `flutter run -d windows`，本机必须安装 Visual Studio C++ 桌面开发工具链

### 2. Web 构建复验

```bash
cd linklab
flutter build web --release
```

说明：Web build 是推荐交付复验口径之一。`2026-07-24` 最近一次本地复验已成功；正式 RC 仍需重新执行并把 commit、命令和结果补入 [`docs/rc_acceptance_evidence.md`](./docs/rc_acceptance_evidence.md)。

### 3. 运行闭环测试

```bash
cd linklab
flutter test --tags demo
```

### 4. 运行静态检查

```bash
cd linklab
flutter analyze
```

最近验证记录（`2026-07-24`）：

- `flutter analyze`：`No issues found`
- `flutter test --reporter compact`：114 项通过
- `flutter build web --release`：成功
- `git diff --check`：通过

这组结果证明当前代码基线可运行，不代表总纲中的每个量化 KPI 都已完成；具体证据缺口见总纲 §4.2。

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

- [DEMO_STATUS.md](./DEMO_STATUS.md)
- [docs/demo_acceptance_checklist.md](./docs/demo_acceptance_checklist.md)
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
│  └─ test/closed_loop/      # Demo 闭环与量化指标测试
├─ supabase/                 # 最小三表活跃基线 + legacy 历史部署面
│  ├─ migrations/
│  └─ functions/
├─ docs/                     # 说明文档
│  └─ submission/            # 三份正式简体提交材料
├─ dist/                     # 本地交付成品（Git 忽略）
├─ prd-analysis/             # PRD / 分析辅助材料
├─ 共感LinkAble_PRD_v1_2.md
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
- 但不应该把真实 WebRTC、真实 Supabase、真实推送、真实短信、真实报警或生产级 SOS 当作现场依赖
- 真实链路只能作为实验能力或后续版本说明，不能在文档、口播或验收中冒充当前已生产完成

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

当前共有 29 个测试文件，最近一次全量运行通过 114 项。最早建立的 5 条核心闭环测试位于 [`linklab/test/closed_loop/`](./linklab/test/closed_loop)：

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

### 真实 AI 链路

真实 AI 密钥不得写入客户端源码、`.env` 或 Flutter assets。客户端只调用受控服务端代理，供应商密钥由服务端保存、轮换和限流。具体要求见 [`linklab/docs/REAL_AI_INTEGRATION_GUIDE.md`](./linklab/docs/REAL_AI_INTEGRATION_GUIDE.md)。

### Supabase 规则

- 根目录 [`supabase/`](./supabase) 是唯一 schema source of truth；活跃目录只保留最小三表候选基线，生产执行仍需独立确认
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

1. [docs/PROJECT_MASTER_PLAN.md](./docs/PROJECT_MASTER_PLAN.md)
2. [AGENTS.md](./AGENTS.md)
3. [DEMO_STATUS.md](./DEMO_STATUS.md)
4. [TODO.md](./TODO.md)
5. [docs/demo_acceptance_checklist.md](./docs/demo_acceptance_checklist.md)
6. [`linklab/lib/main.dart`](./linklab/lib/main.dart)
7. [`linklab/lib/config/app_config.dart`](./linklab/lib/config/app_config.dart)

## 一句话总结

**共感 LinkAble 当前不是“全功能平台原型”，而是一条严格收口、无障碍优先、可稳定演示的 AI + 志愿者协助 MVP 主线。**
