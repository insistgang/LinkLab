# 共感 LinkAble 3 分钟竞赛 Demo 脚本

> 最高事实来源：根目录 `AGENTS.md` §8
> 关键声明：**竞赛 Demo 不依赖外部服务**。脚本必须在无网络、无真实 API key、无真实 Supabase、无真实推送、无真实 WebRTC 的情况下可重复完成。

## 演示前检查

- 使用竞赛 demo mode 启动 App；默认应通过演示员预置会话进入首页，不在现场消耗时间注册。
- 设备可以关闭网络或不配置任何真实 API key；OCR、场景描述、匹配、通话、SOS 均使用本地 demo fallback。
- 默认底部导航只展示 `首页 / AI助手 / 我的`。
- 不打开 admin、真实 WebRTC、真实 Supabase Dashboard、交互式社群、积分或徽章页面。

## 时间轴

| 时间 | 必跑动作 | 讲解重点 | 预期可见状态 | 当前代码入口 |
|---|---|---|---|---|
| `0:00-0:20` | 打开 App，停留首页，展示大按钮 | “共感 LinkAble 是 AI Agent 第一响应、人类志愿者兜底的无障碍互助 App。竞赛 Demo 不依赖外部服务。” | 首页立即可见；主按钮“我需要帮助”；底部导航为 `首页 / AI助手 / 我的`；主按钮有读屏语义、高对比和大触摸目标 | `linklab/lib/main.dart`；`linklab/lib/app.dart`；`linklab/lib/screens/home/main_screen.dart`；`linklab/lib/screens/home/home_screen.dart` |
| `0:20-0:50` | 点击首页大按钮或进入 AI 助手，输入/选择“帮我读药品盒” | “AI 先处理日常求助。本地 demo 数据模拟 OCR，即使没有 OCR key 也能返回稳定结果。” | AI 显示正在分析；返回药品 OCR demo 结果，例如阿莫西林胶囊、规格、用法用量、有效期；页面提供继续提问或转人工入口 | `linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`；`linklab/lib/services/demo/demo_ai_service.dart`；`linklab/assets/demo_data/ai_responses.json` |
| `0:50-1:30` | 输入/选择“我面前是什么” | “同一个 AI Agent 入口也承接场景描述，不把 OCR、看图、导航拆成多个复杂入口。” | AI 显示场景描述 demo 响应，例如室内/街道/公园/超市场景；有文字结果、状态变化和继续求助入口 | `linklab/lib/screens/home/ai_chat_screen.dart`；`linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`；`linklab/lib/services/demo/demo_ai_service.dart` |
| `1:30-2:10` | 输入复杂需求或点击转人工，进入志愿者匹配，再进入 demo 通话 | “AI 无法处理时 100% 有人类兜底。F9 接单后进入 F11 Demo Call，展示连接中、已接通、结束通话、完成评价；竞赛版不依赖真实 WebRTC。” | 进入匹配页；展示匹配中、Top 5 候选志愿者、匹配成功；自动或手动进入 demo 通话；通话页显示连接中、已接通、通话中、挂断；结束后进入帮助完成评价/结果落点；不建立真实 WebRTC、不录音、不真实推送 | `linklab/lib/demo_flow/demo_matching_flow.dart`；`linklab/lib/screens/call/demo_matching_screen.dart`；`linklab/lib/screens/call/demo_call_screen.dart`；`linklab/lib/screens/call/demo_call_rating_screen.dart`；`linklab/lib/providers/demo_call_flow_provider.dart` |
| `2:10-2:40` | 返回首页或通过 AI 紧急意图触发 SOS mock 演示 | “SOS 是广播型紧急流程，不走普通匹配公式。Demo 会让评审看到误触撤销、广播和联系人通知状态。” | 进入 SOS 页面；显示 10 秒误触撤销窗口；显示 Mock 广播演示；显示联系人通知状态；可撤销或继续到志愿者响应状态 | `linklab/lib/screens/call/demo_sos_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoSOSService`；`linklab/lib/demo_flow/demo_sos_flow.dart` |
| `2:40-3:00` | 展示未来蓝图 | “当前已演示的是 MVP 六项：F1/F9/F11/F13/F33/F36。V1.0/V2.0 是路线图，不冒充已完成能力。” | 只展示或口播后续计划：真实 WebRTC、真实推送、完整后台、社群、积分等属于后续版本；不进入半成品页面 | `docs/competition_mvp_delivery_plan.md`；首页的 MVP 范围说明；演示 PPT 或静态蓝图页 |

## 逐段口播要点

### `0:00-0:20` 首页

推荐口播：

> 这是共感 LinkAble。我们的核心不是堆功能，而是让视障或行动不便用户在需要帮助时，用一个大按钮进入 AI Agent；AI 能解决就立即解决，解决不了就转真人志愿者。

必须展示：

- 首页第一屏可见。
- 大按钮足够醒目。
- 默认导航没有社群、积分、后台等非 MVP 功能。

### `0:20-0:50` 药品 OCR

推荐口播：

> 这里演示“帮我读药品盒”。竞赛环境不依赖真实 OCR 服务，当前响应来自本地 demo 数据，所以断网也能稳定复现。

必须展示：

- 用户输入或选择“帮我读药品盒”。
- AI 有“正在分析”或类似处理中状态。
- 结果必须包含药名、规格、用法用量等可读信息。

### `0:50-1:30` 场景描述

推荐口播：

> 同一个入口继续处理“我面前是什么”。这避免让用户在多个功能按钮里做选择，符合低认知负担原则。

必须展示：

- 场景描述以文字形式展示。
- 如果 AI 没法处理，必须能转人工，不能出现死路。

### `1:30-2:10` 匹配与 demo 通话

推荐口播：

> 对复杂问题，AI 不硬答，直接转人工。F9 接单后进入 F11 Demo Call，现场展示连接中、已接通、结束通话和完成评价；这里不建立真实 WebRTC，不录音，也不触发真实推送。

必须展示：

- 匹配页状态变化。
- 至少一个志愿者被匹配。
- 通话页状态从连接中到已接通、通话中、结束通话。
- 结束后出现评价或结果回看落点。

### `2:10-2:40` SOS mock

推荐口播：

> SOS 是紧急广播流程，与普通匹配不同。为了避免误触，系统保留 10 秒撤销窗口；Demo 同时展示广播和联系人通知状态。

必须展示：

- 10 秒误触撤销窗口。
- Mock 广播演示。
- 紧急联系人通知状态。
- 用户能撤销误触，或看到 SOS 继续推进。

### `2:40-3:00` 未来蓝图

推荐口播：

> 今天验收的是 MVP：AI Agent、志愿者匹配、demo 通话、SOS、登录偏好和全局无障碍。真实 WebRTC、真实推送、后台、社群和积分会进入后续 V1.0/V2.0，不把未完成能力冒充为当前已上线。

禁止口播：

- “真实 WebRTC 已完整上线。”
- “真实推送和后台唤醒已经完成。”
- “积分、社群、后台是本次 MVP 的核心能力。”
- “当前 Demo 依赖线上 Supabase 才能跑。”

## 失败降级口径

- 如果现场无网络：直接说明竞赛 Demo 不依赖外部服务，并继续跑本地 demo fallback。
- 如果 AI 响应不符合预期：点击预置场景按钮或重新输入脚本词，确保落到 `assets/demo_data/` 中的稳定响应。
- 如果匹配停留过久：使用默认 demo matching 入口重新进入，避免切到真实匹配页。
- 如果 SOS 联系人为空：说明当前仍会演示志愿者广播；联系人可在“我的 > 紧急联系人”中补全，但不阻塞 Demo。
