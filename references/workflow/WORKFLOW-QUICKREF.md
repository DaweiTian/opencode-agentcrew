# 结构化工作流快速参考

> **智能调度**：默认主代理 `smart-router` 按任务的领域/复杂度/成本自动分流到合适的子智能体；8 个 `*-lite` 轻量变体专门处理简单任务（最快最省）。调度策略详见仓库 README 的「智能调度策略」章节。

## 参考文档索引

> 同目录 `references/workflow/` 下的共享参考文档（安装脚本会装入 `~/.config/opencode/references/workflow/`）。协议正文只在参考文档里维护，主代理正文仅保留核心规则摘要。

| 文档 | 一句话职责 | 触发场景 |
|------|-----------|---------|
| [`parallel-task-management.md`](parallel-task-management.md) | 并行派发协议：阶段屏障、同阶段先到先处理、文件所有权互斥、超时与完成检查 | 一次派出多个子智能体；需要判断能否并行、何时进入下一阶段 |
| [`review-feedback-discipline.md`](review-feedback-discipline.md) | 审查反馈接收纪律：先逐条对照代码库验证再实现，禁止谄媚式认同，Critical/Important/Minor 分级与 YAGNI 检查 | 收到 `@reviewer` / `@spec-reviewer` / `@security-auditor` 或用户的修改意见，准备动手改代码之前 |
| [`debug-methodology.md`](debug-methodology.md) | 调试方法论：根因调查未完成不得提出修复、三振出局、数据流反向追踪、flaky 测试定位、修复后四层校验 | 排查 bug / 测试失败 / 间歇性故障；同一问题已修复失败 2 次以上 |
| [`isolated-workspace.md`](isolated-workspace.md) | 隔离工作区：用 OpenCode 原生 `worktree_create` + `session_move` 隔离并行写任务，开工基线、分支与清理纪律 | 并行写任务可能触碰同一文件；主检出需保持干净；涉及难回滚改动（CI/依赖/迁移） |

## 核心代理

| 代理 | 用途 | 触发场景 |
|------|------|---------|
| `@workflow-orchestrator` | 工作流编排 | 复杂多阶段任务 |
| `@spec-reviewer` | 规范合规性审查 | 验证实现是否符合需求 |
| `@plan-writer` | 实现计划编写 | 将需求分解为 TDD 任务 |

## 工作流阶段

```
用户需求
    ↓
[阶段 1: 构思] — @architect, @research（可选）
    ↓
[阶段 2: 计划] — @plan-writer, @project-manager
    ↓
[阶段 3: 执行] — @test-writer → @code-generator → @executor
    ↓
[阶段 4: 审查] — @spec-reviewer (Stage 1) → @reviewer (Stage 2)
    ↓
[阶段 5: 合并] — @validator, @git-assistant
```

## 使用示例

### 简单任务（直接处理）
```
用户: "修复登录按钮的颜色"
smart-router: 直接修改 CSS，无需结构化工作流
```

### 复杂任务（使用结构化工作流）
```
用户: "添加用户认证系统，支持 JWT 和 OAuth"
smart-router: 我将使用结构化工作流来实现这个功能

Phase 1: Brainstorm
@architect: 设计认证架构
@research: 调研 JWT 和 OAuth 最佳实践

Phase 2: Plan
@plan-writer: 创建实现计划
- Task 1: 编写 JWT 中间件测试 (TDD)
- Task 2: 实现 JWT 验证
- Task 3: 编写 OAuth 集成测试 (TDD)
- Task 4: 实现 OAuth 流程
- Task 5: 集成测试
- Task 6: 文档更新

Phase 3: Execute
@code-generator: 按计划实现每个任务
@test-writer: 编写测试
@executor: 运行测试验证

Phase 4: Review
@spec-reviewer: 验证实现符合需求 (Stage 1)
@reviewer: 代码质量审查 (Stage 2)

Phase 5: Merge
@validator: 最终验证
@git-assistant: 提交和合并
```

## 并行任务完成检查

> 前提：并行派发需使用 `background=true`，且已设置环境变量 `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true`（安装脚本已自动配置；缺失时 `background=true` 退化为同步阻塞）。完整协议见同目录 [`parallel-task-management.md`](parallel-task-management.md)。

**⚠️ 关键：在输出任务完成总结前，必须确认所有子智能体任务已完成。**

### 问题场景
当主智能体派出多个子智能体并行处理任务时：
- 可能出现：5个子智能体派出，3个返回结果，2个仍在处理
- 错误行为：主智能体基于部分结果就输出"任务完成总结"
- 后果：用户关闭OpenCode会打断未完成的任务；不关闭则子代理完成后再次触发总结

### 完成检查协议
1. **跟踪已派出任务**：记录所有派出的子智能体及其任务
2. **验证完成状态（须经独立核实）**：检查每个任务是否收到`Status: done`的结果。子代理的 `done` 只是**声明**，不是证据——主智能体须在当前消息内独立核实（`git diff`／运行测试／读取变更文件并读取完整输出，或派 `@executor`/`@validator` 执行后读取），核实通过才算 **verified done**。核实是主智能体自己的下一步动作，不是干等子代理再次汇报：「仍在处理」仅指**尚未返回结果**的任务
3. **输出决策**：
   - 所有任务完成（且均已核实）→ 输出完整总结
   - 有任务未完成或未核实 → 输出等待提示

### 并行写任务的文件所有权互斥（硬规则）

同一文件（或强耦合的一组文件）同一时刻**只能有一个写任务所有者**。存在重叠时：用 [`isolated-workspace.md`](isolated-workspace.md) 的 worktree 隔离方案（OpenCode 原生 `worktree_create` + `session_move`），或将任务串行化。只读任务（explore/research/review）不受此限。

> 与「冲突解决：高优先级为准」条款的关系：优先级裁决解决**已返回结果的意见冲突**；文件所有权冲突发生在**执行期间**，只能用隔离/串行预防，两者互补不矛盾。详见 [`parallel-task-management.md`](parallel-task-management.md)。

### 等待提示模板
```
⏳ 任务进行中：我已派出 {N} 个子智能体处理此任务。

已完成：
- ✅ {agent1}: {已完成工作的简要描述}
- ✅ {agent2}: {已完成工作的简要描述}

仍在处理：
- 🔄 {agent3}: {任务描述}
- 🔄 {agent4}: {任务描述}

请稍等，我会在所有任务完成后提供完整的总结。您可以继续等待，或者稍后回来查看结果。
```

### 实现要点
- **绝不**在任何子代理仍在处理时输出"任务完成"
- **绝不**仅因为收到部分结果就认为任务完成
- **绝不**把未经核实的子代理 `Status: done` 当作完成——`done` 是声明，核实才是证据
- **必须**在总结前显式检查所有任务状态
- **必须**使用等待提示模板处理未完成任务
- **必须**在当前消息内完成独立核实（`git diff`／运行测试／读取变更文件）并读取完整输出，再宣布完成——文字描述不是证据（验证铁律）

## 两阶段审查

### Stage 1: 规范合规性审查 (@spec-reviewer)
- 验证实现是否符合原始需求
- 使用规范锚定（[Sn] 引用）
- 证据优先原则

### Stage 2: 代码质量审查 (@reviewer)
- 检查代码质量、性能、安全性
- 在 Stage 1 通过后才能运行
- 输出结构化审查报告

> **接收审查意见的一侧**（实现者）须遵循 [`review-feedback-discipline.md`](review-feedback-discipline.md)：完整读懂 → 复述 → 对照代码库逐条验证 → 分级处理（Critical 立即修／Important 修完才继续／Minor 记录）→ 回应 → 才开始实现。外部反馈是待评估的建议，不是命令。

## TDD 原则

每个任务都遵循测试驱动开发：
1. **RED**: 编写失败测试
2. **GREEN**: 编写最小实现让测试通过
3. **REFACTOR**: 重构代码

> 测试持续失败、同一问题反复修不好时，按 [`debug-methodology.md`](debug-methodology.md) 执行：根因调查未完成不得提出修复；连续 3 次失败即停止并上报（疑似架构问题）。

## 何时使用结构化工作流

| 任务类型 | 推荐方式 |
|---------|---------|
| 简单、单步骤 | 直接处理 |
| 2-3 步骤、需求清晰 | 直接实现 + 审查 |
| 3+ 步骤、复杂 | 完整结构化工作流 |
| 新功能、需求模糊 | 完整工作流 + 构思 |
| Bug 修复、问题清晰 | 跳过构思，使用计划 + 执行 |

## 快速命令

```bash
# 启动 OpenCode 并使用 smart-router 主代理（自动编排下述流程；也可直接指定 Erribaba 或 Zero）
opencode

# 在对话中使用结构化工作流
@workflow-orchestrator 请帮我实现用户认证系统

# 单独使用某个阶段
@plan-writer 请为这个功能创建实现计划
@spec-reviewer 请验证这个实现是否符合需求
```
