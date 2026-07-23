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
