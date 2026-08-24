# LinkLab 文档总集（PROJECT_DOCS）

> 本文件是 docs/ 下全部 Markdown 文档的唯一合并版，生成于 2026-08-24。
> 原独立文档已全部删除；如需引用请指向本文件的对应章节。

## 目录

1. 【活跃】PROJECT_MASTER_PLAN.md
2. 【活跃】demo_acceptance_checklist.md
3. 【活跃】rc_acceptance_evidence.md
4. 【索引】REPOSITORY_CONTENT_INDEX.md
5. 【审计】DEPENDENCY_AUDIT.md
6. 【审计】SUPABASE_BASELINE_VALIDATION.md
7. 【审计】SUPABASE_DEPLOYMENT_SURFACE.md
8. 【历史归档】competition_mvp_delivery_plan.md
9. 【历史归档】non_mvp_contamination_audit.md
10. 【历史归档】project_report.md
11. 【历史归档】2026-04-12-prd-alignment-main-frontend.md

---

# 第 1 部分 【活跃】PROJECT_MASTER_PLAN.md

> 来源：`docs/PROJECT_MASTER_PLAN.md`（原文档已并入本文集并删除）

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

---

# 第 2 部分 【活跃】demo_acceptance_checklist.md

> 来源：`docs/demo_acceptance_checklist.md`（原文档已并入本文集并删除）

# 共感 LinkAble 競賽 Demo 驗收檢查清單

> 使用範圍：2026 創客大賽 Demo-first MVP
> 關鍵聲明：**競賽 Demo 不依賴外部服務**。所有檢查都應在無真實 Supabase、無真實 WebRTC、無真實推送、無真實 OCR key 的情況下成立。

## 啓動檢查

- [ ] `linklab/lib/main.dart` 啓動時鎖定 demo mode，並啓用演示員預置會話。
- [ ] App 通過 `ProviderScope(child: LinkLabApp())` 啓動。
- [ ] `LinkLabApp` 能根據 session 狀態進入默認主界面；競賽演示不被登錄/註冊卡住。
- [ ] 默認底部導航只有 `首頁 / AI助手 / 我的`。
- [ ] 首頁第一屏顯示“我需要幫助”大按鈕，且按鈕可點擊進入 AI 或匹配主流程。
- [ ] 不需要真實 Supabase 初始化、不需要 Firebase 初始化、不需要真實 API key 才能打開 App。

建議命令：

```powershell
git status --short
cd linklab
flutter pub get
flutter test test/closed_loop/startup_login_closed_loop_test.dart
```

## 無網絡 / 無 API key 檢查

- [ ] 斷網或不配置真實 API key 時，App 仍能啓動到首頁。
- [ ] OCR、場景描述、匹配、通話、SOS 都走本地 demo fallback。
- [ ] 頁面沒有要求輸入 Supabase URL、Firebase token、WebRTC server、OCR key。
- [ ] 控制檯沒有因爲缺少外部服務而導致主流程崩潰。
- [ ] 評審現場可明確說明：競賽 Demo 不依賴外部服務，真實集成是後續版本。

建議檢查：

```powershell
cd linklab
rg -n "Supabase.initialize|Firebase.initializeApp|RealCallService\(|WebRTCService\(|PushNotificationService\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
```

驗收口徑：默認啓動、首頁和 demo flow 不應命中真實外部服務初始化或真實通話依賴。

## AI demo fallback 檢查

- [ ] 從首頁大按鈕或 `AI助手` 進入單一 AI Agent 入口。
- [ ] 輸入或選擇“幫我讀藥品盒”，返回本地 OCR demo 響應。
- [ ] OCR 響應包含藥名、規格、用法用量、有效期等可講述信息。
- [ ] 輸入或選擇“我面前是什麼”，返回本地場景描述 demo 響應。
- [ ] AI 響應有處理中、成功、失敗或可轉人工等明確狀態。
- [ ] AI 無法處理或複雜需求時，可以 `100%` 轉到志願者匹配。
- [ ] 緊急詞能進入 SOS 路徑，不能只停留在普通聊天回覆。

對應代碼：

- `linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`
- `linklab/lib/services/demo/demo_ai_service.dart`
- `linklab/assets/demo_data/ai_responses.json`
- `linklab/assets/demo_data/help_scenarios.json`

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/ai_to_human_closed_loop_test.dart
flutter test test/closed_loop/demo_mainline_end_to_end_test.dart
```

## 匹配 demo 檢查

- [ ] 點擊轉人工或複雜需求後進入 `DemoMatchingScreen`，不是進入真實 `MatchingScreen`。
- [ ] 匹配頁顯示處理中狀態、候選志願者信息和成功狀態。
- [ ] demo 志願者數據來自 `assets/demo_data/volunteers.json`。
- [ ] 用戶可以取消匹配，取消後有可見反饋。
- [ ] 匹配成功後進入 demo 通話，不依賴真實推送、真實地理位置或真實 Supabase。

對應代碼：

- `linklab/lib/demo_flow/demo_matching_flow.dart`
- `linklab/lib/screens/call/demo_matching_screen.dart`
- `linklab/lib/services/demo_call_service.dart` 中 `DemoMatchingService`
- `linklab/assets/demo_data/volunteers.json`

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/matching_call_rating_closed_loop_test.dart
rg -n "MatchingScreen\(|RealCallScreen|RealCallPage|WebRTCService\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
```

## 通話 demo 檢查

- [ ] 匹配成功後進入 `DemoCallScreen`，不是進入真實 WebRTC 通話頁。
- [ ] 通話頁顯示連接中、已連接、志願者信息、掛斷按鈕。
- [ ] 掛斷後進入評價頁或結果回看落點。
- [ ] 評價提交後可返回首頁或幫助檔案落點。
- [ ] 口播明確：這是 demo 通話狀態機，真實 WebRTC 是後續真實集成，不作爲競賽 Demo 外部依賴。

對應代碼：

- `linklab/lib/screens/call/demo_call_screen.dart`
- `linklab/lib/screens/call/demo_call_rating_screen.dart`
- `linklab/lib/services/demo_call_service.dart` 中 `DemoCallService`

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/matching_call_rating_closed_loop_test.dart
```

## SOS mock 檢查

- [ ] 首頁 SOS 或 AI 緊急詞能進入 `DemoSOSScreen`。
- [ ] 頁面顯示 10 秒誤觸撤銷窗口。
- [ ] 頁面顯示 Mock 廣播演示，不依賴真實推送。
- [ ] 頁面顯示緊急聯繫人通知狀態；聯繫人爲空時有明確說明和降級文案。
- [ ] 用戶能撤銷誤觸；撤銷後狀態明確，不靜默失敗。
- [ ] SOS 路徑不走普通 F9 匹配公式，而是廣播型緊急流程。

對應代碼：

- `linklab/lib/screens/call/demo_sos_screen.dart`
- `linklab/lib/services/demo_call_service.dart` 中 `DemoSOSService`
- `linklab/lib/demo_flow/demo_sos_flow.dart`
- `linklab/lib/services/security/emergency_contact_service.dart`

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/sos_closed_loop_test.dart
```

## 無障礙檢查

- [ ] 默認主鏈路所有交互控件有可理解的 `Semantics` label/hint。
- [ ] 主要按鈕和可點區域接近或達到 `48x48dp`。
- [ ] 文字和背景對比度達到 `>= 7:1` 的競賽口徑。
- [ ] 系統字體縮放到 `200%` 時，首頁、AI、匹配、通話、SOS、我的頁不破版。
- [ ] 錯誤、警告、成功狀態不能只靠顏色表達，需要文字和圖標共同表達。
- [ ] 焦點順序符合視覺與操作順序。
- [ ] 不存在強制倒計時選擇；唯一允許例外是 SOS 10 秒誤觸撤銷窗口。
- [ ] 圖片、故事卡片和圖標型按鈕有可理解替代文本或語義說明。

建議命令：

```powershell
cd linklab
flutter test test/closed_loop/theme_toggle_live_update_test.dart
```

人工驗收：使用系統讀屏和 `200%` 字體縮放完整跑一遍 3 分鐘腳本。

## Flutter analyze / test 驗收

- [ ] `flutter analyze` 通過。
- [ ] `flutter test` 通過。
- [ ] 閉環測試至少覆蓋啓動/登錄、AI 轉人工、匹配通話評價、SOS、Seeker Center MVP 範圍。
- [ ] 不把被 `analysis_options.yaml` 排除的默認可達頁面誤認爲已完全驗收；P0 後應恢復默認主鏈路 analyze 覆蓋。

建議命令：

```powershell
cd linklab
flutter analyze
flutter test
flutter test test/closed_loop
```

## 非 MVP 污染檢查

- [ ] 默認社羣僅展示精選故事，沒有發帖、羣聊或地區社羣；積分、徽章、排班、後臺不進入主線。
- [ ] 首頁和 demo flow 不進入真實 WebRTC、真實推送、真實 Supabase 頁面。
- [ ] `SeekerCenterScreen` 默認只展示“幫助檔案 / 求助狀態”；積分、異步任務、收藏志願者不進入競賽主線。
- [ ] 根 `supabase/` 中非 MVP 表和 functions 已被標註 legacy、歸檔或從競賽部署路徑移除。
- [ ] `admin_dashboard/`、`linklab/lib/admin/` 不參與競賽 App 默認構建驗收。

建議命令：

```powershell
cd linklab
rg -n "AdminLoginScreen|AdminLayout|InterestGroupsScreen|GroupChatScreen|NewbieVillageScreen|PointsTab|AsyncRequestsTab|FavoriteVolunteersTab|RealCallScreen|RealCallPage|MatchingScreen\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
rg -n "points-calculator|point_transactions|async_tasks|reports|call_records" ..\supabase
```

## 文檔與變更範圍檢查

- [ ] 本輪只改 `docs/` 下文檔。
- [ ] 未改 `AGENTS.md`。
- [ ] 未改 `lib/`、`test/`、`supabase/`。
- [ ] 已運行 `git diff -- docs`；若新建文檔尚未被 Git 跟蹤，結合 `git status --short` 或 `git diff --no-index` 覈對新增內容。

建議命令：

```powershell
git diff -- docs
git status --short
```

---

# 第 3 部分 【活跃】rc_acceptance_evidence.md

> 来源：`docs/rc_acceptance_evidence.md`（原文档已并入本文集并删除）

# 竞赛 Demo RC 验收证据

> 核对日期：2026-07-24
> 基线：以 `3eb6810` 为起点的本轮收口交付
> 总索引：[PROJECT_MASTER_PLAN.md](./PROJECT_MASTER_PLAN.md)

## 1. 口径

本次验收只证明 LinkAble 竞赛 Demo 的本地闭环和 Web 交付能力，不代表真实 WebRTC、Supabase、推送、短信、定位、AI 供应商或报警链路已生产上线。

默认演示不依赖外部服务。所有广播、联系人通知、通话和 SOS 均明确标注为本地 Demo / Mock。

## 2. 自动化证据

| 检查 | 结果 |
|---|---|
| Flutter | 3.44.4 stable |
| Dart | 3.12.2 |
| `flutter analyze` | No issues found |
| `flutter test --reporter compact` | 114 项全部通过 |
| `flutter build web --release` | 成功，生成 `build/web` |
| `flutter build apk --release` | 成功，生成 `app-release.apk`（`1.0.1 (2)`，92.0 MB） |
| 后端部署面安全测试 | 3 项通过 |
| 补丁格式 | `git diff --check` 通过 |
| workflow | YAML 可解析 |
| 敏感信息扫描 | 未发现真实 key、JWT 或私钥 |

Web Release 的 WASM dry-run 曾报告 `flutter_tts` 兼容提示，并在依赖收敛后的增量构建中出现工具内部 `org-dartlang-untranslatable-uri` 非阻断异常；JavaScript Web 构建均成功，不阻塞当前 Pages 交付。

Android APK 包名为 `com.gonggan.linklab`，通过 APK Signature Scheme v2 校验。当前使用与旧简体 APK 相同的 Android Debug 证书，适合自装、覆盖升级和现场演示，不作为应用商店正式签名包。

## 3. 功能证据

| 功能 | 自动化证据 | Chrome 实际验收 | 结论 |
|---|---|---|---|
| 启动与 F33 | presenter session、登录和偏好 Widget 测试 | 角色选择后进入求助者首页，没有真实登录卡点 | 通过 |
| F1 9 类意图 | `demo_data_fallback_test.dart` | AI 页面本地可用，输入真人请求出现明确二次确认 | 通过 |
| F1 紧急词 | 100 条固定集；召回率 `>=95%`、误识率 `<=2%` | “救命，我摔倒了”直接进入 SOS | 通过固定集 |
| F1 三轮上下文 | 药品说明三轮对话测试 | 未单独人工计时 | 自动化通过 |
| F1 转人工 | need-human / 状态机测试 | 确认弹窗 → “连接志愿者” → matching | 通过 |
| F9 Top 5 | 50 人池 `<500ms` | 页面展示 Top 5、距离、技能、信誉与 Mock 标签 | 通过 |
| F9 并发 | 10 路接单竞争只有 1 个成功 | 页面最终只有 1 位已接单志愿者 | 通过 Demo 合同 |
| F9 拒接降权 | 连续 3 次拒接/超时后下一轮分数降低 | 页面可见超时并尝试下一位 | 通过 |
| F11 Demo Call | connecting / connected / reconnecting / ended | 匹配后自动进入通话；可静音、免提、结束与评价 | 通过 |
| F11 掉线 | 默认阈值 10 秒；超时回 matching | 页面明确显示“掉线 10 秒未恢复会回到 matching” | 通过状态合同 |
| F13 SOS | 10 秒撤销、Mock 广播、联系人状态测试 | 紧急词进入撤销窗口；点击“撤销误触”返回 SOS 首页 | 通过 |
| 评价与结果回看 | rating / history 闭环测试 | 选择星级、提交后回首页，提示已写入本地 Demo 回看 | 通过 |
| 静态精选故事 | 默认导航范围测试 | 底部“社群”为只读精选入口 | 通过范围合同 |

## 4. Web 与响应式验收

本地使用 Release 产物在浏览器中完成以下路径：

```text
角色选择
  → 求助者首页
  → AI 输入“我需要真人志愿者帮助”
  → 二次确认
  → Top 5 匹配
  → 单一志愿者接单
  → Demo 通话
  → 结束与评价
  → 返回首页
```

SOS 路径：

```text
AI 输入“救命，我摔倒了”
  → SOS 10 秒误触撤销窗口
  → 撤销误触
  → 返回 SOS 首页
```

实际观察：

- 1280×720 页面无明显溢出或断图。
- 390×844 窄屏首页可滚动，主卡片和四项底栏可用。
- 所有 SVG 与本地 Demo JSON 请求成功。
- 浏览器控制台 0 个 error。
- 字体资源在窄屏硬刷新后约 1.5 秒内完成加载；加载完成后中文显示正常。

## 5. 无障碍证据

已自动化：

- 登录、首页、AI、快捷工具、匹配、通话、SOS 与个人页的 200% 字体 smoke。
- 关键按钮与状态的 Semantics 断言。
- 关键触摸目标和可滚动布局。
- 状态不只依赖颜色，配有图标和文字。

仍需人工：

- TalkBack / VoiceOver 完整 3 分钟焦点顺序。
- 真实设备系统字体 200%。
- 关键文字与背景的逐项 7:1 对比度测量。
- Android / iOS 真实设备冷启动。

因此 F36 当前是“自动化通过、人工读屏待验收”，不能写成全部完成。

## 6. Supabase 证据

- 线上只有 `profiles`、`help_requests`、`volunteer_profiles` 三张空业务表，均启用 RLS。
- 线上 migration 记录为 0，Edge Function 为 0。
- 本地活跃 migration 只保留最小三表候选基线。
- 历史全量 schema 与 4 个不可部署函数位于 `supabase/legacy/`。
- 本次没有执行生产 DDL、数据写入或函数部署。
- 候选 migration 的字段、约束、索引、触发器和 12 条 RLS 策略已通过线上只读查询逐项核对。
- 当前机器没有 Supabase CLI 和 Docker，因此空库重放与 migration 历史登记仍待隔离环境/用户确认。

详细依赖见 [SUPABASE_DEPLOYMENT_SURFACE.md](./SUPABASE_DEPLOYMENT_SURFACE.md)，基线核对见 [SUPABASE_BASELINE_VALIDATION.md](./SUPABASE_BASELINE_VALIDATION.md)。

## 7. 当前结论

Demo 主线已达到本地交付 RC：114 项测试通过、静态分析通过、Web 与 Android Release 构建成功、Chrome 主闭环和 SOS 撤销无死路。

进入正式发布前还需要：

1. TalkBack / VoiceOver 和真实设备检查。
2. 逐项对比度记录。

依赖与分析范围证据见 [DEPENDENCY_AUDIT.md](./DEPENDENCY_AUDIT.md)。

---

# 第 4 部分 【索引】REPOSITORY_CONTENT_INDEX.md

> 来源：`docs/REPOSITORY_CONTENT_INDEX.md`（原文档已并入本文集并删除）

# LinkLab 仓库内容总索引

## 当前主版本

LinkLab 当前主版本位于仓库根目录，Flutter 应用位于 `linklab/`。产品定位是
Demo-first MVP，默认服务 F1、F9、F11、F13、F33、F36 六项核心能力，并以
Web / Chrome 作为主要演示路径。

主要目录：

| 路径 | 内容 | 当前用途 |
| --- | --- | --- |
| `linklab/` | Flutter 主应用、测试、资源和平台工程 | 当前可运行版本 |
| `docs/` | 交付、验收、企划及说明文档 | 当前文档 |
| `supabase/` | 当前后端 schema 与说明 | 唯一有效后端事实来源 |
| `LinkAble/` | 企划书及历史产品资料 | 产品资料 |
| `prd-analysis/` | PRD 与分析材料 | 产品范围依据 |
| `icos/`、`pic/` | 图标与图片资源 | 设计和演示素材 |
| `archive/` | 已合并但不参与运行的历史快照 | 内容保全 |

## 2026-07-11 stash 合并

历史 stash `backup before canonical integration 2026-07-11` 已采用“保留当前版本 +
归档旧有效载荷”的方式并入主分支：

- stash 完整提交关系已接入 Git 历史；
- 558 个已跟踪改动文件保存在
  [`archive/stash-2026-07-11/tracked-changes/`](../archive/stash-2026-07-11/tracked-changes/)；
- 98 个当时未跟踪文件保存在
  [`archive/stash-2026-07-11/untracked-snapshot/`](../archive/stash-2026-07-11/untracked-snapshot/)；
- 69 个删除操作保留在 stash 提交历史中；
- 当前应用代码没有被旧版本覆盖。

详细来源、内容分类和恢复命令见
[`archive/stash-2026-07-11/README.md`](../archive/stash-2026-07-11/README.md)。

## 分支口径

- `main` 是唯一交付主分支。
- 原远端 `agent/simplified-quick-tools` 的全部提交已经包含在 `main`，没有独有内容。
- 历史内容完成远端验证后，可安全删除本地 stash 和已合并远端分支；其内容仍可从
  `main` 的归档目录和 Git 历史恢复。

## 当前与历史的边界

归档目录中的文件用于保全和追溯，不代表生产能力已经启用。真实 Supabase、WebRTC、
推送和生产级 SOS 仍需按当前 README、AGENTS.md 与验收文档执行；不能因为历史文件已
归档，就把旧配置或实验实现视为当前默认路径。

---

# 第 5 部分 【审计】DEPENDENCY_AUDIT.md

> 来源：`docs/DEPENDENCY_AUDIT.md`（原文档已并入本文集并删除）

# Flutter 依赖与分析范围审计

> 核对日期：2026-07-24
> 工程：`linklab/`

## 1. 本轮结果

全仓 Dart import 扫描确认以下 8 个直接依赖或生成器没有任何源码引用，已从 `pubspec.yaml` 移除：

- `riverpod_annotation`
- `json_annotation`
- `sensors_plus`
- `screen_brightness`
- `intl`
- `equatable`
- `collection`
- `riverpod_generator`

`flutter pub get` 共减少 19 个依赖包。`collection`、`equatable`、`json_annotation` 仍可能作为其他包的传递依赖存在，但不再由 LinkAble 直接声明。

## 2. 验证

依赖变更后重新执行：

| 检查 | 结果 |
|---|---|
| `flutter pub get` | 成功 |
| `flutter analyze` | No issues found |
| `flutter test --reporter compact` | 114 项全部通过 |
| `flutter build web --release` | 成功 |

Web 构建的 WASM dry-run 出现工具内部 `org-dartlang-untranslatable-uri` 非阻断异常；Flutter 继续完成 JavaScript Release 构建并生成 `build/web`。

## 3. 保留的非默认主线依赖

以下依赖不属于 Demo 主线，但仍被仓库中的 legacy / experimental 源码 import，本轮不强行删除：

| 能力 | 依赖示例 | 保留原因 |
|---|---|---|
| 真实通话 | `flutter_webrtc`、`web_socket_channel` | experimental 通话源码仍可追溯 |
| 真实推送 | `firebase_core`、`firebase_messaging`、`flutter_local_notifications` | experimental 推送服务仍在 |
| 录音与媒体 | `flutter_sound`、`audioplayers`、`camera` | 历史通话/安全模块仍引用 |
| 真实定位 | `geolocator` | experimental 匹配/SOS 仍引用 |
| 历史后台 | `fl_chart`、`data_table_2` | `lib/admin/` 历史源码仍引用 |
| 真实后端 | `supabase_flutter` | 最小 RealMode repository 需要 |

这些依赖不会因为保留在 `pubspec.yaml` 就自动进入默认导航；Flutter Release 只打包入口可达代码。后续若把对应源码整体移出主包，再单独删除依赖。

## 4. 分析范围

当前 `flutter analyze` 覆盖默认可达主线，并显式排除：

- `lib/services/experimental/**`
- 历史 admin / archive / user-center / security 页面与服务
- 旧 WebRTC、真实通话和旧状态流
- 生成文件

`flutter build web --release` 进一步证明默认入口的完整 import graph 可编译。排除项仍是技术债，不等于代码质量已验收。

## 5. 后续原则

- 新代码不得加入未实际使用的直接依赖。
- 新的默认主线代码不得放进 analyze exclude。
- legacy / experimental 只有整体归档后，才移除其专用依赖。
- 不为减小数字而一次性删除仍可追溯的实验源码。

---

# 第 6 部分 【审计】SUPABASE_BASELINE_VALIDATION.md

> 来源：`docs/SUPABASE_BASELINE_VALIDATION.md`（原文档已并入本文集并删除）

# Supabase 最小基线验证记录

> 验证日期：2026-07-24
> 项目：`LinkAble-Prod`（`eeqeoteiowasoubxsuos`）
> 结论：候选 migration 与线上三表结构一致；尚未建立 migration 历史，未执行任何线上写入。

## 1. 验证范围

本次只验证当前 MVP 的唯一活跃 migration：

```text
supabase/migrations/202605240001_realmode_phase3_minimal_crud.sql
```

核对对象：

- `profiles`
- `help_requests`
- `volunteer_profiles`
- 主键、外键、唯一约束和检查约束
- 索引
- `set_updated_at()` 触发器
- RLS 开关和 12 条策略
- Data API 角色授权
- Supabase migration 历史
- Security / Performance Advisor

未验证或未执行：

- 不部署 `supabase/legacy/` 中的迁移或函数。
- 不创建、更新或删除线上数据。
- 不创建付费 Supabase 分支。
- 不执行 `db pull`、`migration repair`、`db push` 或生产 DDL。

## 2. 只读核对结果

| 对象 | 线上结果 | 与候选 migration |
|---|---|---|
| 三张业务表 | 存在，均为 0 行 | 一致 |
| Auth 关系 | `profiles.id -> auth.users.id` | 一致 |
| 业务外键 | `help_requests.seeker_id`、`volunteer_profiles.user_id` 指向 `profiles.id` | 一致 |
| 字段、默认值、非空约束 | 21 个字段与最小三表定义一致 | 一致 |
| 检查约束 | 角色、求助状态、服务半径 | 一致 |
| 索引 | 4 个业务索引 + 主键/唯一索引 | 一致 |
| 更新时间触发器 | 三张表各 1 个 `BEFORE UPDATE` 触发器 | 一致 |
| RLS | 三张表全部启用 | 一致 |
| RLS 策略 | `profiles` 3 条、`help_requests` 5 条、`volunteer_profiles` 4 条 | 一致 |
| API 角色授权 | `anon`、`authenticated`、`service_role` 保留 Supabase 默认表授权 | 依赖 Supabase 默认权限 |
| migration 历史 | 0 条 | 不一致：尚未登记候选基线 |

线上存在 2 个 Auth 用户。业务表为空不代表可以删除或重建 Auth 数据，也不能在生产项目上做 migration 重放实验。

## 3. Advisor 结果

### Security

当前只有 1 条警告：

- 泄露密码保护未开启。它属于 Auth 控制台配置，不是本次三表 migration 的 DDL。

三张表都已启用 RLS，未发现缺少 RLS 的新警告。

### Performance

当前提示：

- 4 个业务索引尚未被使用。
- `help_requests` 对 `authenticated SELECT` 有两条 permissive policy。

三张业务表均为空，不能根据“未使用索引”提示删除为预期查询准备的索引。两条 SELECT policy 分别表达“求助者读取自己的请求”和“可用志愿者读取开放请求”，逻辑正确；后续有真实负载后再决定是否合并为一条策略。

## 4. 本地重放状态

当前机器没有 `supabase` CLI，也没有 Docker，因此无法执行：

```bash
supabase start
supabase db reset --local
supabase db push --dry-run
```

这不是线上写入的理由。空库重放仍是 T3.2 的待验收项，应在具备 Supabase CLI + Docker 的本地环境，或经确认创建的 Supabase 开发分支中完成。

## 5. 生产基线登记方案

官方建议已有远端项目先通过 `db pull` 建立基线，并谨慎维护 migration 历史。由于当前线上结构已与候选 migration 一致，生产阶段不应盲目再次执行整份 DDL。

推荐顺序：

1. 在本地或开发分支从空库重放候选 migration。
2. 再次核对表、约束、索引、触发器和策略。
3. 备份线上 schema，并确认 2 个 Auth 用户不受影响。
4. 选择“以远端 pull 结果作为基线”或“将候选 migration 标记为已应用”的单一方案。
5. 先执行 dry-run，展示将改变的 migration 历史。
6. 获得用户对生产 migration 历史变更的独立确认。
7. 执行后再次运行 Security / Performance Advisor。

禁止：

- 在生产项目执行 `db reset`。
- 为了制造干净历史而删除线上表、Auth 用户或项目。
- 将 `supabase/legacy/` 恢复为默认部署面。
- 在没有备份、dry-run 和独立确认时执行 `migration repair` 或 `db push`。

## 6. 当前判定

| T3.2 验收项 | 判定 |
|---|---|
| 候选 schema 范围唯一 | 通过 |
| 与线上列、约束、索引、触发器、RLS 一致 | 通过 |
| 线上 Advisor 无新增安全错误 | 通过（只读核对） |
| 从空库重放 | 待具备 CLI + Docker 或开发分支 |
| 已有环境幂等验证 | 待隔离环境 |
| 生产 migration 历史建立 | 待用户确认 |

因此，T3.2 当前状态是“结构基线已验证，执行基线未登记”。默认 DemoMode 不受此缺口影响；RealMode 生产交付仍不可宣称完成。

---

# 第 7 部分 【审计】SUPABASE_DEPLOYMENT_SURFACE.md

> 来源：`docs/SUPABASE_DEPLOYMENT_SURFACE.md`（原文档已并入本文集并删除）

# Supabase 部署面与依赖矩阵

> 核对日期：2026-07-24
> 状态：本地隔离完成；尚未执行生产 DDL、数据写入或 Edge Function 部署
> 项目：`LinkAble-Prod`（`eeqeoteiowasoubxsuos`）

## 1. 结论

审计时，根目录 `supabase/` 是三套不兼容历史叠加：

1. `001`—`005`：以自建 `public.users` 为身份中心的历史全量 schema。
2. `202605240001`：以 `auth.users -> public.profiles` 为身份中心的最小三表 schema。
3. `202607230001` 与 4 个 Edge Functions：依赖积分、异步任务、通知、AI 缓存、扩展匹配字段和 RPC。

线上结构与第 2 套基本一致。上述隔离现已完成：活跃 migration 只保留最小三表候选基线，其余位于可追溯的 `supabase/legacy/`。这仍不代表已获准执行 `supabase db push`。

## 2. 线上事实

| 项目 | 当前值 |
|---|---|
| 项目状态 | `ACTIVE_HEALTHY` |
| Auth 用户 | 2 |
| 业务表 | `profiles`、`help_requests`、`volunteer_profiles` |
| 表数据 | 三表均 0 行 |
| RLS | 三表均开启 |
| 迁移历史 | 0 |
| Edge Functions | 0 |
| 已知安全提示 | 泄露密码保护未开启 |

线上存在真实 Auth 用户，所以不能用“业务表为空”推导生产项目可随意重建。

## 3. Migration 矩阵

| 文件 | 身份模型 | 主要对象 | 与线上兼容性 | 处置 |
|---|---|---|---|---|
| `001_create_tables.sql` | `public.users` | 9 张业务表 | 不兼容 | legacy |
| `002_create_indexes.sql` | `public.users` | 全量表索引 | 依赖 001 | legacy |
| `003_create_rls_policies.sql` | `public.users` | 全量 RLS / role helper | 依赖 001 | legacy |
| `004_functions_and_triggers.sql` | `public.users` | 匹配、积分、缓存、审计函数 | 依赖 001 | legacy |
| `005_unify_root_schema_source_of_truth.sql` | `public.users` | 扩展字段、通知、设备、AI 日志 | 依赖 001—004 | legacy |
| `202605240001_realmode_phase3_minimal_crud.sql` | `auth.users -> profiles` | 三表、RLS、索引、更新时间触发器 | 与线上基本一致 | 候选活跃基线 |
| `202607230001_harden_edge_functions.sql` | 历史全量 | 积分幂等 RPC、通知 | 依赖线上不存在对象 | legacy |

### 3.1 关键冲突

- 两套身份表分别是 `public.users` 和 `public.profiles`，不能按文件名顺序叠加。
- 两套 `help_requests` / `volunteer_profiles` 字段集合不同。
- 历史迁移使用 `async_tasks`、`point_transactions`、`emergency_contacts`、`ai_response_cache` 等非 MVP 表。
- 线上没有 migration 记录，即使结构相似，也不能把本地基线直接视为已应用。

## 4. Edge Function 依赖矩阵

| 函数 | 数据库依赖 | 外部依赖 | 当前阻塞点 | 处置 |
|---|---|---|---|---|
| `matching-engine` | `help_requests` 扩展字段、`volunteer_profiles` 扩展字段、`async_tasks`、`find_matching_volunteers` | Auth JWT | 最小三表缺少字段、表、RPC | legacy / future |
| `push-notifier` | `help_requests.type`、`user_devices`、`push_logs`、扩展志愿者字段 | FCM、Auth JWT | 最小 schema 无设备与日志表 | legacy / future |
| `points-calculator` | `help_requests`、`async_tasks`、`award_volunteer_points_once` | service role | 积分属于非 MVP，线上对象不存在 | legacy |
| `ai-dispatcher` | `ai_response_cache`、`increment_cache_hit`、`ai_call_logs` | 百度、通义、讯飞等密钥 | 缓存与日志对象不存在；真实 AI 非 Demo 依赖 | legacy / future |

结论：当前没有任何一个根目录 Edge Function 可以在三表线上结构中独立部署。

## 5. 鉴权边界

- 客户端用户操作应携带 Supabase Auth access token，并在数据库层继续受 RLS 约束。
- `sb_secret_*` 是 API key，不是用户 JWT；不能作为 `Authorization: Bearer` 交给平台 JWT 校验。
- 服务专用或混合路由需要单独设计 `apikey` 校验与授权模型，不能仅把 `verify_jwt` 开关当作完整安全策略。
- 客户端、日志、Git 和文档不得出现 service role、`sb_secret_*` 或供应商密钥。

## 6. 本地隔离结果

目标结构：

```text
supabase/
├─ config.toml
├─ migrations/
│  └─ 202605240001_realmode_phase3_minimal_crud.sql
└─ legacy/
   ├─ README.md
   ├─ migrations/
   │  ├─ 001_create_tables.sql
   │  ├─ 002_create_indexes.sql
   │  ├─ 003_create_rls_policies.sql
   │  ├─ 004_functions_and_triggers.sql
   │  ├─ 005_unify_root_schema_source_of_truth.sql
   │  └─ 202607230001_harden_edge_functions.sql
   └─ functions/
      ├─ ai-dispatcher/
      ├─ matching-engine/
      ├─ points-calculator/
      └─ push-notifier/
```

活跃 `config.toml` 已移除 4 个函数声明，原繁体配置注释/短信模板已改为简体。隔离只改变本地默认部署面，没有删除历史内容。

## 7. 验收与回滚

本地隔离验收：

```bash
rg --files supabase/migrations
rg --files supabase/functions
rg -n "001_create_tables|points-calculator|matching-engine" supabase/legacy
git diff --check
```

通过条件：

- 活跃 migration 只有最小三表基线。
- 活跃 functions 目录不存在可误部署函数。
- legacy 内容完整可追溯。
- Flutter Demo 测试不受影响。

回滚方式：在提交前反向移动文件；提交后使用正常 revert 提交。禁止通过删除生产表回滚本地隔离。

## 8. 生产检查点

本地隔离已通过专用测试，但不代表可以写生产库。生产变更前仍需：

1. 明确空库重放结果。
2. 比较线上列、约束、索引、策略、触发器与候选迁移。
3. 形成只补 migration 历史、不破坏 2 个 Auth 用户的方案。
4. 准备备份与回滚步骤。
5. 获得用户对生产 DDL 的独立确认。

更细的线上只读比对、Advisor 结果和生产基线登记顺序见
[`SUPABASE_BASELINE_VALIDATION.md`](SUPABASE_BASELINE_VALIDATION.md)。

---

# 第 8 部分 【历史归档】competition_mvp_delivery_plan.md

> 来源：`docs/competition_mvp_delivery_plan.md`（原文档已并入本文集并删除）

# 共感 LinkAble 競賽 Demo MVP 交付計劃

> 狀態日期：2026-04-28
> 最高事實來源：根目錄 `AGENTS.md`
> 交付硬約束：**競賽 Demo 不依賴外部服務**。默認首頁、默認路由、默認構建和默認測試只服務 F1/F9/F11/F13/F33/F36 六項 MVP。
> 2026-05-01 文檔口徑補充：當前對外標註爲 Demo-first MVP，Web / Chrome 是首選演示路徑；本輪文檔整理未運行 Flutter，歷史驗證記錄需要在交付前復跑確認。

## 項目定位

共感 LinkAble 是一個“AI Agent 第一響應 + 人類志願者兜底”的無障礙互助 App。競賽 Demo 的目標不是展示完整平臺能力，而是在 3 分鐘內穩定跑通：用戶發起求助、AI 先處理、複雜或高風險問題轉人工、進入志願者匹配、完成 demo 通話、必要時觸發 SOS，並且全流程對讀屏、動態字體和低認知負擔友好。

當前工程驗收口徑是 Demo-first MVP：只交付可點擊、可講述、可閉環的本地演示主線。真實 Supabase、真實 WebRTC、真實推送、後臺和社羣等能力可以作爲後續方向存在，但不得阻塞競賽 Demo。

## 當前主鏈路判斷

- `linklab/lib/main.dart` 已在啓動時鎖定 demo mode，啓用演示員預置會話，初始化 `DemoDataLoader`，並通過 `ProviderScope(child: LinkLabApp())` 啓動。
- `linklab/lib/app.dart` 中 `LinkLabApp` 已是 `ConsumerWidget`，默認通過 session 狀態進入 `MainScreen`、登錄或首次引導。
- `linklab/lib/screens/home/main_screen.dart` 默認底部導航已收縮爲 `首頁 / AI助手 / 我的`。
- `linklab/pubspec.yaml` 已聲明 `assets/demo_data/`，`DemoDataLoader` 當前讀取 `volunteers.json`、`ai_responses.json`、`help_scenarios.json`。
- 當前審計結論：Flutter 默認演示主鏈路基本符合 Demo-first，但仍需要繼續隔離 `SeekerCenterScreen` 內的積分/異步/收藏殘留、根 `supabase/` 的非 MVP 表和 `points-calculator`、真實 WebRTC/推送/admin/community 的非默認入口。

## 當前唯一 MVP 範圍

| ID | 功能 | Demo MVP 驗收口徑 | 當前代碼入口 |
|---|---|---|---|
| `F1` | AI Agent 智能對話 | 單一入口承接 OCR、場景描述、顏色識別、鈔票識別、翻譯、環境描述、導航、藥品確認、緊急詞檢測；首次響應 `<= 3s`；連續 3 輪上下文正確；AI 無法處理時 `100%` 可轉人工；無網絡/無 API key 時走本地 demo fallback | `linklab/lib/screens/home/ai_chat_screen.dart`；`linklab/lib/screens/ai_chat/demo_ai_chat_screen.dart`；`linklab/lib/services/demo/demo_ai_service.dart`；`linklab/assets/demo_data/ai_responses.json`；`linklab/assets/demo_data/help_scenarios.json` |
| `F9` | 志願者匹配引擎 | AI 無法處理或用戶主動轉人工時進入匹配；基於 demo 志願者池展示 Top 5/默認志願者；匹配頁有處理中、成功、取消等可見狀態；競賽 Demo 不依賴真實地理位置、推送或 Supabase | `linklab/lib/demo_flow/demo_matching_flow.dart`；`linklab/lib/screens/call/demo_matching_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoMatchingService`；`linklab/assets/demo_data/volunteers.json` |
| `F11` | 實時語音通話 | 匹配成功後進入 demo 通話；必須展示連接中、已連接、掛斷、評價、結果沉澱；視頻、屏幕共享、真實 WebRTC 建鏈不進入競賽主線 | `linklab/lib/screens/call/demo_call_screen.dart`；`linklab/lib/screens/call/demo_call_rating_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoCallService` |
| `F13` | SOS 緊急呼救 | 一鍵或緊急意圖觸發；必須顯示廣播、聯繫人通知、誤觸撤銷窗口；Demo 允許 mock，但狀態變化必須可見；唯一允許的倒計時是 10 秒誤觸撤銷窗口 | `linklab/lib/screens/call/demo_sos_screen.dart`；`linklab/lib/services/demo_call_service.dart` 中 `DemoSOSService`；`linklab/lib/demo_flow/demo_sos_flow.dart`；`linklab/lib/services/security/emergency_contact_service.dart` 的本地 fallback |
| `F33` | 登錄與無障礙偏好 | 手機號驗證碼登錄 + 首次引導 + 簡化身份/偏好設置；競賽默認使用預置演示員會話，避免 3 分鐘腳本卡在註冊；登錄和偏好流程仍需可獨立跑通 | `linklab/lib/main.dart`；`linklab/lib/services/app_session_service.dart`；`linklab/lib/providers/app_session_provider.dart`；`linklab/lib/screens/auth/onboarding_screen.dart`；`phone_login_screen.dart`；`verification_screen.dart`；`identity_select_screen.dart`；`disability_select_screen.dart`；`preference_screen.dart` |
| `F36` | 全局無障礙適配 | 所有默認可達頁面必須有清晰 `Semantics`、接近或達到 `48x48dp` 觸摸目標、`>= 7:1` 對比度、支持 `200%` 字體縮放、錯誤狀態不只靠顏色表達；讀屏用戶能獨立完成主流程 | `linklab/lib/app.dart` 中 `TextScaler` 適配；`linklab/lib/widgets/accessible/`；默認主鏈路頁面中的 `Semantics` 與無障礙按鈕文案；閉環測試 `linklab/test/closed_loop/` |

## 明確排除範圍

以下內容不屬於競賽 Demo MVP，不得進入默認導航、默認首頁、默認路由、默認測試驗收或 P0/P1 資源：

- 交互式社羣、羣聊、地區社區、新手村、訓練場景；競賽版最多保留硬編碼精選故事展示。
- 積分、徽章、善意時間線、排班、多級認證、積分流水和排行榜。
- `admin_dashboard/` 與 `linklab/lib/admin/` 後臺；運營後臺由 Supabase Dashboard 替代，不作爲競賽 App 能力展示。
- 真實 WebRTC、真實信令、視頻、屏幕共享、通話錄音、AI 通話檢測。
- 真實推送、FCM、App 未啓動時的真實後臺喚醒；Demo 只展示本地 mock 狀態。
- 真實 Supabase 強依賴、真實 API key、真實 OCR key、真實部署腳本；競賽 Demo 必須在無網絡/無 key 時完成。
- 異步留言、任務隊列、`async_tasks`、`point_transactions`、`reports`、`call_records`、`points-calculator` 等非 MVP 後端能力。

## 已符合 AGENTS.md 的點

- 全局入口已有 `ProviderScope`，`LinkLabApp` 可讀取 Riverpod session provider。
- `AppConfig` 已鎖定競賽 demo mode，並啓用演示員預置會話。
- 默認導航已收斂爲 `首頁 / AI助手 / 我的`，未把後臺、社羣、積分、真實通話放入底部導航。
- 演示數據已落在 `assets/demo_data/`，並由 `DemoDataLoader` 加載。
- `linklab/supabase/` 已標記 legacy，根目錄 `supabase/` 是事實來源。
- `docs/rc_acceptance_evidence.md` 曾記錄 `flutter analyze` 和 `flutter test` 通過，但注意部分默認可達文件仍被 `analysis_options.yaml` 排除，不能把歷史通過結果誤讀爲當前全主鏈路完全無風險。
- Web / Chrome 是首選演示路徑；Windows 桌面運行或構建需要 Visual Studio C++ 桌面開發工具鏈，不作爲默認驗收入口。

## P0/P1/P2 修復順序

### P0：阻斷演示污染源

1. 恢復或重構默認可達文件的 analyze 覆蓋：`SeekerCenterScreen`、`demo_flow`、安全/聯繫人入口等默認主鏈路文件不應長期被排除。
2. 拆分 `SeekerCenterScreen`：默認只保留“幫助檔案 / 求助狀態”；將 `AsyncRequestsTab`、`PointsTab`、`FavoriteVolunteersTab` 以及對 `AsyncTaskService`、`PointsService`、`VolunteerDetailScreen` 的依賴移出主文件或歸檔。
3. 收斂根 `supabase/`：MVP 事實表只保留 `users`、`volunteer_profiles`、`help_requests`、`emergency_contacts`、`virtual_identities`；`async_tasks`、`point_transactions`、`reports`、`call_records`、`points-calculator` 移入 legacy 或明確非競賽路徑。
4. 複覈主鏈路沒有真實 Supabase、真實 Firebase、真實 WebRTC、真實推送初始化要求；無 key、斷網仍能打開 App 並完成 3 分鐘腳本。

### P1：凍結 Demo / Real 邊界

1. 將 `real_*` 頁面、`MatchingScreen`、`RealCallScreen`、`RealCallPage`、真實 WebRTC service、推送 service、admin route 明確標記爲 experimental，確認默認入口無法觸達。
2. 精選故事保持靜態展示；若進入詳情頁，移除或隱藏 like/unlike 等交互式社羣行爲。
3. 對 `flutter_webrtc`、Firebase、admin dashboard 相關依賴做隔離評估，避免默認平臺構建被非 MVP 依賴拖垮。
4. 將 SOS mock 的 10 秒撤銷窗口、廣播展示、聯繫人通知展示與 AGENTS.md 口徑對齊；真實 `<= 3s` 推送指標只作爲後續真實集成驗收，不冒充 Demo 已完成。

### P2：交付前收斂質量

1. 歸檔重複實現，例如未被默認主鏈路使用的 `demo_flow/demo_ai_service.dart`。
2. 逐步把 UI 直接 new service、service singleton 和裸 `setState` 流程狀態遷移到 provider-backed controller。
3. 統一 `AppLogger`，減少 `print` / `debugPrint`，並補齊失敗態的可見降級路徑。
4. 複查 F36：動態字體 `200%`、讀屏順序、觸摸目標、顏色+圖標+文字三重錯誤表達。

## 分階段驗收命令

### P0 驗收

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

驗收口徑：Flutter 命令通過；後兩個 `rg` 只能命中 legacy/archive 或無輸出，不能命中競賽默認主鏈路。

### P1 驗收

```powershell
cd linklab
flutter analyze
flutter test test/closed_loop
flutter build web --debug
rg -n "AdminLoginScreen|AdminLayout|RealCallScreen|RealCallPage|MatchingScreen\(|InterestGroupsScreen|GroupChatScreen|NewbieVillageScreen" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
rg -n "Supabase.initialize|Firebase.initializeApp|RealCallService\(|WebRTCService\(|PushNotificationService\(" lib/main.dart lib/app.dart lib/screens/home lib/demo_flow
```

驗收口徑：構建和測試通過；默認主鏈路搜索不出現真實後端、真實通話、後臺或交互式社羣入口。

### P2 驗收

```powershell
cd linklab
flutter analyze
flutter test
flutter build web --release
flutter pub deps --style=compact
rg -n "print\(|debugPrint\(" lib
rg -n "factory .*Service\(\)|static final .*Service _instance|ChangeNotifier" lib/screens lib/services
```

驗收口徑：默認構建和全量測試通過；日誌、service singleton 和 `ChangeNotifier` 殘留都有明確遷移或隔離說明。

---

# 第 9 部分 【历史归档】non_mvp_contamination_audit.md

> 来源：`docs/non_mvp_contamination_audit.md`（原文档已并入本文集并删除）

# 非 MVP 防污染審計

> 口徑聲明：**競賽 Demo 不依賴外部服務**。本審計只判斷非 MVP 模塊是否污染默認 3 分鐘 Demo 主線，不等同於刪除歷史代碼，也不聲明真實後端、真實 WebRTC、真實推送或真實後臺已完成。

## 審計結論

當前 Flutter 默認入口、默認底部導航和主演示鏈路未發現可直接進入 admin、community、points、badges、schedule、recording、真實 WebRTC 或真實 Supabase-only flow 的入口。主要風險集中在歷史代碼仍保留、`analysis_options.yaml` 對 legacy 模塊做了排除、根 `supabase/` 仍包含 points/push/recordings/schedule 等非 MVP 結構。

## 模塊清單

| 模塊名稱 | 當前路徑 | 當前狀態 | 是否可從默認首頁進入 | 是否影響 flutter analyze | 是否影響 flutter test | 建議後續處理 |
|---|---|---|---|---|---|---|
| 獨立運營後臺 | `linklab/admin_dashboard/` | legacy / hidden | 否 | 否；當前不參與主 App analyze | 否；不在主 App 測試鏈路 | 保留爲歷史工程或單獨歸檔；不得接回競賽 App 默認入口 |
| 主應用內後臺殘留 | `linklab/lib/admin/` | legacy / hidden | 否 | 否；`analysis_options.yaml` 已排除 | 否 | 後續若做真實後臺，統一到獨立後臺或 Supabase Dashboard，不在求助端保留入口 |
| 交互式社羣 / 羣聊 / 地區社區 | `linklab/lib/screens/community/**`；`linklab/lib/services/community/**` | legacy / hidden | 否 | 否；已排除 | 否 | 競賽版最多保留靜態精選故事；羣聊、地區社區、新手村繼續隱藏 |
| 首頁舊社羣頁面 | `linklab/lib/screens/home/community_screen.dart` | legacy / hidden | 否 | 否；已排除 | 否 | 不接回底部導航；如需競賽敘事，改用靜態未來藍圖 |
| 積分 / 等級 / 公益時長 | `linklab/lib/services/user_center/points_service.dart`；`linklab/lib/screens/user_center/*points*` | legacy / hidden | 否 | 否；相關 user_center legacy 已排除 | 否 | 不進入默認“我的”；後續作爲 V1.0 獨立評估 |
| 徽章 | `linklab/lib/services/user_center/badge_service.dart`；`linklab/lib/screens/user_center/*badge*` | legacy / hidden | 否 | 否；相關 user_center legacy 已排除 | 否 | 不進入默認個人中心；僅可作爲未來藍圖口播 |
| 排班 | `linklab/lib/services/user_center/schedule_service.dart`；`linklab/lib/models/schedule_model.dart` | legacy / hidden | 否 | 否；service 已排除 | 否 | F9 Demo 使用本地志願者在線狀態，不接真實排班 |
| 舊 user_center 模塊 | `linklab/lib/screens/user_center/**`；`linklab/lib/services/user_center/**` | legacy / partial hidden | 默認首頁不進入；當前只使用獨立 Demo 幫助記錄頁 | 否；多數 legacy 路徑已排除 | 否 | 保留幫助回看所需 demo 頁面；其餘積分、收藏、排班、徽章繼續隔離 |
| 通話錄音 / AI 錄音檢測 | `linklab/lib/services/security/call_recording_service.dart`；`linklab/lib/services/webrtc/call_recording_service.dart` | legacy / hidden | 否 | 否；已排除 | 否 | V2.0 之前不得進入 F11 Demo Call；不得請求錄音權限 |
| 真實 WebRTC 服務 | `linklab/lib/services/webrtc/**`；`linklab/lib/services/webrtc_service.dart`；`linklab/lib/services/experimental/real/webrtc/real_webrtc_service.dart` | experimental / hidden | 否 | 默認主分析不依賴；部分 legacy 已排除 | 否；Demo Call 測試斷言 feature flag 關閉 | 繼續放在 experimental/real adapter 後方；默認不得初始化或請求麥克風 |
| 真實通話頁面 | `linklab/lib/screens/call/real_call_screen.dart`；舊 `lib/pages/call/**` | experimental / hidden | 否 | 否；已排除 | 否 | 不接回 F11 默認路徑；F11 RC 只驗收 Demo Call 狀態機 |
| 真實匹配服務 | `linklab/lib/services/real_matching_service.dart` | experimental / hidden | 否 | 否；已排除 | 否 | F9 RC 使用 `DemoMatchingEngineService`；真實服務待 schema 收口後再評估 |
| 生產推送通知 | `linklab/lib/services/push_notification_service.dart`；`supabase/functions/push-notifier/` | experimental / backend residual | 否 | Flutter 主線不依賴 | Flutter 主線不依賴 | 保留爲後續基礎設施；競賽 Demo 不得要求 FCM token 或真實推送 |
| 生產緊急通知 / 真實短信 | `linklab/lib/services/sos_service.dart`；安全相關 legacy service | experimental / hidden | 否 | 否；相關路徑已排除 | 否 | F13 RC 只做 Mock；不得默認發短信、定位、報警 |
| volunteer advanced certification | 志願者高級認證相關舊頁面 / service | hidden / V1.0 | 否 | 當前不影響 | 當前不影響 | F33 RC 只保留預置演示員會話與基礎偏好，不做專業認證 |
| `linklab/supabase` 分叉 | `linklab/supabase/legacy/**` | legacy | 否 | 否 | 否 | 根 `supabase/` 是唯一事實來源；該分叉繼續停止執行或歸檔 |
| 根 Supabase points function | `supabase/functions/points-calculator/`；`supabase/config.toml` | active backend residual / non-MVP | 否 | 不影響 Flutter analyze | 不影響 Flutter test | 交付前標記 legacy 或移出競賽部署清單；不得作爲 F15 展示 |
| 根 Supabase push function | `supabase/functions/push-notifier/`；`supabase/config.toml` | active backend residual / infrastructure | 否 | 不影響 Flutter analyze | 不影響 Flutter test | 僅可作爲後續 F34 基礎設施；競賽 Demo 不依賴真實推送 |
| 根 Supabase 非 MVP 表 | `supabase/migrations/*.sql` 中 `point_transactions`、`call_records`、`available_schedule`、`push_logs` 等 | active backend residual / contamination risk | 否 | 不影響 Flutter analyze | 不影響 Flutter test | MVP schema 後續收口到 `users`、`volunteer_profiles`、`help_requests`、`emergency_contacts`、`virtual_identities` |
| 默認底部導航 | `linklab/lib/screens/home/main_screen.dart` | active / demo-only | 是；僅：首頁 / AI助手 / 我的 | 是；已通過主線 analyze | 是；`widget_test.dart` 覆蓋 | 繼續禁止加入社羣、積分、徽章、排班、後臺等非 MVP tab |
| 配置 feature flags | `linklab/lib/config/app_config.dart` | active / demo-only guard | 間接影響默認入口 | 是 | 是；`widget_test.dart` 新增關閉斷言 | 保持 `isCompetitionDemoOnly = true`；真實模式不得在競賽構建打開 |

## 後續處理優先級

1. **P0 賽前保持**：默認導航、首頁卡片、AI、匹配、通話、SOS 不接入非 MVP 模塊；feature flags 維持關閉。
2. **P1 後端收口**：根 `supabase/` 中 points、recordings、schedule、push 等非 MVP residual 需要拆分爲 legacy 或後續部署清單。
3. **P2 架構清理**：逐步把 legacy `ChangeNotifier` / singleton service 收斂到 provider-backed facade，但不要在 RC 前做大規模重構。

---

# 第 10 部分 【历史归档】project_report.md

> 来源：`docs/project_report.md`（原文档已并入本文集并删除）

# 共感 LinkAble 项目完整报告

> 扫描日期：2026-05-26
> 扫描范围：`E:\vscode_project\LinkLab` 整个 workspace

---

## 一、项目基本信息

| 属性 | 值 |
|---|---|
| **项目名称** | 共感 LinkAble |
| **项目类型** | Flutter / Dart 移动应用 |
| **版本** | 1.0.1+2 |
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
├─ DEMO_STATUS.md / TODO.md
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

- `api_config.dart` 是已跟踪的无密钥兼容配置，不提供密钥写入入口
- 真实 AI 统一通过服务端代理接入，客户端不保存供应商密钥
- 仓库和 Release 产物中只保留公开配置或服务端点，无真实密钥

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
4. `docs/demo_acceptance_checklist.md` — 演示验收清单
5. `linklab/lib/main.dart` — 应用入口
6. `linklab/lib/config/app_config.dart` — 配置文件
7. `linklab/lib/services/facades/agent_service_facade.dart` — AI 核心 Facade
8. `supabase/migrations/` — 数据库 schema

---

# 第 11 部分 【历史归档】2026-04-12-prd-alignment-main-frontend.md

> 来源：`docs/2026-04-12-prd-alignment-main-frontend.md`（原文档已并入本文集并删除）

# LinkLab Main Frontend PRD Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Align the main LinkLab frontend demo flow with the root PRD by making onboarding, accessibility preferences, profile data, recent help, and featured content behave like a coherent product instead of disconnected static screens.

**Architecture:** Keep the existing Flutter screen structure and demo-first mode, but introduce a lightweight local session layer backed by `SharedPreferences`. Reuse that state in auth/onboarding, home, profile, and fallback service paths so the app works consistently without Supabase.

**Tech Stack:** Flutter, SharedPreferences, existing `freezed` models, existing local storage service, existing home/community/user-center screens.

---

### Task 1: Add a local app session layer for demo mode

**Files:**
- Create: `linklab/lib/services/app_session_service.dart`
- Modify: `linklab/lib/main.dart`
- Modify: `linklab/lib/app.dart`

**Step 1: Initialize a single source of truth for local user session**

Create `AppSessionService` as a singleton `ChangeNotifier` that:
- initializes `LocalStorage`
- loads stored `UserModel` and `AccessibilityPreferences`
- seeds demo help history when storage is empty
- exposes `isLoggedIn`, `isFirstLaunch`, `userProfile`, and `preferences`

**Step 2: Make app bootstrap use the session service**

In `main.dart`, call session initialization before `runApp`.

**Step 3: Make root app react to preferences and login state**

In `app.dart`, use the session service to:
- choose initial screen (`OnboardingScreen`, `LoginScreen`, or `MainScreen`)
- switch between normal/high-contrast theme
- apply stored font scale globally

### Task 2: Persist onboarding and accessibility preferences

**Files:**
- Modify: `linklab/lib/screens/auth/verification_screen.dart`
- Modify: `linklab/lib/screens/auth/identity_select_screen.dart`
- Modify: `linklab/lib/screens/auth/disability_select_screen.dart`
- Modify: `linklab/lib/screens/auth/preference_screen.dart`

**Step 1: Pass onboarding context through the auth flow**

Propagate `phone`, `role`, and `disabilityTypes` through verification → identity → disability → preference.

**Step 2: Save onboarding completion into local session**

When the user finishes `PreferenceScreen`, store:
- phone
- selected role(s)
- disability type(s)
- accessibility preferences
- login state
- first-launch state

**Step 3: Support preference editing after login**

Allow `PreferenceScreen` to open in edit mode from “我的” and update preferences without recreating the profile.

### Task 3: Replace static home/profile placeholders with session-backed data

**Files:**
- Modify: `linklab/lib/screens/home/home_screen.dart`
- Modify: `linklab/lib/screens/home/profile_screen.dart`

**Step 1: Personalize the homepage**

Use stored profile data for greeting and add a compact date/time + demo weather row.

**Step 2: Make recent help dynamic**

Load the latest 3 help records from local storage/service fallback instead of hardcoded cards.

**Step 3: Add featured story content on the home page**

Show a small “每日精選故事” section that reads from the community story service fallback.

**Step 4: Make profile page useful**

Replace static identity text and setting labels with real session data. Wire:
- accessibility settings → `PreferenceScreen(edit mode)`
- help record entry → `SeekerCenterScreen`
- logout → clear local session

### Task 4: Add fallback behavior to services used by the main frontend

**Files:**
- Modify: `linklab/lib/services/user_center/help_archive_service.dart`
- Modify: `linklab/lib/services/community/featured_story_service.dart`

**Step 1: Make help archive work without Supabase**

If Supabase is not initialized, read help history from `LocalStorage`, convert to `HelpRequestModel`, and compute basic statistics locally.

**Step 2: Make featured stories work without Supabase**

If Supabase is not initialized, return a small curated list of demo `FeaturedStory` entries so community/home surfaces are populated.

### Task 5: Verify build and record remaining PRD gaps

**Files:**
- Modify: `linklab/README.md`

**Step 1: Build web demo**

Run:
```powershell
& 'C:\Users\Administrator\tools\flutter\bin\flutter.bat' build web --release --base-href /LinkLab/
```

**Step 2: Update documentation**

Add a short note to `README.md` clarifying:
- what parts of the PRD are implemented in the current demo
- what still remains as future work

**Step 3: Summarize residual PRD gaps**

Keep the final audit explicit about the remaining non-trivial differences:
- real auth backend
- stable realtime matching backend
- production push notifications
- full SOS/voice/video/security infrastructure


