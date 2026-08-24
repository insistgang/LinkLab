# Supabase 历史部署面

本目录保存 LinkAble 早期全量 schema 与实验性 Edge Functions，仅用于追溯，不属于当前默认部署面。

## 当前活跃基线

当前候选活跃 migration 只有：

`../migrations/202605240001_realmode_phase3_minimal_crud.sql`

它定义 `profiles`、`help_requests`、`volunteer_profiles` 三张最小 RealMode 表，并与 2026-07-24 的线上结构基本一致。

## 禁止事项

- 不要从本目录执行 `supabase db push`。
- 不要批量部署本目录的 Functions。
- 不要把 `public.users` 历史身份模型与 `auth.users -> profiles` 当前模型叠加。
- 不要因为线上三张业务表为空而删除或重建生产对象；线上仍有 Auth 用户。

依赖矩阵、隔离理由与生产检查点见 [`../../docs/PROJECT_DOCS.md`](../../docs/PROJECT_DOCS.md)（SUPABASE 部署面章节）。
