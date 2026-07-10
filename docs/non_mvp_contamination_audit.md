# 非 MVP 防污染审计

> 口径声明：**竞赛 Demo 不依赖外部服务**。本审计只判断非 MVP 模块是否污染默认 3 分钟 Demo 主线，不等同于删除历史代码，也不声明真实后端、真实 WebRTC、真实推送或真实后台已完成。

## 审计结论

当前 Flutter 默认入口、默认底部导航和主演示链路未发现可直接进入 admin、community、points、badges、schedule、recording、真实 WebRTC 或真实 Supabase-only flow 的入口。主要风险集中在历史代码仍保留、`analysis_options.yaml` 对 legacy 模块做了排除、根 `supabase/` 仍包含 points/push/recordings/schedule 等非 MVP 结构。

## 模块清单

| 模块名称 | 当前路径 | 当前状态 | 是否可从默认首页进入 | 是否影响 flutter analyze | 是否影响 flutter test | 建议后续处理 |
|---|---|---|---|---|---|---|
| 独立运营后台 | `linklab/admin_dashboard/` | legacy / hidden | 否 | 否；当前不参与主 App analyze | 否；不在主 App 测试链路 | 保留为历史工程或单独归档；不得接回竞赛 App 默认入口 |
| 主应用内后台残留 | `linklab/lib/admin/` | legacy / hidden | 否 | 否；`analysis_options.yaml` 已排除 | 否 | 后续若做真实后台，统一到独立后台或 Supabase Dashboard，不在求助端保留入口 |
| 交互式社群 / 群聊 / 地区社区 | `linklab/lib/screens/community/**`；`linklab/lib/services/community/**` | legacy / hidden | 否 | 否；已排除 | 否 | 竞赛版最多保留静态精选故事；群聊、地区社区、新手村继续隐藏 |
| 首页旧社群页面 | `linklab/lib/screens/home/community_screen.dart` | legacy / hidden | 否 | 否；已排除 | 否 | 不接回底部导航；如需竞赛叙事，改用静态未来蓝图 |
| 积分 / 等级 / 公益时长 | `linklab/lib/services/user_center/points_service.dart`；`linklab/lib/screens/user_center/*points*` | legacy / hidden | 否 | 否；相关 user_center legacy 已排除 | 否 | 不进入默认“我的”；后续作为 V1.0 独立评估 |
| 徽章 | `linklab/lib/services/user_center/badge_service.dart`；`linklab/lib/screens/user_center/*badge*` | legacy / hidden | 否 | 否；相关 user_center legacy 已排除 | 否 | 不进入默认个人中心；仅可作为未来蓝图口播 |
| 排班 | `linklab/lib/services/user_center/schedule_service.dart`；`linklab/lib/models/schedule_model.dart` | legacy / hidden | 否 | 否；service 已排除 | 否 | F9 Demo 使用本地志愿者在线状态，不接真实排班 |
| 旧 user_center 模块 | `linklab/lib/screens/user_center/**`；`linklab/lib/services/user_center/**` | legacy / partial hidden | 默认首页不进入；当前只使用独立 Demo 帮助记录页 | 否；多数 legacy 路径已排除 | 否 | 保留帮助回看所需 demo 页面；其余积分、收藏、排班、徽章继续隔离 |
| 通话录音 / AI 录音检测 | `linklab/lib/services/security/call_recording_service.dart`；`linklab/lib/services/webrtc/call_recording_service.dart` | legacy / hidden | 否 | 否；已排除 | 否 | V2.0 之前不得进入 F11 Demo Call；不得请求录音权限 |
| 真实 WebRTC 服务 | `linklab/lib/services/webrtc/**`；`linklab/lib/services/webrtc_service.dart`；`linklab/lib/services/experimental/real/webrtc/real_webrtc_service.dart` | experimental / hidden | 否 | 默认主分析不依赖；部分 legacy 已排除 | 否；Demo Call 测试断言 feature flag 关闭 | 继续放在 experimental/real adapter 后方；默认不得初始化或请求麦克风 |
| 真实通话页面 | `linklab/lib/screens/call/real_call_screen.dart`；旧 `lib/pages/call/**` | experimental / hidden | 否 | 否；已排除 | 否 | 不接回 F11 默认路径；F11 RC 只验收 Demo Call 状态机 |
| 真实匹配服务 | `linklab/lib/services/real_matching_service.dart` | experimental / hidden | 否 | 否；已排除 | 否 | F9 RC 使用 `DemoMatchingEngineService`；真实服务待 schema 收口后再评估 |
| 生产推送通知 | `linklab/lib/services/push_notification_service.dart`；`supabase/functions/push-notifier/` | experimental / backend residual | 否 | Flutter 主线不依赖 | Flutter 主线不依赖 | 保留为后续基础设施；竞赛 Demo 不得要求 FCM token 或真实推送 |
| 生产紧急通知 / 真实短信 | `linklab/lib/services/sos_service.dart`；安全相关 legacy service | experimental / hidden | 否 | 否；相关路径已排除 | 否 | F13 RC 只做 Mock；不得默认发短信、定位、报警 |
| volunteer advanced certification | 志愿者高级认证相关旧页面 / service | hidden / V1.0 | 否 | 当前不影响 | 当前不影响 | F33 RC 只保留预置演示员会话与基础偏好，不做专业认证 |
| `linklab/supabase` 分叉 | `linklab/supabase/legacy/**` | legacy | 否 | 否 | 否 | 根 `supabase/` 是唯一事实来源；该分叉继续停止执行或归档 |
| 根 Supabase points function | `supabase/functions/points-calculator/`；`supabase/config.toml` | active backend residual / non-MVP | 否 | 不影响 Flutter analyze | 不影响 Flutter test | 交付前标记 legacy 或移出竞赛部署清单；不得作为 F15 展示 |
| 根 Supabase push function | `supabase/functions/push-notifier/`；`supabase/config.toml` | active backend residual / infrastructure | 否 | 不影响 Flutter analyze | 不影响 Flutter test | 仅可作为后续 F34 基础设施；竞赛 Demo 不依赖真实推送 |
| 根 Supabase 非 MVP 表 | `supabase/migrations/*.sql` 中 `point_transactions`、`call_records`、`available_schedule`、`push_logs` 等 | active backend residual / contamination risk | 否 | 不影响 Flutter analyze | 不影响 Flutter test | MVP schema 后续收口到 `users`、`volunteer_profiles`、`help_requests`、`emergency_contacts`、`virtual_identities` |
| 默认底部导航 | `linklab/lib/screens/home/main_screen.dart` | active / demo-only | 是；仅：首页 / AI助手 / 我的 | 是；已通过主线 analyze | 是；`widget_test.dart` 覆盖 | 继续禁止加入社群、积分、徽章、排班、后台等非 MVP tab |
| 配置 feature flags | `linklab/lib/config/app_config.dart` | active / demo-only guard | 间接影响默认入口 | 是 | 是；`widget_test.dart` 新增关闭断言 | 保持 `isCompetitionDemoOnly = true`；真实模式不得在竞赛构建打开 |

## 后续处理优先级

1. **P0 赛前保持**：默认导航、首页卡片、AI、匹配、通话、SOS 不接入非 MVP 模块；feature flags 维持关闭。
2. **P1 后端收口**：根 `supabase/` 中 points、recordings、schedule、push 等非 MVP residual 需要拆分为 legacy 或后续部署清单。
3. **P2 架构清理**：逐步把 legacy `ChangeNotifier` / singleton service 收敛到 provider-backed facade，但不要在 RC 前做大规模重构。
