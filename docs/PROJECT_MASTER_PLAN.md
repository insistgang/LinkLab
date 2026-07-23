# LinkAble 整体项目总纲与执行计划

> 文档状态：审查冻结版，三轮审查完成，可按本文件执行
> 建立日期：2026-07-24
> 适用仓库：`LinkLab/`
> 最高约束：根目录 `AGENTS.md`
> 维护规则：本文件是当前项目唯一的“范围、进度、任务与验收”总索引；历史文档只作为证据，不再单独代表实时状态。

## 1. 项目目标

LinkAble 当前交付目标是一套面向无障碍互助场景的竞赛 MVP：

1. AI Agent 先处理标准化求助。
2. AI 无法安全解决时转入志愿者匹配。
3. 匹配后进入可稳定演示的语音协助闭环。
4. 紧急情况进入带误触撤销、广播和联系人通知状态的 SOS 流程。
5. 登录、偏好和全局无障碍能力贯穿主流程。
6. Web / Chrome 在无网络、无真实密钥时仍能完成 3 分钟演示。

### 1.1 当前版本定义

- 产品形态：Demo-first MVP。
- 主要平台：Flutter Web / Chrome。
- 主要语言：简体中文。
- 默认数据：本地 deterministic Demo 数据。
- 默认后端：不依赖线上 Supabase。
- 真实能力：只允许在显式 RealMode 或 experimental 路径中验证，不得阻塞竞赛主线。

### 1.2 不属于当前完成定义

- 交互式社区、群聊、地区社群。
- 积分、徽章、排班、复杂异步任务。
- 生产级 WebRTC、真实短信、真实报警、后台唤醒。
- 独立运营后台作为竞赛主应用能力。
- 把实验性 Supabase / 推送 / AI 接口表述为已经生产上线。

### 1.3 语言口径

- UI、文档、提交材料和默认演示统一使用简体中文。
- 不保留独立繁体 UI 分支。
- “繁体 OCR Demo 稳定”只表示 F1 能读取繁体输入样例，不等于维护一套繁体界面。

## 2. 当前事实基线

### 2.1 Git 与工程状态

- 当前分支：`main`。
- 本轮收口起点：`3eb6810 fix: 加固 LinkAble 安全与 MVP 交付`。
- 最终提交与远端同步状态以仓库 `main` 最新记录为准，不在文档中固化动态 ahead / behind 数字。
- 主 Flutter 工程：`linklab/`。
- 当前手写 Dart 文件：约 254 个。
- 当前测试文件：29 个。
- 当前工作目录占用：约 1.9 GB，其中本轮 Web 构建缓存 `linklab/build/` 约 1.4 GB、`.dart_tool/` 约 174 MB。
- 排除 Git、交付包、构建与工具缓存后，源码/文档/配置约 9.8 MB；`dist/` 历史交付包约 190 MB。

### 2.2 最近一次本地验证

| 检查 | 最近结果 | 状态 |
|---|---|---|
| `flutter test --reporter compact` | 114 项测试通过 | 已通过 |
| `flutter analyze` | No issues found | 已通过 |
| `flutter build web --release` | 构建成功 | 已通过 |
| `flutter build apk --release` | `1.0.1 (2)`，92.0 MB，v2 签名校验通过 | 已通过 |
| 活跃 Edge Function 部署面 | 0 个；历史函数已隔离 | 已通过 |
| `git diff --check` | 无补丁格式问题 | 已通过 |

说明：`flutter_tts` 仍会产生 WebAssembly 兼容提示，但 JavaScript Web Release 构建成功。

### 2.3 线上 Supabase 事实

项目：`LinkAble-Prod`（`eeqeoteiowasoubxsuos`）

| 项目 | 线上事实 |
|---|---|
| 项目状态 | `ACTIVE_HEALTHY` |
| Auth 用户 | 2 |
| `public` 业务表 | `profiles`、`help_requests`、`volunteer_profiles` |
| 三张业务表数据 | 均为 0 行 |
| RLS | 三张表均已开启 |
| Supabase 迁移记录 | 0 |
| 已部署 Edge Functions | 0 |
| 安全顾问 | 泄露密码保护未开启 |

关键结论：

- 线上结构与 `202605240001_realmode_phase3_minimal_crud.sql` 基本一致。
- 根目录早期 `001`—`005` 迁移描述的是另一套历史全量 schema。
- `202607230001_harden_edge_functions.sql` 依赖线上不存在的积分与通知表。
- 当前 Edge Functions 依赖线上不存在的字段、表或 RPC，不能直接部署。
- Flutter 默认入口向 `AppConfig` 传入空环境，当前发布构建实际不会进入 RealMode。

## 3. 总体架构与依赖顺序

```text
AGENTS.md / 本总纲
        │
        ├── Demo 合同与本地数据
        │       ├── Riverpod 流程状态
        │       ├── Flutter 页面与无障碍组件
        │       └── 闭环测试 / Web 构建
        │
        └── RealMode 合同（默认关闭）
                ├── Supabase Auth
                ├── 最小生产 schema
                ├── RealDatabaseRepository
                └── 实验性匹配 / 推送 / WebRTC（后续）
```

执行必须遵循：

1. 先冻结范围与事实来源。
2. 再保证 Demo 主线和无障碍验收。
3. 再收敛 Supabase schema 与部署边界。
4. 最后才允许逐条打开真实能力。

## 4. MVP 功能完成定义

| ID | 功能 | 当前状态 | 完成标准 |
|---|---|---|---|
| F1 | AI Agent | Demo 已实现 | OCR、场景、常见求助、低信心转人工、紧急词转 SOS 均有 deterministic 结果和错误落点 |
| F9 | 志愿者匹配 | Demo 已实现 | Top 5、取消、超时、单人接单结果可复现；真实匹配不进入默认路径 |
| F11 | 语音协助 | Demo 已实现 | connecting / connected / reconnecting / ended / rating 闭环稳定 |
| F13 | SOS | Mock 已实现 | 10 秒撤销窗口、模拟广播、联系人通知状态、取消与完成态清楚标注 |
| F33 | 登录与偏好 | Demo 会话已实现 | 演示不被登录阻塞；偏好可保存；真实 Auth 仅在 RealMode 使用 |
| F36 | 无障碍 | 基础实现 | 主流程支持读屏语义、48dp、200% 字体、高对比和非纯颜色状态表达 |
| 精选故事 | 静态展示 | 已实现 | 只读 3 条精选内容；不开放发帖、点赞、群聊或地区社群 |

### 4.1 量化验收指标

| 功能 | 当前 MVP 指标 |
|---|---|
| F1 | 首次可见响应 `<= 3s`；9 类意图样例准确率 `>= 85%`；紧急词误识率 `<= 2%`；AI 无法处理时 `100%` 有转人工落点；连续 3 轮上下文不丢失；简体 UI 下可演示繁体 OCR 输入 |
| F9 | 50 人本地池 Top 5 计算 `<= 500ms`；取消/超时可落地；10 个志愿者并发接单时只有 1 个成功；连续拒接/超时有降权证据 |
| F11 | Demo 建链状态 `<= 5s`；掉线 10 秒未恢复回到 `matching`；无真实 WebRTC 时完整 Demo Call 可用 |
| F13 | 必须有 10 秒误触撤销；广播与联系人通知均标注为模拟；系统级入口只展示设计，不冒充真实后台能力 |
| F33 | 演示员会话可跳过登录；登录/引导设计 `<= 90s`、3 步可跳过；真实手机号验证码不作为当前现场依赖 |
| F36 | 对比度 `>= 7:1`；触摸目标 `>= 48x48dp`；200% 字体不破版；关键状态由颜色 + 图标 + 文字共同表达；读屏焦点手测通过 |

### 4.2 当前证据与缺口

| 指标 | 当前证据 | 判定 |
|---|---|---|
| F1 9 类意图、连续 3 轮上下文 | `demo_data_fallback_test.dart` 有自动化覆盖 | 已证明 |
| F1 首次可见响应 | Demo 安全回复与 SOS 测试门槛为 2 秒 | 部分证明；仍需 Chrome 首屏计时 |
| F1 紧急词召回 / 误识 | 100 条固定正反评测集 | 已证明当前固定集达到召回 `>=95%`、误识 `<=2%` |
| F9 50 人池 `<= 500ms` | `demo_matching_service_test.dart` | 已证明 |
| F9 竞争接单唯一成功 | 10 路 Future 竞争测试 | 已证明 Demo 状态合同只有 1 个成功 |
| F9 连续拒接/超时降权 | 连续 3 次后跨轮扣分测试 | 已证明 |
| F11 掉线回匹配 | 默认 10 秒常量 + 加速 Timer 状态测试 | 已证明 |
| F13 10 秒撤销与 Mock 标识 | 现有 SOS facade / 页面 / 闭环测试 | 已证明核心路径；需 RC 手测 |
| F36 200% 字体与 Semantics | 多个 Widget 测试；390×844 Chrome smoke | 部分证明；对比度与读屏焦点仍需人工清单 |

## 5. 交付轨道

### 5.1 轨道 A：竞赛 Demo（必须完成）

- 默认 DemoMode。
- 首页 → AI → 匹配 → 通话 → 评价 → 历史闭环。
- 首页 / AI 紧急词 → SOS Mock 闭环。
- 首页 / AI / 匹配 / 通话 / SOS / 我的在 200% 字体下可用。
- 完整 Web Release 构建和 Chrome 手动演示。
- 简体中文文案与提交材料一致。

### 5.2 轨道 B：最小 RealMode（不阻塞轨道 A）

- Supabase Auth。
- `profiles`、`help_requests`、`volunteer_profiles` 最小 CRUD。
- 生产 schema 有可重放的迁移记录。
- 客户端只使用 publishable key；服务端 secret 不进入仓库或产物。
- 所有真实能力默认关闭且失败时回落 Demo。

### 5.3 轨道 C：未来能力（本轮不执行）

- 真实匹配、推送、WebRTC、短信与真实 SOS。
- 交互式社区。
- 积分、徽章、排班、后台、录音分析。

## 6. 分阶段任务

### Phase 0：事实来源与交付护栏

#### T0.1 建立并冻结整体项目总纲

- 验收：
  - 本文件包含目标、范围、架构、任务、风险、验收、三轮审查和执行日志。
  - README、DEMO_STATUS、TODO 能链接到本文件。
- 验证：
  - `rg -n "PROJECT_MASTER_PLAN" README.md DEMO_STATUS.md TODO.md`
- 依赖：无。
- 预计范围：S。

#### T0.2 同步实时状态文档

- 验收：
  - 删除“当前只有 3 个导航”等过期实时陈述。
  - 最新测试数量、Web 构建和 Supabase 状态有日期。
  - 历史记录继续保留为历史，不冒充当前结果。
- 验证：
  - 人工对照本文件 §2。
- 依赖：T0.1。
- 预计范围：M。

#### T0.3 固化 CI 交付门禁

- 验收：
  - PR 执行 `flutter analyze`、`flutter test`、Web Release 构建。
  - CI 不生成或打包包含密钥的 `.env`。
  - GitHub Pages 只发布 DemoMode。
  - CI 固定到已验证的 Flutter `3.44.4`，避免 `stable` 漂移。
- 验证：
  - 审查 `.github/workflows/*.yml`。
- 依赖：T0.1。
- 预计范围：S。

### Phase 1：Demo 主线真实性与无障碍

#### T1.1 冻结默认导航和范围

- 验收：
  - 求助者与志愿者都只有：首页/待帮助、AI、只读社群、我的。
  - 不存在积分、后台、交互式社区、真实通话入口。
- 验证：
  - `flutter test test/widget_test.dart`
  - `flutter test test/closed_loop/seeker_center_scope_test.dart`
- 依赖：Phase 0。
- 预计范围：S。

#### T1.2 完整 3 分钟自动闭环

- 验收：
  - 启动、AI 直接解决、AI 转人工、匹配、通话、评价、历史、SOS 均有测试。
  - 所有流程有 loading / success / empty / error / retry 或可执行降级。
  - F1 的 9 类意图、紧急词误识、连续 3 轮和 3 秒响应有可重复评测。
  - F9 在 50 人池中 `<= 500ms`，并发接单只有 1 个成功。
  - F11 掉线 10 秒未恢复后回到 `matching`。
- 验证：
  - `flutter test test/closed_loop`
- 依赖：T1.1。
- 预计范围：M。

#### T1.3 F36 自动化覆盖

- 验收：
  - 首页、登录、AI、快捷工具、匹配、通话、SOS、我的覆盖 200% 字体。
  - 关键操作具有可理解 Semantics。
  - 系统字体缩放不会被应用偏好降低。
- 验证：
  - `flutter test`
  - TalkBack / VoiceOver 手动清单。
- 依赖：T1.1。
- 预计范围：M。

#### T1.4 真实设备与 Chrome 演示验收

- 验收：
  - Chrome 冷启动后 20 秒内看懂产品。
  - 完整 3 分钟脚本无死路、无溢出、无断图。
  - 断网、无 Key 时仍可演示。
- 验证：
  - `flutter run -d chrome`
  - `flutter build web --release`
- 依赖：T1.2、T1.3。
- 预计范围：S。

### Phase 2：代码与依赖收敛

#### T2.1 分析范围收敛

- 验收：
  - 所有默认可达 Dart 文件参与 `flutter analyze`。
  - exclude 只覆盖明确 legacy / experimental 文件。
- 验证：
  - `flutter analyze`
- 依赖：Phase 1。
- 预计范围：M。

#### T2.2 依赖分层

- 验收：
  - 主应用未使用依赖被移除。
  - WebRTC、Firebase、录音、后台图表等非 MVP 依赖有保留理由或被隔离。
- 验证：
  - `flutter pub deps --style=compact`
  - `flutter build web --release`
- 依赖：T2.1。
- 预计范围：M。

#### T2.3 状态与服务边界

- 验收：
  - 新代码不再增加 singleton 或 ChangeNotifier 业务状态。
  - 主流程使用 provider-backed controller / facade。
  - 旧服务按实际可达性逐步迁移，不进行赛前大爆炸重构。
- 验证：
  - `rg -n "extends ChangeNotifier|static final .*Service _instance" linklab/lib`
  - 全量测试。
- 依赖：T2.1。
- 预计范围：按服务拆成多个 S/M 子任务。

### Phase 3：Supabase 唯一事实来源

#### T3.1 隔离历史全量 schema

- 验收：
  - 活跃 migration 不再混合历史 `users` 全量 schema、最小 `profiles` schema 和非 MVP 积分 schema。
  - 历史迁移可追溯但不会被默认部署。
  - 活跃 Edge Functions 只依赖活跃 schema。
- 验证：
  - 生成表/函数依赖矩阵。
  - 对照线上 `public` schema。
- 依赖：Phase 0。
- 预计范围：M。

#### T3.2 建立生产基线迁移

- 验收：
  - `profiles`、`help_requests`、`volunteer_profiles` 可从空库重建。
  - RLS、索引、触发器与线上一致。
  - 迁移可在已有空表环境幂等执行。
- 验证：
  - Supabase 开发分支或本地实例执行。
  - `get_advisors` 无新增安全错误。
- 依赖：T3.1。
- 预计范围：M。

#### T3.3 修正新式 API Key 鉴权

- 验收：
  - 用户请求使用 Auth JWT。
  - 服务请求使用 `apikey` + `sb_secret_*` 或明确保留的 legacy JWT 方案。
  - secret 不出现在客户端、日志、Git 或聊天输出中。
- 验证：
  - 未认证请求返回 401。
  - 越权资源请求返回 403。
  - 服务请求仅受控调用成功。
- 依赖：T3.2。
- 预计范围：M。

#### T3.4 最小 RealMode 垂直闭环

- 验收：
  - 登录用户可创建/读取自己的 profile 和 help request。
  - 志愿者只能读允许公开的待帮助记录。
  - RLS 越权测试通过。
  - 失败自动回落 Demo，不污染默认构建。
- 验证：
  - 数据库集成测试。
  - Flutter `real_database_repository_test.dart`。
- 依赖：T3.2、T3.3。
- 预计范围：按 Auth/Profile/Help/Volunteer 拆成 4 个 S/M 子任务。

### Phase 4：交付与发布

#### T4.1 冻结 RC 证据

- 验收：
  - 记录日期、Commit、命令、测试数、构建产物和手动检查人。
  - 文档不再引用过期测试数作为当前证据。
- 验证：
  - 对照 `docs/rc_acceptance_evidence.md`。
- 依赖：Phase 1—3 的当前交付范围。
- 预计范围：S。

#### T4.2 交付包与远端同步

- 验收：
  - 工作区干净。
  - Commit 可追踪。
  - 用户确认后 push。
  - 交付包不含 `.env`、secret、构建缓存和历史大文件。
- 验证：
  - `git status --short`
  - 敏感文件扫描。
  - 校验和清单。
- 依赖：T4.1。
- 预计范围：S。

### 6.1 实际执行批次

为控制回归面，每个批次最多修改 5 个文件；一个批次验证通过后才进入下一个批次：

1. **批次 A｜事实护栏**：总纲、README、DEMO_STATUS、TODO、CI。
2. **批次 B｜部署面盘点**：生成活跃 migration / function / table / RPC 依赖矩阵，不写生产库。
3. **批次 C｜Supabase 本地隔离**：分小批移动历史迁移与不可部署函数；每批同步测试和说明。
4. **批次 D｜Demo KPI 缺口**：先补评测/并发/重连断言，再修最小实现。
5. **批次 E｜F36 与 Chrome RC**：自动测试、读屏手测、3 分钟脚本和 Web Release。
6. **批次 F｜最小 RealMode**：用户确认后在隔离环境验证三表迁移和 RLS；不部署未来能力。
7. **批次 G｜交付**：冻结证据、提交；用户确认后再 push / 发布。

### 6.2 检查点

| 检查点 | 进入条件 | 允许动作 |
|---|---|---|
| A：本地护栏 | 批次 A 通过，补丁无格式问题 | 继续本地代码、测试和文档修改 |
| B：后端变更 | 依赖矩阵完成，空库方案与回滚方案明确，用户确认 | 可在隔离环境或生产执行 DDL |
| C：远端交付 | 全量测试、Web Release、敏感信息扫描、工作区清单完成，用户确认 | 可 commit / push / 发布 |

## 7. 标准命令

```bash
# 安装依赖
cd linklab
flutter pub get

# 静态分析
flutter analyze

# 全量测试
flutter test --reporter compact

# 闭环测试
flutter test test/closed_loop

# Web Release
flutter build web --release

# 补丁与仓库检查
cd ..
git diff --check
git status --short --branch
```

## 8. 测试策略

| 层级 | 目标 | 证据 |
|---|---|---|
| 单元测试 | 状态机、服务排序、配置、安全 helper | `test/**/*_test.dart` |
| Widget 测试 | 导航、动态字体、Semantics、无溢出 | `widget_test.dart`、闭环 screen tests |
| 闭环测试 | 3 分钟主线与 SOS | `test/closed_loop/` |
| 构建测试 | Web 发布可用 | `flutter build web --release` |
| 手动无障碍 | 读屏焦点、真实 200% 字体、冷启动 | RC 手动清单 |
| 后端安全 | RLS、401/403、迁移、Advisor | Supabase 集成记录 |

## 9. 工作边界

### 始终执行

- 修改前对照 `AGENTS.md` 和本文件。
- 每个增量都运行与风险相称的测试。
- 保持 Demo fallback。
- 更新本文件中的任务状态与执行日志。
- 新增文案使用简体中文。

### 必须先确认

- 生产数据库 DDL 或数据写入。
- Edge Function 生产部署。
- Git push、GitHub Pages 生产发布。
- 删除真实用户、表、分支或远端数据。
- 引入付费服务或产生费用的 Supabase 分支。

### 禁止

- 提交 `.env`、service role、`sb_secret_*` 或供应商密钥。
- 将 Mock 描述成真实上线。
- 让 RealMode 阻塞 DemoMode。
- 为已砍功能扩展默认入口。
- 通过排除分析或删除测试掩盖问题。

## 10. 风险与缓解

| 风险 | 等级 | 缓解 |
|---|---|---|
| 本地与线上 Supabase schema 分叉 | 高 | 先冻结最小基线，历史 schema 移出默认部署路径 |
| 历史文档互相冲突 | 高 | 本文件作为唯一实时索引，其他文档只记录专项或历史 |
| experimental 依赖误入主线 | 高 | FeatureFlags 默认关闭，CI 搜索默认入口 |
| 读屏与 200% 字体只靠自动化 | 高 | RC 必须增加 TalkBack / VoiceOver 手动结果 |
| 依赖过多拖慢 Web 构建 | 中 | 按实际 import 逐个移除，不一次性重构 |
| singleton / ChangeNotifier 历史债 | 中 | 只迁移默认可达流程，新代码禁止扩散 |
| Flutter stable 漂移造成 CI 差异 | 中 | 记录验证版本，后续固定 CI Flutter 版本 |
| 生产项目已有 Auth 用户 | 中 | 任何生产写入先确认，只用隔离测试账号/分支 |

## 11. 三轮审查记录

### 第一轮：产品范围与竞赛主线

状态：已完成。

对照：

- `AGENTS.md` §2—§9。
- `共感LinkAble_PRD_v1_2.md` §3—§5、§8、§13。
- 默认入口、底部导航和 Demo flow。

发现并修订：

1. 初稿只描述“功能存在”，未完整写入 AGENTS 的量化指标；已新增 §4.1。
2. 明确 UI / 文档只维护简体中文，但繁体 OCR 作为 F1 输入能力保留，不再维护繁体 UI 分支。
3. 确认底部只读精选故事符合 AGENTS §11；它不是被 PRD 删除的交互式社群。
4. 明确 F33 的真实手机号登录不是现场 Demo 依赖，不能用演示员会话冒充生产登录完成。
5. 将 50 人匹配、唯一接单、掉线回匹配和连续 3 轮上下文加入 Phase 1 验收。

第一轮结论：范围与竞赛叙事一致，可以进入技术现实审查。

### 第二轮：代码、数据与依赖现实

状态：已完成。

对照：

- `linklab/lib/main.dart`、`AppConfig`、主导航与 provider 状态机。
- 审查时的 29 个测试文件与 111 项测试；执行后新增证据，当前为 114 项通过。
- GitHub Pages workflow。
- 根目录 `supabase/`、线上 schema、迁移记录与 Edge Functions。

发现并修订：

1. 将“量化目标”与“已有测试证据”拆开，新增 §4.2，避免把 111 项通过误写成所有 KPI 已达标。
2. 当前匹配测试只证明顺序竞争唯一成功，不等于 10 路并发；当前拒接实现是本轮排除，不是跨轮降权。
3. Demo Call 已有 10 秒默认重连计时与失败回匹配路径，但需要补默认时长断言。
4. CI 使用浮动 `stable`，且生成应用不会读取的 `.env`；T0.3 增加固定 Flutter `3.44.4` 和移除 `.env`。
5. 默认 `main.dart` 向配置层传空环境，Pages 产物是 DemoMode；因此 CI 中的 Supabase 变量不仅无效，还会造成错误的真实后端印象。
6. 线上只有三表最小 schema、0 条迁移和 0 个 Edge Function；本地历史全量迁移与当前函数依赖均不可直接部署，T3.1 必须先于任何后端部署。
7. `RealDatabaseRepository` 与线上三表基本一致，可作为 RealMode 垂直切片起点；积分、通知、真实匹配与推送继续留在 experimental / future。
8. `analysis_options.yaml` 仍排除较多历史目录，单例与 ChangeNotifier 债务存在，但不应赛前整体重构。

第二轮结论：Demo 主线处于可运行状态；后端部署面尚未形成唯一事实来源。执行应先完成文档与 CI 护栏，再隔离 Supabase 历史部署面。

### 第三轮：执行顺序、风险与验收闭环

状态：已完成。

审查方法：

- 按依赖、失败成本、可回滚性和用户确认边界重新排序。
- 将每个执行批次限制在最多 5 个文件。
- 对“本地可执行”“生产需确认”“远端需确认”设置检查点。

发现并修订：

1. 原阶段编号表达产品逻辑，但不够适合真实执行；新增 §6.1，把文档/CI、部署面盘点、本地隔离、KPI、RC、RealMode、交付排成 7 个批次。
2. Supabase 分叉是最高风险，但不需要立刻写生产库；先做依赖矩阵和本地隔离，生产 DDL 留在检查点 B。
3. Demo KPI 采用“测试先行”：先写失败测试，再做最小实现，避免用文档宣布完成。
4. 旧文档存在繁体和过期数字；批次 A 只保留历史证据，所有当前口径改为简体并指向本总纲。
5. 当前本地已领先远端 1 个提交；本轮改动不得与旧提交混在未经说明的 push 中，检查点 C 单独展示提交清单。
6. 生产 Supabase 有 2 个 Auth 用户，因此不使用生产用户做迁移试验，不删除线上对象。

第三轮结论：先执行批次 A；随后执行只读依赖矩阵和本地隔离。生产 DDL、函数部署、push 与 Pages 发布继续等待独立确认。

## 12. 执行进度

| 任务 | 状态 | 证据 / 备注 |
|---|---|---|
| T0.1 建立总纲 | 已完成 | 三轮审查冻结版 |
| T0.2 同步实时状态 | 已完成 | README / DEMO_STATUS / TODO 已指向本总纲 |
| T0.3 固化 CI | 已完成 | Flutter 3.44.4；移除无效 `.env` 生成 |
| Phase 1 Demo 主线 | 进行中 | T1.2 自动化与 Chrome 主闭环完成；F36 人工项待验收 |
| Phase 2 代码收敛 | 进行中 | T2.1 / T2.2 完成；状态与服务债务增量处理 |
| Phase 3 Supabase | 进行中 | T3.1 完成；T3.2 结构基线与线上一致，空库重放和 migration 历史待隔离环境/确认 |
| Phase 4 交付发布 | 进行中 | RC 与交付审计完成；最终提交和远端同步结果以 Git 记录为准 |

## 13. 执行日志

### 2026-07-24

- 建立项目总纲草案。
- 读取 `AGENTS.md`、README、TODO、DEMO_STATUS、交付计划、验收清单与真实代码入口。
- 记录最近 Flutter 验证与线上 Supabase 只读审计结果。
- 完成产品范围、技术现实、执行顺序三轮审查，并将发现回写到总纲。
- 冻结当前执行顺序：批次 A 从实时文档与 CI 护栏开始。
- 完成批次 A：实时文档统一为简体；README、DEMO_STATUS、TODO 统一引用本总纲。
- CI 固定 Flutter `3.44.4`，删除未被应用读取的 Supabase `.env` 生成步骤。
- 批次 A 验证：workflow YAML 可解析，`git diff --check` 通过。
- 完成批次 B 只读审计：建立 migration / function / table / RPC 依赖矩阵和本地隔离、回滚方案。
- 确认 4 个 Edge Functions 均不能在当前线上三表 schema 中直接部署。
- 完成批次 C：历史全量迁移和 4 个不可部署函数移入 `supabase/legacy/`，活跃部署面只保留最小三表 migration。
- 将 Supabase 配置与短信模板统一为简体，并移除活跃函数声明。
- 更新后端安全测试，验证最小活跃基线、空函数部署面和 legacy 可追溯性；3 项测试通过。
- 完成批次 D：新增 100 条紧急词固定评测、10 路接单竞争、连续 3 次拒接降权和默认 10 秒重连测试。
- 修复紧急词否定/引用语境误报，加入跨轮拒接计数与 penalty score，导出统一重连阈值。
- 全量验证：`flutter analyze` 无问题；114 项测试通过；Web Release 构建成功。
- 完成 Chrome RC：AI 转人工 → 匹配 → 通话 → 评价回首页，以及紧急词 → SOS → 撤销均无死路。
- 390×844 窄屏 smoke 通过，浏览器控制台 0 个 error；读屏与逐项对比度仍保留为人工检查点。
- 完成 Phase 2 依赖审计：移除 8 个零引用直接依赖/生成器，依赖解析减少 19 个包。
- 记录 WebRTC、Firebase、录音、定位与历史后台依赖的 legacy / experimental 保留理由。
- 依赖变更后再次通过 analyze、114 项测试和 Web Release；WASM dry-run 工具异常不影响 JavaScript 产物。
- 完成 Supabase 三表基线只读深度核对：字段、约束、索引、触发器和 12 条 RLS 策略与候选 migration 一致。
- 再次确认线上 migration 历史为 0；Security Advisor 只有泄露密码保护未开启，Performance Advisor 为 4 个空表未使用索引和 1 组重叠 SELECT 策略。
- 当前机器没有 Supabase CLI 和 Docker，不能做空库重放；未以此为由改写生产库，T3.2 保留为“结构已验证、执行未登记”。
- 完成最终交付审计：历史 Supabase 文件逐个验证为“归档说明头 + 原内容”，没有内容丢失；workflow YAML 可解析，`git diff --check` 通过。
- 敏感信息扫描未发现真实 key、JWT 或私钥；历史部署文档中命中的私钥头只是带 `\n...` 的占位示例。
- 最终全量复验再次通过：`flutter analyze` 无问题、114 项测试全部通过、Web Release 成功。
- Android Release 构建成功：包名 `com.gonggan.linklab`，版本 `1.0.1 (2)`，92.0 MB；APK v2 签名与旧简体安装包一致，可直接覆盖安装。
- 当前磁盘 1.9 GB 主要来自本轮可再生成的 Web 构建缓存；源码/文档/配置本体约 9.8 MB。
