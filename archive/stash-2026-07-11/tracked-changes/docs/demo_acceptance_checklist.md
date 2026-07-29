# 共感 LinkAble 竞赛 Demo 验收检查清单

> 使用范围：2026 创客大赛 Demo-first MVP
> 关键声明：**竞赛 Demo 不依赖外部服务**。所有检查都应在无真实 Supabase、无真实 WebRTC、无真实推送、无真实 OCR key 的情况下成立。

## 启动检查

- [ ] `linklab/lib/main.dart` 启动时锁定 demo mode，并启用演示员预置会话。
- [ ] App 通过 `ProviderScope(child: LinkLabApp())` 启动。
- [ ] `LinkLabApp` 能根据 session 状态进入默认主界面；竞赛演示不被登录/注册卡住。
- [ ] 默认底部导航只有 `首页 / AI助手 / 我的`。
- [ ] 首页第一屏显示“我需要帮助”大按钮，且按钮可点击进入 AI 或匹配主流程。
- [ ] 不需要真实 Supabase 初始化、不需要 Firebase 初始化、不需要真实 API key 才能打开 App。

建议命令：

```powershell
git status --short
cd linklab
flutter pub get
flutter test test/closed_loop/startup_login_closed_loop_test.dart
```

## 无网络 / 无 API key 检查

- [ ] 断网或不配置真实 API key 时，App 仍能启动到首页。
- [ ] OCR、场景描述、匹配、通话、SOS 都走本地 demo fallback。
- [ ] 页面没有要求输入 Supabase URL、Firebase token、WebRTC server、OCR key。
- [ ] 控制台没有因为缺少外部服务而导致主流程崩溃。
- [ ] 评审现场可明确说明：竞赛 Demo 不依赖外部服务，真实集成是后续版本。

建议检查：

```powershell
cd linklab
rg -n "Supabase.initialize|Firebase.initializeApp|RealCallService\(|WebRTCService\(|PushNotificationService\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
```

验收口径：默认启动、首页和 demo flow 不应命中真实外部服务初始化或真实通话依赖。

## AI demo fallback 检查

- [ ] 从首页大按钮或 `AI助手` 进入单一 AI Agent 入口。
- [ ] 输入或选择“帮我读药品盒”，返回本地 OCR demo 响应。
- [ ] OCR 响应包含药名、规格、用法用量、有效期等可讲述信息。
- [ ] 输入或选择“我面前是什么”，返回本地场景描述 demo 响应。
- [ ] AI 响应有处理中、成功、失败或可转人工等明确状态。
- [ ] AI 无法处理或复杂需求时，可以 `100%` 转到志愿者匹配。
- [ ] 紧急词能进入 SOS 路径，不能只停留在普通聊天回覆。

对应代码：

- `linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`
- `linklab/lib/services/demo/demo_ai_service.dart`
- `linklab/assets/demo_data/ai_responses.json`
- `linklab/assets/demo_data/help_scenarios.json`

建议命令：

```powershell
cd linklab
flutter test test/closed_loop/ai_to_human_closed_loop_test.dart
flutter test test/closed_loop/demo_mainline_end_to_end_test.dart
```

## 匹配 demo 检查

- [ ] 点击转人工或复杂需求后进入 `DemoMatchingScreen`，不是进入真实 `MatchingScreen`。
- [ ] 匹配页显示处理中状态、候选志愿者信息和成功状态。
- [ ] demo 志愿者数据来自 `assets/demo_data/volunteers.json`。
- [ ] 用户可以取消匹配，取消后有可见反馈。
- [ ] 匹配成功后进入 demo 通话，不依赖真实推送、真实地理位置或真实 Supabase。

对应代码：

- `linklab/lib/demo_flow/demo_matching_flow.dart`
- `linklab/lib/screens/call/demo_matching_screen.dart`
- `linklab/lib/services/demo_call_service.dart` 中 `DemoMatchingService`
- `linklab/assets/demo_data/volunteers.json`

建议命令：

```powershell
cd linklab
flutter test test/closed_loop/matching_call_rating_closed_loop_test.dart
rg -n "MatchingScreen\(|RealCallScreen|RealCallPage|WebRTCService\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
```

## 通话 demo 检查

- [ ] 匹配成功后进入 `DemoCallScreen`，不是进入真实 WebRTC 通话页。
- [ ] 通话页显示连接中、已连接、志愿者信息、挂断按钮。
- [ ] 挂断后进入评价页或结果回看落点。
- [ ] 评价提交后可返回首页或帮助档案落点。
- [ ] 口播明确：这是 demo 通话状态机，真实 WebRTC 是后续真实集成，不作为竞赛 Demo 外部依赖。

对应代码：

- `linklab/lib/screens/call/demo_call_screen.dart`
- `linklab/lib/screens/call/demo_call_rating_screen.dart`
- `linklab/lib/services/demo_call_service.dart` 中 `DemoCallService`

建议命令：

```powershell
cd linklab
flutter test test/closed_loop/matching_call_rating_closed_loop_test.dart
```

## SOS mock 检查

- [ ] 首页 SOS 或 AI 紧急词能进入 `DemoSOSScreen`。
- [ ] 页面显示 10 秒误触撤销窗口。
- [ ] 页面显示 Mock 广播演示，不依赖真实推送。
- [ ] 页面显示紧急联系人通知状态；联系人为空时有明确说明和降级文案。
- [ ] 用户能撤销误触；撤销后状态明确，不静默失败。
- [ ] SOS 路径不走普通 F9 匹配公式，而是广播型紧急流程。

对应代码：

- `linklab/lib/screens/call/demo_sos_screen.dart`
- `linklab/lib/services/demo_call_service.dart` 中 `DemoSOSService`
- `linklab/lib/demo_flow/demo_sos_flow.dart`
- `linklab/lib/services/security/emergency_contact_service.dart`

建议命令：

```powershell
cd linklab
flutter test test/closed_loop/sos_closed_loop_test.dart
```

## 无障碍检查

- [ ] 默认主链路所有交互控件有可理解的 `Semantics` label/hint。
- [ ] 主要按钮和可点区域接近或达到 `48x48dp`。
- [ ] 文字和背景对比度达到 `>= 7:1` 的竞赛口径。
- [ ] 系统字体缩放到 `200%` 时，首页、AI、匹配、通话、SOS、我的页不破版。
- [ ] 错误、警告、成功状态不能只靠颜色表达，需要文字和图标共同表达。
- [ ] 焦点顺序符合视觉与操作顺序。
- [ ] 不存在强制倒计时选择；唯一允许例外是 SOS 10 秒误触撤销窗口。
- [ ] 图片、故事卡片和图标型按钮有可理解替代文本或语义说明。

建议命令：

```powershell
cd linklab
flutter test test/closed_loop/theme_toggle_live_update_test.dart
```

人工验收：使用系统读屏和 `200%` 字体缩放完整跑一遍 3 分钟脚本。

## Flutter analyze / test 验收

- [ ] `flutter analyze` 通过。
- [ ] `flutter test` 通过。
- [ ] 闭环测试至少覆盖启动/登录、AI 转人工、匹配通话评价、SOS、Seeker Center MVP 范围。
- [ ] 不把被 `analysis_options.yaml` 排除的默认可达页面误认为已完全验收；P0 后应恢复默认主链路 analyze 覆盖。

建议命令：

```powershell
cd linklab
flutter analyze
flutter test
flutter test test/closed_loop
```

## 非 MVP 污染检查

- [ ] 默认导航没有社群、积分、徽章、排班、后台。
- [ ] 首页和 demo flow 不进入真实 WebRTC、真实推送、真实 Supabase 页面。
- [ ] `SeekerCenterScreen` 默认只展示“帮助档案 / 求助状态”；积分、异步任务、收藏志愿者不进入竞赛主线。
- [ ] 根 `supabase/` 中非 MVP 表和 functions 已被标注 legacy、归档或从竞赛部署路径移除。
- [ ] `admin_dashboard/`、`linklab/lib/admin/` 不参与竞赛 App 默认构建验收。

建议命令：

```powershell
cd linklab
rg -n "AdminLoginScreen|AdminLayout|CommunityScreen|PointsTab|AsyncRequestsTab|FavoriteVolunteersTab|RealCallScreen|RealCallPage|MatchingScreen\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
rg -n "points-calculator|point_transactions|async_tasks|reports|call_records" ..\supabase
```

## 文档与变更范围检查

- [ ] 本轮只改 `docs/` 下文档。
- [ ] 未改 `AGENTS.md`。
- [ ] 未改 `lib/`、`test/`、`supabase/`。
- [ ] 已运行 `git diff -- docs`；若新建文档尚未被 Git 跟踪，结合 `git status --short` 或 `git diff --no-index` 核对新增内容。

建议命令：

```powershell
git diff -- docs
git status --short
```
