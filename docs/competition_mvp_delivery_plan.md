# 共感 LinkAble 竞赛 Demo MVP 交付计划

> 状态日期：2026-04-28
> 最高事实来源：根目录 `AGENTS.md`
> 交付硬约束：**竞赛 Demo 不依赖外部服务**。默认首页、默认路由、默认构建和默认测试只服务 F1/F9/F11/F13/F33/F36 六项 MVP。

## 项目定位

共感 LinkAble 是一个“AI Agent 第一响应 + 人类志愿者兜底”的无障碍互助 App。竞赛 Demo 的目标不是展示完整平台能力，而是在 3 分钟内稳定跑通：用户发起求助、AI 先处理、复杂或高风险问题转人工、进入志愿者匹配、完成 demo 通话、必要时触发 SOS，并且全流程对读屏、动态字体和低认知负担友好。

当前工程验收口径是 Demo-first MVP：只交付可点击、可讲述、可闭环的本地演示主线。真实 Supabase、真实 WebRTC、真实推送、后台和社群等能力可以作为后续方向存在，但不得阻塞竞赛 Demo。

## 当前主链路判断

- `linklab/lib/main.dart` 已在启动时锁定 demo mode，启用演示员预置会话，初始化 `DemoDataLoader`，并通过 `ProviderScope(child: LinkLabApp())` 启动。
- `linklab/lib/app.dart` 中 `LinkLabApp` 已是 `ConsumerWidget`，默认通过 session 状态进入 `MainScreen`、登录或首次引导。
- `linklab/lib/screens/home/main_screen.dart` 默认底部导航已收缩为 `首页 / AI助手 / 我的`。
- `linklab/pubspec.yaml` 已声明 `assets/demo_data/`，`DemoDataLoader` 当前读取 `volunteers.json`、`ai_responses.json`、`help_scenarios.json`。
- 当前审计结论：Flutter 默认演示主链路基本符合 Demo-first，但仍需要继续隔离 `SeekerCenterScreen` 内的积分/异步/收藏残留、根 `supabase/` 的非 MVP 表和 `points-calculator`、真实 WebRTC/推送/admin/community 的非默认入口。

## 当前唯一 MVP 范围

| ID | 功能 | Demo MVP 验收口径 | 当前代码入口 |
|---|---|---|---|
| `F1` | AI Agent 智能对话 | 单一入口承接 OCR、场景描述、颜色识别、钞票识别、翻译、环境描述、导航、药品确认、紧急词检测；首次响应 `<= 3s`；连续 3 轮上下文正确；AI 无法处理时 `100%` 可转人工；无网络/无 API key 时走本地 demo fallback | `linklab/lib/screens/home/ai_chat_screen.dart`；`linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`；`linklab/lib/services/demo/demo_ai_service.dart`；`linklab/assets/demo_data/ai_responses.json`；`linklab/assets/demo_data/help_scenarios.json` |
| `F9` | 志愿者匹配引擎 | AI 无法处理或用户主动转人工时进入匹配；基于 demo 志愿者池展示 Top 5/默认志愿者；匹配页有处理中、成功、取消等可见状态；竞赛 Demo 不依赖真实地理位置、推送或 Supabase | `linklab/lib/demo_flow/demo_matching_flow.dart`；`linklab/lib/screens/call/demo_matching_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoMatchingService`；`linklab/assets/demo_data/volunteers.json` |
| `F11` | 实时语音通话 | 匹配成功后进入 demo 通话；必须展示连接中、已连接、挂断、评价、结果沉淀；视频、屏幕共享、真实 WebRTC 建链不进入竞赛主线 | `linklab/lib/screens/call/demo_call_screen.dart`；`linklab/lib/screens/call/demo_call_rating_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoCallService` |
| `F13` | SOS 紧急呼救 | 一键或紧急意图触发；必须显示广播、联系人通知、误触撤销窗口；Demo 允许 mock，但状态变化必须可见；唯一允许的倒计时是 10 秒误触撤销窗口 | `linklab/lib/screens/call/demo_sos_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoSOSService`；`linklab/lib/demo_flow/demo_sos_flow.dart`；`linklab/lib/services/security/emergency_contact_service.dart` 的本地 fallback |
| `F33` | 登录与无障碍偏好 | 手机号验证码登录 + 首次引导 + 简化身份/偏好设置；竞赛默认使用预置演示员会话，避免 3 分钟脚本卡在注册；登录和偏好流程仍需可独立跑通 | `linklab/lib/main.dart`；`linklab/lib/services/app_session_service.dart`；`linklab/lib/providers/app_session_provider.dart`；`linklab/lib/screens/auth/onboarding_screen.dart`；`phone_login_screen.dart`；`verification_screen.dart`；`identity_select_screen.dart`；`disability_select_screen.dart`；`preference_screen.dart` |
| `F36` | 全局无障碍适配 | 所有默认可达页面必须有清晰 `Semantics`、接近或达到 `48x48dp` 触摸目标、`>= 7:1` 对比度、支持 `200%` 字体缩放、错误状态不只靠颜色表达；读屏用户能独立完成主流程 | `linklab/lib/app.dart` 中 `TextScaler` 适配；`linklab/lib/widgets/accessible/`；默认主链路页面中的 `Semantics` 与无障碍按钮文案；闭环测试 `linklab/test/closed_loop/` |

## 明确排除范围

以下内容不属于竞赛 Demo MVP，不得进入默认导航、默认首页、默认路由、默认测试验收或 P0/P1 资源：

- 交互式社群、群聊、地区社区、新手村、训练场景；竞赛版最多保留硬编码精选故事展示。
- 积分、徽章、善意时间线、排班、多级认证、积分流水和排行榜。
- `admin_dashboard/` 与 `linklab/lib/admin/` 后台；运营后台由 Supabase Dashboard 替代，不作为竞赛 App 能力展示。
- 真实 WebRTC、真实信令、视频、屏幕共享、通话录音、AI 通话检测。
- 真实推送、FCM、App 未启动时的真实后台唤醒；Demo 只展示本地 mock 状态。
- 真实 Supabase 强依赖、真实 API key、真实 OCR key、真实部署脚本；竞赛 Demo 必须在无网络/无 key 时完成。
- 异步留言、任务队列、`async_tasks`、`point_transactions`、`reports`、`call_records`、`points-calculator` 等非 MVP 后端能力。

## 已符合 AGENTS.md 的点

- 全局入口已有 `ProviderScope`，`LinkLabApp` 可读取 Riverpod session provider。
- `AppConfig` 已锁定竞赛 demo mode，并启用演示员预置会话。
- 默认导航已收敛为 `首页 / AI助手 / 我的`，未把后台、社群、积分、真实通话放入底部导航。
- 演示数据已落在 `assets/demo_data/`，并由 `DemoDataLoader` 加载。
- `linklab/supabase/` 已标记 legacy，根目录 `supabase/` 是事实来源。
- 当前 `flutter analyze` 和 `flutter test` 通过，但注意部分默认可达文件仍被 `analysis_options.yaml` 排除，不能把通过结果误读为全主链路完全无风险。

## P0/P1/P2 修复顺序

### P0：阻断演示污染源

1. 恢复或重构默认可达文件的 analyze 覆盖：`SeekerCenterScreen`、`demo_flow`、安全/联系人入口等默认主链路文件不应长期被排除。
2. 拆分 `SeekerCenterScreen`：默认只保留“帮助档案 / 求助状态”；将 `AsyncRequestsTab`、`PointsTab`、`FavoriteVolunteersTab` 以及对 `AsyncTaskService`、`PointsService`、`VolunteerDetailScreen` 的依赖移出主文件或归档。
3. 收敛根 `supabase/`：MVP 事实表只保留 `users`、`volunteer_profiles`、`help_requests`、`emergency_contacts`、`virtual_identities`；`async_tasks`、`point_transactions`、`reports`、`call_records`、`points-calculator` 移入 legacy 或明确非竞赛路径。
4. 复核主链路没有真实 Supabase、真实 Firebase、真实 WebRTC、真实推送初始化要求；无 key、断网仍能打开 App 并完成 3 分钟脚本。

### P1：冻结 Demo / Real 边界

1. 将 `real_*` 页面、`MatchingScreen`、`RealCallScreen`、`RealCallPage`、真实 WebRTC service、推送 service、admin route 明确标记为 experimental，确认默认入口无法触达。
2. 精选故事保持静态展示；若进入详情页，移除或隐藏 like/unlike 等交互式社群行为。
3. 对 `flutter_webrtc`、Firebase、admin dashboard 相关依赖做隔离评估，避免默认平台构建被非 MVP 依赖拖垮。
4. 将 SOS mock 的 10 秒撤销窗口、广播展示、联系人通知展示与 AGENTS.md 口径对齐；真实 `<= 3s` 推送指标只作为后续真实集成验收，不冒充 Demo 已完成。

### P2：交付前收敛质量

1. 归档重复实现，例如未被默认主链路使用的 `demo_flow/demo_ai_service.dart`。
2. 逐步把 UI 直接 new service、service singleton 和裸 `setState` 流程状态迁移到 provider-backed controller。
3. 统一 `AppLogger`，减少 `print` / `debugPrint`，并补齐失败态的可见降级路径。
4. 复查 F36：动态字体 `200%`、读屏顺序、触摸目标、颜色+图标+文字三重错误表达。

## 分阶段验收命令

### P0 验收

```powershell
git status --short
cd linklab
flutter pub get
flutter analyze
flutter test test/closed_loop/seeker_center_scope_test.dart
flutter test test/closed_loop/demo_mainline_end_to_end_test.dart
rg -n "PointsTab|AsyncRequestsTab|FavoriteVolunteersTab|PointsService|AsyncTaskService|VolunteerDetailScreen" lib/screens/user_center/seeker_center_screen.dart
rg -n "points-calculator|point_transactions|async_tasks|reports|call_records" ..\supabase
```

验收口径：Flutter 命令通过；后两个 `rg` 只能命中 legacy/archive 或无输出，不能命中竞赛默认主链路。

### P1 验收

```powershell
cd linklab
flutter analyze
flutter test test/closed_loop
flutter build web --debug
rg -n "AdminLoginScreen|AdminLayout|RealCallScreen|RealCallPage|MatchingScreen\(|CommunityScreen|InterestGroupsScreen|GroupChatScreen|NewbieVillageScreen" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
rg -n "Supabase.initialize|Firebase.initializeApp|RealCallService\(|WebRTCService\(|PushNotificationService\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
```

验收口径：构建和测试通过；默认主链路搜索不出现真实后端、真实通话、后台或交互式社群入口。

### P2 验收

```powershell
cd linklab
flutter analyze
flutter test
flutter build web --release
flutter pub deps --style=compact
rg -n "print\(|debugPrint\(" lib
rg -n "factory .*Service\(\)|static final .*Service _instance|ChangeNotifier" lib/screens lib/services
```

验收口径：默认构建和全量测试通过；日志、service singleton 和 `ChangeNotifier` 残留都有明确迁移或隔离说明。
