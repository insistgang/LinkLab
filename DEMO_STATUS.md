# LinkLab Demo 当前状态

> 核对日期：2026-07-24
> 唯一完整总索引：[docs/PROJECT_MASTER_PLAN.md](./docs/PROJECT_MASTER_PLAN.md)

## 当前定位

LinkLab / LinkAble 是 Demo-first 的无障碍互助竞赛 MVP，不是生产级全功能平台。当前默认承诺：

1. F1 AI Agent 先处理标准化求助。
2. F9 复杂需求转志愿者 Top 5 匹配。
3. F11 进入本地 Demo Call 状态机。
4. F13 展示带 10 秒误触撤销的 Mock SOS。
5. F33 使用演示员会话和本地偏好。
6. F36 把无障碍作为主流程强制约束。

默认演示不依赖真实 API Key、Supabase、WebRTC、推送、短信或报警链路。

## 当前验证

| 检查 | 最近结果 |
|---|---|
| Flutter | 3.44.4 / Dart 3.12.2 |
| `flutter analyze` | 无问题 |
| `flutter test --reporter compact` | 114 项通过 |
| `flutter build web --release` | 成功 |
| `flutter build apk --release` | 成功，`1.0.1 (2)`，92.0 MB |
| 主要平台 | Web / Chrome |

说明：这些结果证明当前基线可运行；竞赛量化指标的已证明项与缺口见总纲 §4.2。

## 推荐演示路径

```bash
cd linklab
flutter pub get
flutter run -d chrome
```

构建发布产物：

```bash
flutter build web --release
```

Windows 桌面不是当前首选路径；缺少 Visual Studio C++ 工具链时应直接使用 Web / Chrome。

## 默认导航

求助者与志愿者主界面均保持四个入口：

- 首页 / 待帮助
- AI
- 精选故事
- 我的

“精选故事”只展示静态内容，不开放发帖、点赞、群聊或地区社群。

## 真实链路状态

- 线上 Supabase 项目当前健康。
- `public` 只有 `profiles`、`help_requests`、`volunteer_profiles` 三张空业务表，均启用 RLS。
- 线上迁移记录为 0，已部署 Edge Function 为 0。
- 本地根 `supabase/` 已把历史全量 schema 和 4 个不可部署函数移入 `legacy/`，活跃 migration 只保留最小三表候选基线。
- 默认入口传入空环境，Pages 构建实际运行 DemoMode。
- 真实 WebRTC、匹配、推送、短信、SOS 和 AI 供应商调用继续视为实验或后续能力。

任何生产 DDL、Edge Function 部署、push 或 Pages 发布都需要独立确认。

## 推荐阅读顺序

1. [docs/PROJECT_MASTER_PLAN.md](./docs/PROJECT_MASTER_PLAN.md)
2. [AGENTS.md](./AGENTS.md)
3. [README.md](./README.md)
4. [docs/demo_acceptance_checklist.md](./docs/demo_acceptance_checklist.md)
5. [docs/rc_acceptance_evidence.md](./docs/rc_acceptance_evidence.md)
6. [TODO.md](./TODO.md)（历史执行档案）
