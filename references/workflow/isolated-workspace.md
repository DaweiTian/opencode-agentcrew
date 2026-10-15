# Isolated Workspace — 隔离工作区

> 本文是三个主代理（`smart-router`、`Zero`、`Erribaba`）及所有会写文件的子代理共享的参考文档。规定**什么时候必须为任务建立隔离工作区、怎么用 OpenCode 原生工具建立、开工基线要求、分支与清理纪律**。核心目的：让并行的写任务互不踩踏，同时保证共享状态（主检出、用户未提交改动、其他会话）不被污染。

## 目录

1. [优先使用 OpenCode 原生工具](#优先使用-opencode-原生工具)
2. [什么时候必须隔离](#什么时候必须隔离)
3. [标准工作流](#标准工作流)
4. [开工基线：先跑测试](#开工基线先跑测试)
5. [分支纪律：不在 main/master 上实现](#分支纪律不在-mainmaster-上实现)
6. [清理纪律（provenance）](#清理纪律provenance)
7. [检查清单](#检查清单)
8. [与其他文档的关系](#与其他文档的关系)

## 优先使用 OpenCode 原生工具

OpenCode 内置 worktree 与会话目录切换能力，**这是本仓库所有隔离操作的首选**，不要用 shell 手写 `git worktree add`，也不要引入外部工具（如自行调用 `gh`、`git clone` 到临时目录）来做同样的事——原生工具与主代理的会话上下文（工作目录、references 加载、权限判定）是联动的，手写路径容易造成会话仍在原目录而代理以为已进隔离区的错乱。

| 工具 | 作用 | 关键出入参 |
|------|------|-----------|
| `opencode.worktree_create` | 为任务创建独立 worktree | 入参 `name`；返回 worktree 的 `directory`（绝对路径） |
| `opencode.session_move` | 把会话工作目录切到该 worktree | 入参 `directory`（可省 `sessionID`，默认移动当前会话） |
| `opencode.worktree_list` | 列出仓库的 worktree | 用于创建前后核对，避免重名/遗留 |
| `opencode.worktree_remove` | 移除 worktree | 入参 `directory`；`force` 仅在已确认丢弃改动时使用 |

```
标准两步：
1. worktree_create({ name: "<task-slug>" })        → 得到 directory
2. session_move({ directory: <上一步返回的路径> })   → 会话工作目录切进隔离区
```

**注意**：只 `worktree_create` 而不 `session_move`，代理仍然在主检出上写文件——隔离不生效。两步都要做，除非你明确打算让另一个后台子会话在 worktree 内工作（那种情况下 `session_move` 由该子会话自己执行）。

## 什么时候必须隔离

### 硬规则：并行写任务必须文件所有权互斥

同一文件（或强耦合的一组文件）在同一时刻**只能有一个写任务的所有者**。派发多个可能触碰同一文件的写任务时，二选一：

```
选项 A（推荐）：worktree 隔离
  ├── 每个写任务一个独立 worktree（各自独立检出 + 各自分支）
  ├── 任务互不可见对方的中间状态
  └── 完成后按 [清理纪律] 逐个合并

选项 B：退化为串行
  ├── 只派发一个写任务，等它完成并验证后再派发下一个
  └── 代价是时间，换来零冲突；文件重叠度高时往往比并行更快
```

**只读任务不受此限**：`explore` / `research` / `reviewer` / `spec-reviewer` / `security-auditor` / `architect` 等不写文件的任务，可以共享同一个检出自由并行。

### 判定决策表

| 场景 | 是否需要隔离 | 做法 |
|------|------------|------|
| 多个只读探索/审查任务并行 | 否 | 直接在主检出并行，`background=true` |
| 单个写任务 | 否（但需分支纪律） | 新建分支实现；用户要求隔离时用 worktree |
| 多个写任务，文件集明显不相交（如分别改 `docs/` 与 `src/api/`） | 可不隔离 | 显式声明各自文件边界后再并行；边界一旦被突破立即转隔离 |
| 多个写任务，可能触碰同一文件 | **是** | worktree 隔离，或串行 |
| 任务需要大规模重构、实验性方案、可能长时间失败 | **是** | worktree 隔离，失败可直接丢弃，不污染主检出 |
| 需要保持主检出干净（用户正在其中编辑、或有未提交改动） | **是** | worktree 隔离，避免与人工改动冲突 |
| 要修改 CI/CD、依赖清单、数据库迁移等难回滚内容 | **是** | worktree 隔离 + 合并前审查 |

### 如何提前判断文件是否重叠

派发前让每个写任务先给出**预计触碰的文件清单**（只读探查即可完成，成本极低）：

```
1. 并行派发只读 explore 任务，产出各任务的 candidate files
2. 求交集：任一文件出现在 ≥2 个任务清单中 → 该组任务必须隔离或串行
3. 隔离/串行决策完成后，才派发真正的写任务（遵守阶段屏障）
```

⛔ 不要把"看起来不太可能重叠"当成"不重叠"。共享的入口文件、索引文件（`index.ts`）、路由表、依赖清单、锁文件、i18n 资源、barrel export，几乎总会被多个任务同时触碰。

## 标准工作流

```
[1] 判定：这批写任务的文件所有权是否互斥？
      ├── 互斥（或只读）→ 直接在主检出/共享检出执行
      └── 可能重叠 → 继续
[2] 选择：worktree 隔离 or 串行化？
      ├── 任务彼此独立、可各自合并 → worktree 隔离
      └── 任务相互依赖、需要顺序 → 串行（并遵守阶段屏障）
[3] 建立隔离区：worktree_create({ name }) → session_move({ directory })
[4] 声明基线：跑基线测试，记录预存失败（见下节）
[5] 实现：在 worktree 内的独立分支上工作（不在 main/master）
[6] 验证：在 worktree 内完成四层校验（见 debug-methodology.md）
[7] 合并：先合并（PR 或本地 merge），再清理
[8] 清理：只清理本会话自己创建的 worktree（见 provenance 节）
```

## 开工基线：先跑测试

**在写任何代码之前**，先跑一次基线（构建 + 测试），确立"改动前的世界是什么样"。

```bash
# 依项目实际命令选择，示例：
npm run build
npm test
npm run lint
```

### 为什么要基线

- 没有基线，任务结束时无法区分"我引入的失败"和"本来就红的测试"。
- 把预存失败归因到自己身上，会导致无谓的修复工作和错误的质量结论；反过来，忽略预存失败则会带着真缺陷交付。

### 发现预存失败时的处理

**不要静默继续，也不要擅自去修。** 标准动作是声明 + 请求许可：

```markdown
## ⚠️ 基线不干净（开工前已存在失败）

**执行的基线命令**：`npm test`
**结果**：142 passed, 3 failed, 1 skipped

**预存失败清单**（均在本次改动之前存在，已用 `git stash` / 基线检出确认）：
1. `tests/user.spec.ts > rejects expired token` —— 断言 401 实得 500
2. `tests/report.spec.ts > renders CJK` —— 快照不匹配
3. `e2e/checkout.spec.ts` —— 需要本地 DB，当前环境未启动

**我的判断**：这些与本次任务无直接关系，但会使"测试全绿"这一验收标准无法达成。

**请求确认**：
- (a) 忽略这些预存失败继续实现，我只保证"不新增失败 + 本任务相关测试通过"；
- (b) 先修这些再开始（会改变任务范围与耗时）；
- (c) 暂停，由你决定分工。

在收到答复前我不开始实现。
```

判定口径：本任务的验收标准从"测试全绿"调整为"**基线失败集合不扩大，且本任务新增/相关测试通过**"。这是 (a) 路线下唯一诚实的目标陈述。

## 分支纪律：不在 main/master 上实现

**未经用户明确同意，不得直接在 `main` / `master` 上实现改动。**

> **询问方式**：按主代理的 Ask Discipline，这类放行请求走结构化提问工具并给出具体选项（如「新建分支实现（推荐）／直接在 main 上实现／先暂停」），**不要**在长回复末尾追加一句自然语言问句——后台与无头运行下那会卡住流程。用户无法应答时，取最小范围方案（新建分支），不擅自直接在 `main` 上实现。

```
默认（需询问一次，之后沿用）：
  git switch -c feat/<task-slug>        # 或 fix/<task-slug>、refactor/<task-slug>
  ... 实现、提交 ...
  然后按项目约定开 PR / 合并

例外（必须用户明确同意才可用）：
  直接在 main/master 上提交
```

- 当前检出已在 `main`/`master` 时，第一件事是创建分支，而不是编辑文件。
- 用户曾明确表达"直接在 main 上做就行"之类的授权，可沿用该授权，但仍需在总结中说明提交落在了哪个分支。
- worktree 本身通常带独立分支；若 `worktree_create` 后仍处于默认分支，同样要先切出任务分支。
- 检查当前状态：

```bash
git rev-parse --abbrev-ref HEAD     # 确认在哪个分支上
git status --short                  # 确认没有携带他人未提交改动进入工作区
```

## 清理纪律（provenance）

worktree 是磁盘上的临时检出，**残留会让下一次 `worktree_list` 充满噪音、`git worktree prune` 负担变重、同名任务复用错误目录**。纪律的核心是：**谁创建，谁负责；不清理别人（或用户）的东西。**

> ⛔ **移除 worktree 属于破坏性操作，永远不在自动授权范围内。** 即使自治模式开启，删除 worktree / 删除分支 / 丢弃改动 / hard reset 都必须先取得用户明确确认——**用户沉默不等于同意**。确认请求走结构化提问工具并给出具体选项，不在长回复末尾追加自然语言问句。

### 规则

1. **只清理本会话自己创建的 worktree。**
   创建时把 `worktree_create` 返回的 `directory` 记录下来，作为本会话的 provenance 清单。清理时只处理清单内路径。
   ```
   本会话 provenance 清单：
     - D:\...\worktrees\<name-a>   （会话内创建，可清理）
     - D:\...\worktrees\<name-b>   （会话内创建，可清理）
   清单外一律不动 —— 即使它看起来"是废弃的"，也可能是另一个会话或用户手工建的。
   ```
2. **走 PR 路径的任务不清理 worktree。**
   如果改动通过 PR 合并（远端分支、需要评审、CI 在跑），**保留 worktree**，直到 PR 真正合并且用户确认无需再本地修改。评审往返期间删掉 worktree，等于把开发环境删了。
3. **先合并，后清理。顺序不可颠倒。**
   ```bash
   # 正确：确认改动已在主分支上，再删
   git -C <main-checkout> merge <task-branch>
   git -C <main-checkout> log --oneline -3        # 确认合并已发生
   # 然后才：worktree_remove({ directory: <worktree> })

   # 错误：先删 worktree → 提交在已删除的检出上，合并无从下手
   ```
4. **清理前确认无未提交改动。** 有改动且尚未合并时，先处理改动（提交/合并/明确丢弃），不要靠 `force` 掩盖。
5. **`force: true` 需要用户确认。** 丢弃修改与未跟踪文件属于破坏性操作；只有在用户明确同意"这些改动可以丢"时才设置。
6. **本地直接合并的任务**（未走 PR）：合并完成并验证后，即可在本会话内清理其 worktree 与任务分支。

### 清理前检查

```bash
# 1. 本会话 provenance 清单内的工作区，是否都已有提交？
git -C <worktree> status --short
git -C <worktree> log --oneline -5

# 2. 改动是否已进入主分支？
git -C <main-checkout> branch --contains <task-branch>

# 3. 只列出 worktree 供核对（不删）
# opencode.worktree_list
```

## 检查清单

### 派发前

- [ ] 已判定任务是只读 / 写；只读无需隔离
- [ ] 写任务已收集预计触碰文件清单，并求过交集
- [ ] 存在文件重叠时：已选择 worktree 隔离或串行化（未选择"直接并行赌不冲突"）
- [ ] 隔离方案已使用 OpenCode 原生工具（`worktree_create` + `session_move`），未手写 `git worktree add`

### 开工前

- [ ] 会话工作目录已切换到 worktree（不是只在 worktree 里"以为"在工作）
- [ ] 已跑基线构建 + 测试，并记录结果
- [ ] 基线不干净时：已声明预存失败并请求继续许可，未静默继续
- [ ] 当前分支不是 `main`/`master`（或已获得用户明确同意）
- [ ] 主检出的未提交改动未被带入本次工作

### 收尾时

- [ ] 改动已在 worktree 内完成四层校验
- [ ] 先合并后清理（顺序正确）
- [ ] 走 PR 的任务：**保留** worktree，未清理
- [ ] 只清理本会话 provenance 清单内的 worktree
- [ ] 清理前已就"删除 worktree"这一破坏性操作取得用户明确确认（沉默不算同意）
- [ ] 清理前确认无未提交/未合并改动；`force` 未擅自使用

## 与其他文档的关系

- 并行派发的阶段屏障、超时与完成检查协议见 [`parallel-task-management.md`](parallel-task-management.md)；其中的"文件所有权互斥"硬规则与本文互为表里（该文件给出规则，本文给出隔离实现）。
- 隔离区内修复缺陷的流程与校验层要求见 [`debug-methodology.md`](debug-methodology.md)。
- 审查反馈的接收与验证纪律见 [`review-feedback-discipline.md`](review-feedback-discipline.md)。
