# AGENTS.md

## What This Repo Is

A collection of OpenCode agent configuration files. No code, no build, no tests — only `.md` files that define agent behavior via YAML frontmatter + prompt body. Hosted on Gitee at `aerlee/opencode-agents`.

## Structure

```
agents/
  *.md          # 29 agent definitions (2 primary + 27 subagent)
plugins/
  image-paste-saver.js  # Auto-saves pasted images to /tmp/ for vision-dev
README.md       # Chinese (outdated — lists 18 agents, actual count is 29)
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
temperature: <0.0-1.0>
tools:            # optional — omit keys to allow all
  write: false
  edit: false
  bash: false
---

<System prompt in English or Chinese>
```

## Key Conventions

- **`description` is always in Chinese** — this is the trigger text OpenCode matches against. Match the style: role name + capabilities + trigger scenarios.
- **`mode: primary`** means the agent can be a top-level session. Only `Zero.md` and `Erribaba.md` are primary agents.
  - **Zero.md** (`opencode-go/mimo-v2.5`) — rapid prototyping, multimodal (image input), lightweight tasks
  - **Erribaba.md** (`Xianyu/mimo-v2.5-pro`) — production code, complex algorithms, deep analysis
- **`mode: subagent`** means the agent is only invoked via delegation from a primary agent.
- **Filename = agent name** used in delegation (e.g., `reviewer.md` → delegate as `reviewer`).
- **Model naming**: provider prefix matters — models include `opencode-go/mimo-v2.5`, `opencode-go/mimo-v2.5-pro`, `opencode-go/deepseek-v4-pro`, `opencode-go/kimi-k2.6`, `opencode-go/qwen3.7-plus`, `opencode-go/minimax-m2.7`, `opencode-go/glm-5.1`. Primary agents use different providers: `opencode-go/` vs `Xianyu/`.
- **Tool access** defaults to all tools allowed when `tools` key is omitted (primary agents). Subagents that need to write code must explicitly set `write: true, edit: true`. Read-only subagents set all three to `false`. Agents needing shell access add `bash: true`.

## All 29 Agents

### Primary (2)

| File | Model | Role |
|------|-------|------|
| `Zero.md` | `opencode-go/mimo-v2.5` | Rapid prototyping, multimodal input, quick iteration |
| `Erribaba.md` | `Xianyu/mimo-v2.5-pro` | Production code, complex algorithms, full-stack engineering |

### Subagents — Read-only (10)

| File | Model | Role |
|------|-------|------|
| `architect.md` | `opencode-go/glm-5.1` | System architecture design |
| `frontend-reviewer.md` | `opencode-go/mimo-v2.5` | Frontend code review |
| `git-assistant.md` | `opencode-go/mimo-v2.5` | Git workflow assistance |
| `research.md` | `opencode-go/qwen3.7-plus` | Technical research |
| `reviewer.md` | `opencode-go/deepseek-v4-pro` | Code quality review (Stage 2) |
| `security-auditor.md` | `opencode-go/deepseek-v4-pro` | Security audit |
| `spec-reviewer.md` | `opencode-go/deepseek-v4-pro` | Spec compliance review (Stage 1) |

Plus `perf-optimizer` and `validator` — read-only for file edits but have `bash: true` for running commands.

### Subagents — With write/edit (19)

| File | Model | Has bash | Role |
|------|-------|:--------:|------|
| `api-designer.md` | `opencode-go/mimo-v2.5-pro` | ✗ | API endpoint design |
| `code-generator.md` | `opencode-go/mimo-v2.5-pro` | ✗ | Code generation |
| `db-engineer.md` | `opencode-go/deepseek-v4-pro` | ✓ | Database engineering |
| `debugger.md` | `opencode-go/deepseek-v4-pro` | ✓ | Bug debugging |
| `devops.md` | `opencode-go/mimo-v2.5-pro` | ✓ | DevOps/CI-CD |
| `doc-writer.md` | `opencode-go/qwen3.7-plus` | ✗ | Documentation |
| `e2e-tester.md` | `opencode-go/mimo-v2.5-pro` | ✗ | E2E testing |
| `executor.md` | `opencode-go/minimax-m2.7` | ✓ | Command execution |
| `frontend-dev.md` | `opencode-go/kimi-k2.6` | ✗ | Frontend development |
| `migration.md` | `opencode-go/deepseek-v4-pro` | ✓ | System migration |
| `plan-writer.md` | `opencode-go/mimo-v2.5-pro` | ✗ | Implementation planning |
| `project-manager.md` | `opencode-go/qwen3.7-plus` | ✗ | Project management |
| `refactorer.md` | `opencode-go/mimo-v2.5-pro` | ✗ | Code refactoring |
| `software-engineer.md` | `opencode-go/mimo-v2.5` | ✓ | Full-stack implementation |
| `test-writer.md` | `opencode-go/mimo-v2.5-pro` | ✗ | Test writing |
| `ui-designer.md` | `opencode-go/kimi-k2.6` | ✗ | UI design |
| `vision-dev.md` | `opencode-go/mimo-v2.5` | ✗ | Visual development |
| `workflow-orchestrator.md` | `opencode-go/mimo-v2.5-pro` | ✓ | Workflow orchestration |

## When Adding or Editing Agents

1. Match the frontmatter field order: `description`, `mode`, `model`, `temperature`, then optional `tools`.
2. Write `description` in Chinese — start with the role name (e.g., "代码审查智能体"), then describe capabilities and trigger scenarios.
3. Keep system prompts concise and structured with `##` sections.
4. **Primary agents must list all available subagents in their body** — update both `Zero.md` and `Erribaba.md` if adding a new subagent.
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

## Plugin: image-paste-saver

Source: `plugins/image-paste-saver.js`
Install target: `~/.config/opencode/plugins/` (handled by install scripts)

Automatically detects pasted images in the TUI conversation, saves them to `{project}/.opencode/tmp/`, and injects file path references into the prompt. This enables text-only primary agents (Erribaba) to delegate image analysis to vision-dev.

**How it works:**
1. User pastes an image in the OpenCode TUI
2. Plugin intercepts via `chat.message` hook
3. Image is decoded from base64 and saved to `{project}/.opencode/tmp/`
4. A text reference `[Image saved to: .opencode/tmp/opencode-img-xxx.png]` is injected into the prompt
5. Primary agent sees the file path and delegates to `@vision-dev`

**Cleanup:**
- On plugin dispose (OpenCode exit): deletes all temp files created during the session
- On startup: cleans up stale files older than 1 hour (crash recovery)

**Supported formats:** PNG, JPEG, GIF, WebP, SVG, BMP (max 10MB)

## Parallel Task Management

Both primary agents use an **async first-come-first-serve** pattern for parallel subagent delegation.

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

## Language

- Frontmatter `description`: Chinese
- System prompt body: English (most files) or Chinese (acceptable)
- README: Chinese primary, English secondary
