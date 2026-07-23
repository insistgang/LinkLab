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
