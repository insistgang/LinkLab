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
