# LinkLab Demo Status

> 文档口径整理日期：2026-05-01

## 当前定位

LinkLab 当前应被标注为 **Demo-first MVP**，不是生产级全功能平台。竞赛和对外演示只承诺一条可重复讲述、可点击闭环的本地 Demo 主线：

1. F1 AI Agent 先处理标准化求助。
2. F9 复杂需求转志愿者匹配。
3. F11 进入 Demo Call 状态机。
4. F13 展示 Mock SOS 的误触撤销、广播和联系人通知状态。
5. F33 使用演示会话和基础偏好。
6. F36 保持无障碍优先。

默认演示不应依赖真实 API key、真实 Supabase 初始化、真实 WebRTC 建链、真实推送、真实短信或真实报警链路。

## 推荐演示路径

**主要演示路径是 Flutter Web / Chrome。** 现场演示、录屏和快速验收优先使用 Chrome，因为它最接近当前 Demo-first 的交付目标，也能减少 Windows 桌面原生工具链带来的变量。

建议命令口径：

```powershell
cd linklab
flutter pub get
flutter run -d chrome
```

需要产物时使用 Web 构建口径：

```powershell
cd linklab
flutter build web --release
```

本轮文档整理没有运行任何 Flutter 命令；上述命令是推荐复验路径，不是本轮执行结果。

## Windows 桌面说明

Windows 桌面不是当前首选演示路径。若要运行或构建 Windows 桌面端，需要本机已安装 Visual Studio 的 C++ 桌面开发工具链，至少包括：

- Visual Studio 2022 或兼容版本；
- `Desktop development with C++` 工作负载；
- MSVC C++ build tools；
- Windows 10/11 SDK；
- CMake / Ninja 等 Flutter Windows 构建依赖。

缺少该工具链时，Windows desktop build 失败不应被解读为 Demo 主线不可演示；应优先切回 Web / Chrome。

## 历史验证口径

仓内已有文档对验证结果的记录不完全同一时间点，容易被误读。统一口径如下：

| 记录来源 | 记录内容 | 当前解释 |
|---|---|---|
| `README.md` / `TODO.md` 的 2026-04-17 记录 | 曾记录 `flutter test --tags demo` 通过，同时记录过 `flutter analyze lib` 仍有噪音 | 这是早期收口记录，不等同于当前复验结果 |
| `docs/rc_acceptance_evidence.md` | 曾记录 RC 加固后 `flutter analyze` 为 `No issues found`，`flutter test --reporter compact` 为 `All tests passed` / 60 tests | 可作为较新的历史 RC 证据，但本轮未复跑 |
| `docs/competition_mvp_delivery_plan.md` / `docs/plans/2026-04-12-prd-alignment-main-frontend.md` | 将 `flutter build web --debug` / `flutter build web --release` 作为 Web 演示验收或构建命令 | Web build 是推荐验收口径；最终交付前应重新执行并记录时间、命令和结果 |

因此，对外表述建议使用：

> 项目历史上已有 Flutter test / Web build 验收口径和 RC 证据；当前文档整理未复跑 Flutter。交付或路演前应以 Web / Chrome 路径重新执行 `flutter test` 和 `flutter build web`，并把最新结果补到 RC 证据文档。

## 真实链路状态

以下能力不得表述为当前生产可用：

- **真实 WebRTC**：保留实验实现和接入文档；竞赛默认走 Demo Call，不建立真实媒体链路。
- **真实 Supabase**：根目录 `supabase/` 是 schema source of truth，但竞赛 Demo 默认不依赖真实 Supabase 初始化或线上数据。
- **真实推送**：推送函数和客户端服务属于实验/后续基础设施；现场演示只展示本地 Mock 状态。
- **真实 SOS**：当前只承诺 Mock SOS 的 10 秒误触撤销、广播状态和联系人通知状态；真实短信、真实定位、系统级触发、110/120 或后台唤醒未作为生产完成项。
- **真实 AI / OCR / ASR / Vision API**：可作为本地实验配置，不能成为 Demo 必需条件。

## 推荐引用顺序

接手或验收项目时，建议先读：

1. `DEMO_STATUS.md`
2. `README.md`
3. `docs/rc_acceptance_evidence.md`
4. `docs/demo_script_3min.md`
5. `docs/competition_mvp_delivery_plan.md`
6. `TODO.md`

