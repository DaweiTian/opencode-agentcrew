# AGENTS.md

## What This Repo Is

A collection of OpenCode agent configuration files. No code, no build, no tests — only `.md` files that define agent behavior via YAML frontmatter + prompt body. Hosted on GitHub at `DaweiTian/opencode-agentcrew`.

## Structure

```
agents/
  *.md          # 38 agent definitions (3 primary + 35 subagent)
README.md       # Chinese (38 agents, model table included)
README.en.md    # English (same)
LICENSE         # MIT
```

## Agent File Format

Every file in `agents/` uses this structure:

```yaml
---
description: <Chinese description — this is what OpenCode uses to decide when to invoke the agent>
mode: primary | subagent
model: <provider/model-name>
permissions:      # optional — omit to allow all tools
  - action: edit        # deny specific actions per agent role
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: deny
---

<System prompt in English or Chinese>
```

## Key Conventions

- **`description` is always in Chinese** — this is the trigger text OpenCode matches against. Match the style: role name + capabilities + trigger scenarios.
- **`mode: primary`** means the agent can be a top-level session. Three files are primary agents: `smart-router.md`, `Zero.md`, and `Erribaba.md`.
  - **smart-router.md** (`opencode-go/mimo-v2.6-flash`) — intelligent dispatching, multimodal (image input): routes tasks by complexity/domain/cost to the right subagent and model tier (recommended default entry point)
  - **Zero.md** (`opencode-go/mimo-v2.6-flash`) — rapid prototyping, multimodal (image input), lightweight tasks
  - **Erribaba.md** (`opencode-go/mimo-v2.6-pro`) — production code, complex algorithms, deep analysis, multimodal (image input)
- **`mode: subagent`** means the agent is only invoked via delegation from a primary agent.
- **Filename = agent name** used in delegation (e.g., `reviewer.md` → delegate as `reviewer`).
- **Model naming**: all agents use the `opencode-go/` provider prefix — models include `opencode-go/mimo-v2.6-flash`, `opencode-go/mimo-v2.6-pro`, `opencode-go/deepseek-v4.1-flash`, `opencode-go/glm-5.2`, `opencode-go/kimi-k2.7-code`, `opencode-go/qwen3.8-flash`, `opencode-go/minimax-m3`, `opencode-go/longcat-2.5-preview-free`, `opencode-go/step-5-preview-free`.
- **Tool access** defaults to all tools allowed when `permissions` key is omitted (primary agents). Subagents declare explicit `permissions` deny rules: agents that write code omit the `edit` deny (or allow specific paths such as `~/.opencode/plan/*`); read-only subagents deny both `edit` and `shell`; agents needing shell access omit the `shell` deny.

## All 38 Agents

### Primary (3)

| File | Model | Role |
|------|-------|------|
| `smart-router.md` | `opencode-go/mimo-v2.6-flash` | Intelligent dispatching — routes tasks by complexity/domain/cost to the right subagent and model tier (recommended default) |
| `Zero.md` | `opencode-go/mimo-v2.6-flash` | Rapid prototyping, multimodal input, quick iteration |
| `Erribaba.md` | `opencode-go/mimo-v2.6-pro` | Production code, complex algorithms, full-stack engineering |

### Subagents — Read-only (12)

Denied both `edit` and `shell` in `permissions` frontmatter (equivalent to all tools `false`):

| File | Model | Role |
|------|-------|------|
| `architect.md` | `opencode-go/glm-5.2` | System architecture design |
| `frontend-reviewer.md` | `opencode-go/mimo-v2.6-flash` | Frontend code review |
| `git-assistant.md` | `opencode-go/longcat-2.5-preview-free` | Git workflow assistance |
| `plan-writer.md` | `opencode-go/mimo-v2.6-pro` | Implementation planning (edit allowed only under `~/.opencode/plan/*`) |
| `project-manager.md` | `opencode-go/qwen3.8-flash` | Project management (edit allowed only under `~/.opencode/plan/*`) |
| `research.md` | `opencode-go/qwen3.8-flash` | Technical research |
| `research-lite.md` | `opencode-go/mimo-v2.6-flash` | Technical research (lite) |
| `reviewer.md` | `opencode-go/deepseek-v4.1-flash` | Code quality review (Stage 2) |
| `reviewer-lite.md` | `opencode-go/mimo-v2.6-flash` | Code quality review (lite) |
| `security-auditor.md` | `opencode-go/deepseek-v4.1-flash` | Security audit |
| `spec-reviewer.md` | `opencode-go/deepseek-v4.1-flash` | Spec compliance review (Stage 1) |
| `workflow-orchestrator.md` | `opencode-go/mimo-v2.6-pro` | Workflow orchestration |

Plus `perf-optimizer` (`opencode-go/mimo-v2.6-pro`) and `validator` (`opencode-go/step-5-preview-free`) — deny `edit` but allow `shell`: read-only for file edits, have bash for running commands.

### Subagents — With write/edit (21)

No `edit` deny (or only path-scoped denies) in `permissions` frontmatter:

| File | Model | Has bash | Role |
|------|-------|:--------:|------|
| `api-designer.md` | `opencode-go/mimo-v2.6-pro` | ✗ | API endpoint design |
| `code-generator.md` | `opencode-go/mimo-v2.6-pro` | ✗ | Code generation |
| `code-generator-lite.md` | `opencode-go/mimo-v2.6-flash` | ✗ | Code generation (lite) |
| `db-engineer.md` | `opencode-go/deepseek-v4.1-flash` | ✓ | Database engineering |
| `debugger.md` | `opencode-go/deepseek-v4.1-flash` | ✓ | Bug debugging |
| `debugger-lite.md` | `opencode-go/mimo-v2.6-flash` | ✓ | Bug debugging (lite) |
| `devops.md` | `opencode-go/mimo-v2.6-flash` | ✓ | DevOps/CI-CD |
| `doc-writer.md` | `opencode-go/qwen3.8-flash` | ✗ | Documentation |
| `doc-writer-lite.md` | `opencode-go/mimo-v2.6-flash` | ✗ | Documentation (lite) |
| `e2e-tester.md` | `opencode-go/mimo-v2.6-flash` | ✗ | E2E testing |
| `executor.md` | `opencode-go/minimax-m3` | ✓ | Command execution |
| `frontend-dev.md` | `opencode-go/kimi-k2.7-code` | ✗ | Frontend development |
| `frontend-dev-lite.md` | `opencode-go/mimo-v2.6-flash` | ✗ | Frontend development (lite) |
| `migration.md` | `opencode-go/deepseek-v4.1-flash` | ✓ | System migration |
| `refactorer.md` | `opencode-go/mimo-v2.6-pro` | ✗ | Code refactoring |
| `refactorer-lite.md` | `opencode-go/mimo-v2.6-flash` | ✗ | Code refactoring (lite) |
| `software-engineer.md` | `opencode-go/mimo-v2.6-flash` | ✓ | Full-stack implementation |
| `test-writer.md` | `opencode-go/mimo-v2.6-pro` | ✗ | Test writing |
| `test-writer-lite.md` | `opencode-go/mimo-v2.6-flash` | ✗ | Test writing (lite) |
| `ui-designer.md` | `opencode-go/kimi-k2.7-code` | ✗ | UI design |
| `vision-dev.md` | `opencode-go/mimo-v2.6-flash` | ✗ | Visual development |

### Lite Agents (8)

All eight `-lite` variants run on `opencode-go/mimo-v2.6-flash`. They are lightweight versions of their full counterparts, dispatched by `smart-router` when it judges task complexity as `simple` — fast and cheap, not suited for complex work:

| Lite Agent | Full Counterpart |
|------------|------------------|
| `code-generator-lite` | `code-generator` |
| `debugger-lite` | `debugger` |
| `doc-writer-lite` | `doc-writer` |
| `frontend-dev-lite` | `frontend-dev` |
| `refactorer-lite` | `refactorer` |
| `research-lite` | `research` |
| `reviewer-lite` | `reviewer` |
| `test-writer-lite` | `test-writer` |

(Their rows also appear in the Read-only and With write/edit tables above, marked `(lite)`.)

## When Adding or Editing Agents

1. Match the frontmatter field order: `description`, `mode`, `model`, then optional `permissions`.
2. Write `description` in Chinese — start with the role name (e.g., "代码审查智能体"), then describe capabilities and trigger scenarios.
3. Keep system prompts concise and structured with `##` sections.
4. **Primary agents must list all available subagents in their body** — update all three primaries (`smart-router.md`, `Zero.md`, and `Erribaba.md`) if adding a new subagent.
5. Do not add build/CI/tooling — this repo has none and needs none.
6. After adding a new agent, update the tables in this file.

## Structured Development Workflow

The agent system supports a structured development workflow inspired by MiMo Code's Compose pattern. This workflow is optional but recommended for complex, multi-step tasks.

### Workflow Phases

```
User Request
    ↓
[Phase 1: Brainstorm] — architect, research
    ↓
[Phase 2: Plan] — plan-writer, project-manager
    ↓
[Phase 3: Execute] — test-writer, code-generator, executor
    ↓
[Phase 4: Review] — spec-reviewer (Stage 1), reviewer (Stage 2)
    ↓
[Phase 5: Merge] — validator, git-assistant
```

### Key Concepts

#### Two-Stage Review
The review phase uses a two-stage process:
1. **Stage 1: Spec Compliance** (`@spec-reviewer`) — Verifies implementation matches requirements
2. **Stage 2: Code Quality** (`@reviewer`) — Verifies code is well-built

**Important:** Stage 1 must pass before Stage 2 runs.

#### TDD Integration
The execute phase follows Test-Driven Development:
1. Write failing test (`@test-writer`)
2. Verify test fails (`@executor`)
3. Write minimal implementation (`@code-generator`)
4. Verify test passes (`@executor`)
5. Refactor if needed
6. Commit (`@git-assistant`)

#### Workflow Orchestration
For complex tasks, use `@workflow-orchestrator` to manage the full workflow. It coordinates other agents in the correct order and ensures quality gates are met.

### When to Use Structured Workflow

| Task Type | Recommended Approach |
|-----------|---------------------|
| Simple, single-step | Handle directly |
| 2-3 steps, clear requirements | Direct implementation with review |
| 3+ steps, complex | Full structured workflow |
| New feature, ambiguous | Full workflow with brainstorm |
| Bug fix, clear issue | Skip brainstorm, use plan + execute |

### Agent Roles in Workflow

| Phase | Primary Agents | Supporting Agents |
|-------|---------------|-------------------|
| Brainstorm | `architect`, `research` | `project-manager` |
| Plan | `plan-writer`, `project-manager` | `architect` |
| Execute | `test-writer`, `code-generator` | `executor`, `git-assistant` |
| Review | `spec-reviewer`, `reviewer` | `security-auditor`, `frontend-reviewer` |
| Merge | `validator` | `git-assistant`, `devops` |

## Parallel Task Management

All primary agents use an **async first-come-first-serve** pattern for parallel subagent delegation.

### 1. 配置（必须）

在 shell 配置文件（`~/.bashrc` 或 `~/.zshrc`）中添加：
```bash
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
```

或者在 Windows 中设置用户环境变量：
```powershell
[Environment]::SetEnvironmentVariable("OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS", "true", "User")
```

没有此配置，所有子代理任务将同步阻塞执行。

### 2. 使用方式（必须）

配置只是开启了功能，代理还必须**主动使用** `background=true` 参数：

```
// ❌ 错误：同步阻塞，等待完成才继续
@code-generator (task A)
@ui-designer (task B)
@db-engineer (task C)

// ✅ 正确：异步并行，立即返回，按完成顺序处理
@code-generator (task A, background=true)
@ui-designer (task B, background=true)
@db-engineer (task C, background=true)
```

### 3. 结果处理（必须）

**⚠️ 关键概念：阶段屏障（Phase Barriers）**

当执行多阶段工作流时，**必须等待当前阶段所有任务完成**才能进入下一阶段：

```
阶段 1：探索（并行启动）
  ├── @explore (模块A, background=true) ─┐
  ├── @explore (模块B, background=true)  │ 全部完成
  ├── @explore (模块C, background=true)  │ 才能进入
  └── @explore (模块D, background=true) ─┘ 下一阶段
  
  ⛔ 屏障：等待所有探索任务完成
  ⛔ 不要启动修复任务
  
阶段 2：分析与计划
  ├── 综合所有探索结果
  ├── 识别跨模块依赖
  └── 制定修复计划
  
阶段 3：执行修复（现在才能启动修复任务）
  ├── @debugger (修复1, background=true)
  └── @software-engineer (修复2, background=true)
```

**同一阶段内的并行任务**使用先到先处理模式：

```
收到 code-generator 结果 → 立即验证并处理 → 继续等待同阶段其他任务
收到 db-engineer 结果 → 立即验证并处理 → 继续等待同阶段其他任务
收到 ui-designer 结果 → 立即验证并处理 → 所有任务完成 → 进入下一阶段
```

**❌ 常见错误：**
```
错误：启动探索 → 第一个探索返回 → 立即启动修复代理
正确：启动探索 → 等待所有探索完成 → 综合分析 → 启动修复代理
```

### 4. 注意事项

- **独立任务才用 background=true**：有依赖关系的任务不要并行
- **不要轮询**：系统会自动通知完成，不要主动查询状态
- **超时处理**：复杂任务超过 30 分钟应考虑取消重试
- **冲突解决**：多个子代理修改同一文件时，以高优先级为准（security-auditor > reviewer > validator > others）
- **⚠️ 阶段屏障**：多阶段工作流必须等待当前阶段所有任务完成才能进入下一阶段

### 5. 任务完成检查（关键）

**⚠️ 强制要求：在输出任何任务完成总结之前，必须确认所有子代理任务已完成。**

#### 问题场景
当主智能体派出多个子智能体并行处理任务时：
- 可能出现：5个子智能体派出，3个返回结果，2个仍在处理
- 错误行为：主智能体基于部分结果就输出"任务完成总结"
- 后果：用户关闭OpenCode会打断未完成的任务；不关闭则子代理完成后再次触发总结

#### 解决方案
主智能体必须遵循"任务完成检查协议"：
1. **跟踪已派出任务**：记录所有派出的子智能体及其任务
2. **验证完成状态**：检查每个任务是否收到`Status: done`的结果
3. **输出决策**：
   - 所有任务完成 → 输出完整总结
   - 有任务未完成 → 输出等待提示，列出已完成和仍在处理的任务

#### 等待提示模板
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

#### 实现要点
- **绝不**在任何子代理仍在处理时输出"任务完成"
- **绝不**仅因为收到部分结果就认为任务完成
- **必须**在总结前显式检查所有任务状态
- **必须**使用等待提示模板处理未完成任务

## Language

- Frontmatter `description`: Chinese
- System prompt body: English (most files) or Chinese (acceptable)
- README: Chinese primary, English secondary
