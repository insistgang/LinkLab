历史记录：2026-04-17 项目修复工作曾标记为 P0+P1+P2 全部收口。当前对外口径以 `DEMO_STATUS.md` 和 `docs/rc_acceptance_evidence.md` 为准。

# TODO.md - 共感 LinkAble MVP 修复执行清单（2026.04）

> 依据：`AGENTS.md`
> 说明：本清单只服务当前 MVP 主线 `F1 / F9 / F11 / F13 / F33 / F36`，不为已砍掉或降级功能分配默认交付资源。
> 2026-05-01 文档口径补充：本文件是历史执行清单，不是当前运行环境的复验报告。本轮未运行 Flutter；Web / Chrome 是首选演示路径，Windows 桌面需要 Visual Studio C++ toolchain。

## P0（立即必须完成）

### 1. 修复 Riverpod 全局 `ProviderScope` 缺失

- 具体要做什么：
  - 在 `runApp` 根节点提供全局 `ProviderScope`
  - 校验所有可达 `ConsumerWidget` / `ConsumerStatefulWidget` 页面都运行在统一 Riverpod 容器内
  - 在入口代码中补充清晰注释，说明竞赛版默认仍走 Demo 主线，但全局状态容器不可缺失
- 涉及的主要文件：
  - `linklab/lib/main.dart`
  - `linklab/lib/app.dart`
  - 受影响可达 Riverpod 页面：`linklab/lib/screens/community/interest_groups_screen.dart`、`linklab/lib/screens/call/real_call_screen.dart`、`linklab/lib/pages/call/real_call_page.dart`、`linklab/lib/widgets/call/call_controls.dart`
- 完成标准：
  - `runApp` 根节点为 `ProviderScope`
  - 应用入口存在明确的 Demo-first 与 Riverpod 说明
  - 不新增新的 `ChangeNotifier` 业务状态、裸流程 `setState` 状态源或新的 service singleton

### 2. 全仓资源清单核对 + 补齐 / 统一回退资源

- 具体要做什么：
  - 核对 `pubspec.yaml` 的资源声明与磁盘实际文件
  - 扫描所有 `Image.asset(...)`、资源路径常量与头像/插图引用
  - 对缺失资源统一补齐或替换为占位图、文本头像、无图回退
- 涉及的主要文件：
  - `linklab/pubspec.yaml`
  - `linklab/admin_dashboard/pubspec.yaml`
  - `linklab/assets/**`
  - `linklab/lib/widgets/accessible/accessible_image.dart`
  - 所有图片资源引用点
- 完成标准：
  - 主链路不再因资源缺失报错
  - `pubspec.yaml` 资源声明与实际目录一致
  - 竞赛版演示不出现空白、断图或运行时资源异常
- 完成记录（2026-04-17）：
  - 已全量扫描 `linklab/lib` 与 `linklab/admin_dashboard/lib` 中的 `Image.asset`、`AssetImage`、`precacheImage`、`SvgPicture.asset`、`rootBundle.load*` 等资源入口；主应用实际 Flutter assets 仅剩 `assets/demo_data/*.json` 和训练场景页的可选图片入口，后台未发现 Flutter asset bundle 依赖。
  - 已将主应用 `pubspec.yaml` 收口为只声明实际使用的 `assets/demo_data/`；`admin_dashboard/pubspec.yaml` 已补充说明：后台仅使用 `web/` 静态图标，不通过 Flutter assets 打包。
  - 已新增 `linklab/lib/widgets/accessible/accessible_image.dart`，统一处理 asset / network 图片加载失败时的无障碍回退，提供 `Semantics`、可见占位图标与替代文本。
  - 已将训练场景页切换到 `AccessibleImage.asset(...)`，即使未来收到缺失的 asset 路径，也会稳定回退到无障碍占位态。
  - 已确认主应用缺失的头像和训练示意图资源不再阻塞 Demo 主线：志愿者头像统一退回文字头像，训练图统一走组件回退。

### 3. 清理社区 / 社群模块所有硬编码 `current_user_id`

- 具体要做什么：
  - 将社区、社群、群聊、新手村等模块中的硬编码 `current_user_id` 全部改为读取 `AppSessionService` 当前用户
  - 不属于 MVP 的页面若仍挂在默认导航，应直接隐藏或移出主链路
- 涉及的主要文件：
  - `linklab/lib/services/app_session_service.dart`
  - `linklab/lib/screens/community/interest_groups_screen.dart`
  - `linklab/lib/screens/community/regional_community_screen.dart`
  - `linklab/lib/screens/community/group_chat_screen.dart`
  - `linklab/lib/screens/community/newbie_village_screen.dart`
  - `linklab/lib/screens/community/training_scenario_screen.dart`
  - `linklab/lib/screens/community/story_detail_screen.dart`
  - `linklab/lib/services/unified_call_service.dart`
  - `linklab/lib/services/unified_matching_service.dart`
- 完成标准：
  - 主链路代码中不再出现硬编码 `current_user_id`
  - 所有保留页面都读取统一会话上下文
  - Demo 模式下未登录时有安全 fallback，不会因空用户中断页面
- 完成记录（2026-04-17）：
  - 已全量扫描 `linklab/lib/` 中的 `current_user_id`、`const userId = 'current_user_id'`、`hardcoded user id` 等硬编码用户 ID；当前仓内已无残留硬编码占位用户 ID。
  - 已将社区/社群相关页面、故事详情页，以及 Demo/Real 过渡层中的用户 ID 读取统一为 `AppSessionService.instance.currentUser?.id ?? 'demo-user-id'`。
  - 已在 `AppSessionService` 中补充显式 `currentUser` getter，页面层不再依赖硬编码字符串，也不需要直接读取 Supabase Auth 才能获得当前演示用户。
  - 已确认默认底部导航仍不包含社区入口；社区模块代码保留但不抢占 MVP 默认导航，符合当前竞赛范围控制要求。

### 4. 统一 Supabase schema 的唯一事实来源

- 具体要做什么：
  - 明确根目录 `supabase/` 是唯一 schema source of truth
  - 停止 `linklab/supabase/` 继续作为并行 schema 入口
  - 识别并清理双套 migration / function / config 的冲突引用
- 涉及的主要文件：
  - `supabase/`
  - `linklab/supabase/`
  - 相关引用配置与说明文档
- 完成标准：
  - 后续 schema 变更只允许落在根 `supabase/`
  - `linklab/supabase/` 被归档、停用或显式标识为历史目录
  - 不再存在两套并行数据库事实来源
- 完成记录（2026-04-17，当前执行轮次 / 用户指定 P1-第1项）：
  - 已新增根迁移 `supabase/migrations/005_unify_root_schema_source_of_truth.sql`，将 `help_requests` 状态机收口到 `AGENTS.md §5.2`，并补齐 `virtual_identities` 核心表。
  - 已在根 schema 为当前保留的实验性真实链路补齐最小基础设施表：`user_devices`、`push_logs`、`ai_call_logs`、`emergency_notifications`、`notifications`；不再依赖 `linklab/supabase/` 历史分叉。
  - 已将 `linklab/supabase/` 下原 `functions/`、`migrations/` 全部移动到 `linklab/supabase/legacy/`，并在原目录留下只读 `README.md`，明确根 `supabase/` 是唯一事实来源。
  - 已重写根 `supabase/functions/matching-engine/index.ts`，只使用根 schema 的 `help_requests` / `volunteer_profiles` / `async_tasks` / `find_matching_volunteers(...)`。
  - 已重写根 `supabase/functions/push-notifier/index.ts`，改为读取根 schema 中的 `user_devices` / `push_logs`，无 FCM key 时自动返回 mock success，避免真实推送阻塞竞赛版。

### 5. 修复数据库 schema 与 Edge Function / 客户端代码不一致

- 具体要做什么：
  - 对齐 `users`、`volunteer_profiles`、`help_requests`、`emergency_contacts`、`virtual_identities` 等 MVP 核心表字段
  - 对齐 Edge Functions、客户端 service 与 migration 中的字段名、状态枚举和主流程数据流
  - 真实路径未对齐前，一律回退为 Demo fallback，不得阻塞竞赛主线
- 涉及的主要文件：
  - `supabase/migrations/*.sql`
  - `supabase/functions/**`
  - `linklab/lib/services/**/*real*`
  - `linklab/lib/services/realtime_sync_service.dart`
  - `linklab/lib/services/sos_service.dart`
- 完成标准：
  - 客户端字段访问与根 `supabase/` migration 一致
  - `help_requests.status` 与 `AGENTS.md` §5.2 状态机一致
  - 竞赛版主流程不再依赖字段不一致的真实后端链路

### 6. 补齐或移除代码中引用但 migration 未创建的关键表

- 具体要做什么：
  - 清点代码中引用但根 `supabase/` 未定义的表
  - 对主链路必须存在的表补 migration
  - 对非 MVP 或不稳定表引用统一切回 Demo 本地数据或从主链路移除
- 涉及的主要文件：
  - `supabase/migrations/*.sql`
  - `linklab/lib/services/sos_service.dart`
  - `linklab/lib/services/community/featured_story_service.dart`
  - `supabase/functions/**`
- 完成标准：
  - 主链路不再访问不存在的数据库对象
  - 所有保留表引用都能在根 `supabase/` 中找到定义，或已完成 Demo 回退

## P1（1-3 天内完成）

### 1. 冻结 Demo / Real 边界，明确竞赛版只保留 Demo 主线

- 具体要做什么：
  - 在入口、配置、导航和关键服务层明确 Demo-first 策略
  - 隔离 `real_*` 页面、真实 WebRTC、真实推送与真实 Supabase 主链路依赖
  - 当真实依赖缺失或不稳定时自动回退到本地 Demo 数据
- 涉及的主要文件：
  - `linklab/lib/main.dart`
  - `linklab/lib/config/app_config.dart`
  - `linklab/lib/screens/home/**`
  - `linklab/lib/services/unified_*`
- 完成标准：
  - 默认启动、默认导航、默认演示只走 Demo 主线
  - 真实链路不再阻塞 `F1 -> F9 -> F11` 闭环
- 完成记录（2026-04-17，按 AGENTS.md §7“实施节奏补充”提前执行）：
  - 已在 `main.dart` 中显式执行 `AppConfig.demoMode = true;`，并继续通过 `lockCompetitionDemoMode()` 锁定竞赛版只走 Demo 主线。
  - 已在 `app.dart`、`home/main_screen.dart`、`home/home_screen.dart` 补充断言与说明，确保默认入口、底部导航和首页文案都明确指向 Demo-only 演示闭环。
  - 已将 `unified_matching_service.dart`、`unified_call_service.dart`、`unified_sos_service.dart`、`matching_service.dart`、`ai_service_manager.dart` 的 Demo/Real 分流统一绑定到 `AppConfig.demoMode`。
  - 已为主链路相关 `demo_*` fallback 服务补充 `AppConfig.shouldUseDemoFallback(...)` 判定；当 Demo 开关关闭时，这些服务不会再被误当成默认实现。
  - 已在 `real_*` 与 unified 调用真实服务的位置补充 `AGENTS.md §4.2` 注释，明确真实链路仅供实验，不进入默认导航和竞赛演示脚本。
  - 当前阶段前置依赖已完成：根 `supabase/` 已收口为唯一 schema source of truth，真实匹配 / SOS / 推送只允许对齐根 migration 与根 Edge Functions。
- 完成记录（2026-04-17，当前执行轮次 / 用户指定 P1-第2项）：
  - 已新建 `linklab/lib/services/experimental/real/`，并将 `real_call_service.dart`、`real_matching_service.dart`、`sos_service.dart`、`webrtc_service.dart`、`ai/real_ai_service_manager.dart`、`webrtc/real_webrtc_service.dart` 的实现迁入实验目录。
  - 原路径现仅保留兼容导出壳，避免历史实验页立即失效；默认 barrel `services_exports.dart`、`ai_module_export.dart`、`webrtc_exports.dart` 已停止导出真实实现。
  - 已将 `unified_matching_service.dart`、`unified_sos_service.dart` 强制收口为 Demo-only；`unified_call_service.dart` 默认只驱动 Demo 通话，真实通话仅可通过显式 experimental API 进入。
  - 已将旧 facade `matching_service.dart`、`call_service_factory.dart`、`ai_service_manager.dart` 冻结为 Demo-first / Demo-only，阻断默认分流自动进入真实链路。
  - 已再次确认默认路由与默认底部导航仍只保留 `Home / AIChat / Profile`，并从 `home_screen.dart` 移除异步留言入口，避免非 MVP 页面继续出现在默认首页。

### 3. 补齐 5 条关键闭环测试

- 具体要做什么：
  - 为启动 / 登录、AI -> 转人工、匹配 / 通话 / 评价、SOS、Demo 主线端到端各补一条有效测试
  - 优先覆盖状态变化、页面可见反馈和 Demo fallback
- 涉及的主要文件：
  - `linklab/test/**`
  - 相关 screen / service / provider
- 完成标准：
- 5 条关键闭环都有自动化测试
  - 测试断言与 `AGENTS.md` 状态机、Demo-first 策略一致
- 完成记录（2026-04-17，当前执行轮次 / 用户指定 P1-第3项）：
  - 已新增 `linklab/test/closed_loop/test_harness.dart`，统一准备 `AppConfig.demoMode = true`、`ProviderScope`、`AppSessionService` 预置会话和本地 Demo 数据环境。
  - 已新增 5 个带 `@Tags(['demo', 'closed-loop'])` 的闭环测试：`startup_login_closed_loop_test.dart`、`ai_to_human_closed_loop_test.dart`、`matching_call_rating_closed_loop_test.dart`、`sos_closed_loop_test.dart`、`demo_mainline_end_to_end_test.dart`。
  - 已新增 `linklab/dart_test.yaml`，为 `demo` / `closed-loop` 标签提供测试配置，便于按主链路回归。
  - 已补充 `linklab/lib/demo_flow/demo_help_request_tracker.dart`，把 Demo 主线的本地 `help_request` 状态显式追踪到 `ai_processing -> ai_resolved / matching -> connected -> completed`，并覆盖 SOS 的 `created -> cancelled / matching` 转换。
  - 已为 AI、匹配、通话、SOS 的 Demo 流程补齐测试所需的本地状态写入与可见反馈，确保不依赖真实 Supabase、真实推送或真实 WebRTC。
  - 已完成 `flutter test --tags demo` 回归，P1 全部完成。

## P2（交付前完成）

### 1. 清理 `flutter analyze` 高噪音问题

- 具体要做什么：
  - 先处理会遮蔽真实问题的高噪音 warning / lint
  - 聚焦首页、AI 主线、匹配、通话、SOS、登录与无障碍相关文件
- 涉及的主要文件：
  - `linklab/lib/**`
  - `linklab/test/**`
- 完成标准：
  - 主应用 analyze 噪音显著下降
  - 主链路问题不再被无关警告淹没
- 完成记录（2026-04-17，当前执行轮次 / 用户指定 P2-第1项）：
  - 已运行 `flutter analyze lib`（`linklab/`）与 `flutter analyze lib`（`linklab/admin_dashboard/`），并记录清理前后数量。
  - 主应用已通过 `analysis_options.yaml` 明确排除 `AGENTS.md` 已冻结的非 MVP / experimental / 历史分叉目录，使默认 analyze 范围收口到竞赛主链路。
  - 已将主应用默认链路和后台中的高频 `withOpacity(...)` 全部收敛为 `withValues(alpha: ...)`，同步消除 Flutter 新版本弃用噪音。
  - 已修复 `AppLogger` 的过时 API 用法，统一改为 `dateTimeFormat` 与 `trace` 级别调用，继续满足 `AGENTS.md §4.6` 的正式日志要求。
  - 已清理一批 `unused import`、`unused local variable`、`unnecessary cast`、`BuildContext` 异步告警和可直接消除的 `prefer_const_*` 噪音。
  - 清理结果：
    - 主应用：`629 -> 70`
    - `admin_dashboard`：`36 -> 9`
  - `P2 第1项完成`

### 2. 统一日志与错误处理，减少 `print`

- 具体要做什么：
  - 用 `AppLogger` 替换主链路正式日志中的 `print` / `debugPrint`
  - 为关键异步流程补齐 `loading / success / empty / error / retry` 状态表达
- 涉及的主要文件：
  - `linklab/lib/services/**`
  - `linklab/lib/core/utils/logger.dart`
  - 主流程 screen / controller / provider
- 完成标准：
  - 主流程关键文件不再新增 `print`
  - 用户端失败都有明确文案与降级路径
- 完成记录（2026-04-17，当前执行轮次 / 用户指定 P2-第2项）：
  - 已全仓扫描 `linklab/lib/**/*.dart` 中的 `print(` 与 `debugPrint(`，并将残留调用统一替换为 `AppLogger.verbose / info / warning / error`。
  - 已补齐实验真实链路、WebRTC、旧 Demo SOS 流程中的 catch 日志，统一使用 `AppLogger.error(message, error, stackTrace)` 记录失败上下文。
  - 已确认默认主链路与实验隔离目录都不再残留 raw `print` / `debugPrint`。
  - `P2 第2项完成`

### 3. 规范配置与密钥管理

- 具体要做什么：
  - 收敛 `api_config.dart`、环境变量和示例模板
  - 清理不应进入版本控制的真实配置
  - 补足本地演示所需的 mock / example 配置说明
- 涉及的主要文件：
  - `.gitignore`
  - `linklab/lib/config/api_config.dart`
  - 相关 `.example` / README / 配置模板
- 完成标准：
  - 敏感配置有明确模板与注入方式
  - 竞赛版本地运行不依赖真实密钥
- 完成记录（2026-04-17，当前执行轮次 / 用户指定 P2-第3项）：
  - 已将 `linklab/lib/config/api_config.dart` 调整为本地实验专用文件，并通过仓库根 `.gitignore` 与 `linklab/.gitignore` 双重忽略。
  - 已新增/规范 `linklab/lib/config/api_config.example.dart` 作为唯一入库模板，并同步修正相关文档引用。
  - 已执行 `git rm --cached linklab/lib/config/api_config.dart`，停止真实配置文件被 Git 继续追踪。
  - 已复核 `supabaseUrl / supabaseAnonKey / API key` 相关常量，代码库只保留占位值或公开服务端点，未保留真实密钥。
  - `P2 第3项完成`

## 竞赛演示闭环检查项

| 时间 | 必跑动作 | 当前状态 | 说明 |
|---|---|---|---|
| `0:00–0:20` | 打开 App，大按钮吸睛 | `需回归验证` | 需确认默认启动不会被真实登录、真实初始化或资源缺失阻塞 |
| `0:20–0:50` | 语音求助“帮我读药品盒”→ AI 识别朗读 | `已具备` | Demo AI 路径已存在，需在 P0 修复后回归弱网 / 本地 fallback |
| `0:50–1:30` | “我面前是什么”→ 场景描述 | `已具备` | 需确认场景描述继续走稳定 Demo 响应，不被真实多模态依赖卡住 |
| `1:30–2:10` | 复杂需求 → `F9` 匹配 → `F11` 通话 | `已具备` | 当前 Demo matching + demo call 是主闭环，必须持续保持稳定 |
| `2:10–2:40` | `F13` SOS 演示（Mock 模式） | `需回归验证` | 需确认 SOS 走 Mock 广播、联系人通知和 10 秒撤销窗口 |
| `2:40–3:00` | 展示未来蓝图 | `需修复` | 需要单独的静态蓝图展示，不得混入未完成真实功能冒充已完成 |

## 验证记录口径补充（2026-05-01）

- `2026-04-17` 历史记录中，`flutter test --tags demo` 曾标记为通过；同一批记录也写明 `flutter analyze lib` 仍存在主应用 `70 issues found`、`admin_dashboard` `9 issues found`。
- `docs/rc_acceptance_evidence.md` 的 RC 记录写明，后续曾有 `flutter analyze` 为 `No issues found`、`flutter test --reporter compact` 为 `All tests passed`（60 tests）的结果。
- `docs/competition_mvp_delivery_plan.md` 和 `docs/plans/2026-04-12-prd-alignment-main-frontend.md` 已把 `flutter build web --debug` / `flutter build web --release` 纳入 Web 演示验收口径。
- 上述记录来自不同时间点，不应混写成“当前全部已复验”。本轮只整理 Markdown 文档，未运行 `flutter test`、`flutter analyze`、`flutter build web` 或任何 Flutter 命令。
- 交付前建议以 Web / Chrome 为主路径重新执行：`flutter test`、`flutter build web --release`，并把具体日期、命令和结果补入 `docs/rc_acceptance_evidence.md`。
- 真实 WebRTC、真实 Supabase、真实推送、真实短信和生产级 SOS 仍按实验/后续能力处理；竞赛 Demo 只承诺本地 Demo fallback 与 Mock 状态展示。
