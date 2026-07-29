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
