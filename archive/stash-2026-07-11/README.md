# LinkLab 2026-07-11 合并归档

本目录保存 `backup before canonical integration 2026-07-11` 的完整有效载荷，
用于在不覆盖当前 `main` 最新代码的前提下，把旧工作区中的资料、代码和二进制文件
统一纳入主分支。

## 来源

- stash 提交：`ea66783b98ab710d9d6e7bacead70f9518c24952`
- stash 基线：`538378500e2b16e4da57f3851eda40b84744714d`
- stash 未跟踪文件父提交：`578688ba67555d0c0c5d6975ac8f53daa7e9e305`
- 保全合并提交：`dbb1122`

`dbb1122` 使用 Git `ours` 合并策略把 stash 的完整提交关系接入当前历史。
因此，当前根目录继续保留最新版本，同时旧快照及其未跟踪文件父提交也会随
`main` 一同推送并长期可恢复。

## 目录内容

### `tracked-changes/`

共 558 个文件。它们是 stash 相对其基线中新增、修改、重命名或类型变化后仍然存在的
文件版本，主要包括：

- Flutter 应用、测试、平台工程和配置的旧版本；
- AI+X 竞赛 Markdown、Word、图片和文档生成工具；
- Demo 脚本、演示指南和计划文档；
- Supabase migration、Edge Function 与相关说明；
- 旧版工作流、图标、图片和企划材料。

stash 还记录了 69 个删除操作。删除本身没有可复制的文件内容，但完整删除状态保留在
stash 提交中，可通过下面的命令查看。

### `untracked-snapshot/`

共 98 个文件，是当时工作区中未跟踪内容的完整快照，主要包括：

- Android Demo APK；
- 4 段演示视频；
- 企划书 PDF、页面 DOCX、分析报告和 SVG 资源；
- Flutter 评测数据集、评测报告、原始结果和评测测试代码；
- 已在当前仓库以简体/繁体新名称存在的图标副本。

## 使用原则

- 当前可运行、可部署的版本仍以仓库根目录为准。
- 本目录属于历史归档，不参与 Flutter 构建、GitHub Pages 部署或 Supabase migration。
- 不要把 `tracked-changes/` 整体复制回根目录；其中包含旧代码和旧配置，会覆盖当前实现。
- 需要恢复某一文件时，应先与当前文件比较，再选择性迁移。
- 根目录 `supabase/` 仍是当前唯一有效的 schema source of truth；本归档中的
  `linklab/supabase/` 仅用于保留历史。

## 核对与恢复

查看 stash 相对基线的完整改动：

```bash
git diff --name-status \
  538378500e2b16e4da57f3851eda40b84744714d \
  ea66783b98ab710d9d6e7bacead70f9518c24952
```

单独检出当时的完整已跟踪工作区：

```bash
git worktree add --detach ../linklab-stash-tracked \
  ea66783b98ab710d9d6e7bacead70f9518c24952
```

单独检出当时未跟踪文件的完整快照：

```bash
git worktree add --detach ../linklab-stash-untracked \
  578688ba67555d0c0c5d6975ac8f53daa7e9e305
```

恢复后可使用 `git worktree remove <目录>` 移除临时工作树。
