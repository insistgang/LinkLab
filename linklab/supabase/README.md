# Legacy Notice

`linklab/supabase/legacy/` 僅用於保留歷史分叉文件，不再參與任何 schema、RLS 或 Edge Function 的事實來源判定。

依據 `AGENTS.md §4.4`：

- 根目錄 `supabase/` 是唯一 schema source of truth
- 所有後續 migration、RLS、functions 只允許在根 `supabase/` 維護
- `linklab/supabase/legacy/` 不得再次被部署、執行或作爲客戶端字段設計依據
