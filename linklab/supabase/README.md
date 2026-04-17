# Legacy Notice

`linklab/supabase/legacy/` 仅用于保留历史分叉文件，不再参与任何 schema、RLS 或 Edge Function 的事实来源判定。

依据 `AGENTS.md §4.4`：

- 根目录 `supabase/` 是唯一 schema source of truth
- 所有后续 migration、RLS、functions 只允许在根 `supabase/` 维护
- `linklab/supabase/legacy/` 不得再次被部署、执行或作为客户端字段设计依据
