# opencode-agentcrew

<div align="right">

**English** | **[中文](README.md)**

</div>

**A ready-to-use OpenCode agent team with 39 specialized roles covering the full-stack development workflow.**

## 📑 Table of Contents

- [Quick Install](#quick-install)
- [Recommended: OpenCode Go Plan](#recommended-opencode-go-plan)
- [Configure Models](#configure-models)
- [Directory Structure](#directory-structure)
- [Agent Overview](#agent-overview)
- [Structured Workflow](#structured-workflow)
- [Usage](#usage)
- [File Format](#file-format)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

- **39 Specialized Agents** — Architecture design, code generation, debugging, testing, frontend development, security audit, and more
- **Smart Routing** — `smart-router` dispatches skills and models automatically based on task complexity, domain, and cost
- **Tiered Subagents** — 9 high-frequency roles have `-lite` variants (`mimo-v2.6-flash`) for fast, cheap simple tasks
- **Structured Workflow** — Inspired by the MiMo Compose pattern, supports the full brainstorm→plan→execute→review→merge pipeline
- **Two-Stage Review** — Spec compliance review + code quality review, ensuring the implementation matches requirements and the code is well built
- **Orchestration Discipline** — MiMo Compose-style disciplines: Verification Iron Law (done is a claim, independently verified), reviewer tier parity, exclusive file ownership, destructive ops never auto-approved
- **Triple Primary Agents** — smart-router (intelligent dispatch) + Erribaba (production code) + Zero (rapid prototyping/multimodal)
- **Multi-Model Collaboration** — 8 opencode-go models (mimo-v2.6-flash, mimo-v2.6-pro, deepseek-v4.1-flash, glm-5.2, glm-5.3-flash, kimi-k2.7-code, qwen3.7-plus, qwen3.8-flash); smart-router runs on the Xiaomi Token Plan billing channel (`console-xiaomi-token-plan/mimo-v2.6-flash`)
- **Image Handling** — All three primaries are natively multimodal and analyze pasted images directly; on-disk image files can be delegated to vision-dev
- **Ready to Use** — One-command installation, automatic configuration

## Quick Install

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/DaweiTian/opencode-agentcrew/master/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/DaweiTian/opencode-agentcrew/master/install.ps1 | iex
```

> The install script automatically does three things:
>
> 1. **Installs agents** — downloads `agents/*.md` to `~/.config/opencode/agents/` (an existing agents directory is first backed up to `~/.config/opencode/agents-备份-<timestamp>`);
> 2. **Installs reference docs** — copies `references/*` to `~/.config/opencode/references/` (6 workflow docs in total: the structured workflow quick reference WORKFLOW-QUICKREF, the parallel task protocol parallel-task-management shared by the 3 primary agents, plus the review feedback discipline, debug methodology, isolated workspace, and behavior drill playbook docs);
> 3. **Enables background subagent parallelism** — appends `export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true` to `~/.bashrc` or `~/.zshrc` (the Windows script sets a user-level environment variable with the same name instead). This variable enables the primary agents' background parallel subtask dispatch; to undo it, remove the corresponding export line at the end of your shell config file (Windows: delete the user environment variable) and reopen your terminal.

### Manual Install

```bash
git clone --depth 1 https://github.com/DaweiTian/opencode-agentcrew.git /tmp/opencode-agents

# 1. Copy agent files
mkdir -p ~/.config/opencode/agents
cp /tmp/opencode-agents/agents/*.md ~/.config/opencode/agents/

# 2. Copy reference docs (structured workflow quick reference, etc.)
mkdir -p ~/.config/opencode/references
cp -r /tmp/opencode-agents/references/* ~/.config/opencode/references/

# 3. Enable background subagent parallelism (use ~/.zshrc for zsh)
echo 'export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true' >> ~/.bashrc
source ~/.bashrc

rm -rf /tmp/opencode-agents
```

> Manual install on Windows (PowerShell): target paths are under `$env:USERPROFILE\.config\opencode\`; set the environment variable with
> `[Environment]::SetEnvironmentVariable("OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS", "true", "User")`.

Finally, add the `references` field to `~/.config/opencode/opencode.json` pointing at the reference docs directory — **without this configuration, the structured workflow reference docs will not take effect**:

```json
{
  "references": {
    "workflow-docs": {
      "path": "~/.config/opencode/references/workflow",
      "description": "智能体工作流文档和快速参考，包含结构化工作流指南、代理配置和最佳实践",
      "hidden": false
    }
  }
}
```

## Recommended: OpenCode Go Plan

This agent collection requires multiple models working together. We recommend the [OpenCode Go Plan](https://opencode.ai/go?ref=4BZQW1YPFK) — one subscription gives you access to every model in the plan (36 models officially) with no separate API key configuration needed.

**Benefits:**
- Rich model selection: the official plan covers 36 models, and all 8 opencode-go models used by this collection are included in the Go Plan
- Cost-effective: cheaper than purchasing individual API access
- Ready to use: no multi-provider setup — just use the `opencode-go/<model-id>` format

> The 8 opencode-go models used by the 39 agents in this collection (mimo-v2.6-flash, mimo-v2.6-pro, deepseek-v4.1-flash, glm-5.2, glm-5.3-flash, kimi-k2.7-code, qwen3.7-plus, qwen3.8-flash) are all confirmed to be included in the Go Plan; smart-router runs on the Xiaomi Token Plan billing channel (`console-xiaomi-token-plan/mimo-v2.6-flash`) instead.
> All models chosen for this collection are **Chinese domestic models** that work directly in China — no foreign models such as GPT/Claude/Grok are required.
>
> Model quotas are maintained officially and change frequently, so this README keeps no local quota snapshot. Please refer to the official pages:
> - Plan overview: <https://opencode.ai/go>
> - Usage limits: <https://opencode.ai/docs/go#usage-limits>

## Configure Models

After installation, you need to configure models for each agent. Copy and send the following prompt to your OpenCode agent — it will handle the configuration automatically:

<details>
<summary>📋 Click to expand setup prompt</summary>

````
--- Copy the prompt below and send it to your OpenCode agent ---

I just installed the opencode-agents collection (located at ~/.config/opencode/agents/).
Please help me complete the following configuration:

## Step 1: Check existing providers and models

Read ~/.config/opencode/opencode.json and list my currently configured providers and models.

## Step 2: Select models

Below are the default models for each agent in the collection. Based on my existing providers and models, select an available model for each agent (prefer more capable models):

| Agent | Default Model | Role |
|-------|---------------|------|
| 🎯 smart-router | console-xiaomi-token-plan/mimo-v2.6-flash | Primary (intelligent dispatch, recommended default) |
| 🌱 Zero | opencode-go/mimo-v2.6-flash | Primary (rapid prototyping, multimodal) |
| 🛠️ Erribaba | opencode-go/mimo-v2.6-pro | Primary (production code, deep analysis) |
| 🏗️ api-designer | opencode-go/qwen3.7-plus | API design |
| 🏗️ api-designer-lite | opencode-go/mimo-v2.6-flash | API design (lite) |
| 🏗️ architect | opencode-go/glm-5.2 | Architecture design |
| ⚙️ code-generator | opencode-go/mimo-v2.6-pro | Code generation |
| ⚙️ code-generator-lite | opencode-go/mimo-v2.6-flash | Code generation (lite) |
| 🗄️ db-engineer | opencode-go/deepseek-v4.1-flash | Database engineering |
| 🐛 debugger | opencode-go/deepseek-v4.1-flash | Debugging |
| 🐛 debugger-lite | opencode-go/mimo-v2.6-flash | Debugging (lite) |
| 🚀 devops | opencode-go/mimo-v2.6-flash | DevOps/CI-CD |
| 📚 doc-writer | opencode-go/qwen3.8-flash | Documentation |
| 📚 doc-writer-lite | opencode-go/mimo-v2.6-flash | Documentation (lite) |
| 🎭 e2e-tester | opencode-go/mimo-v2.6-flash | End-to-end testing |
| 🖥️ executor | opencode-go/mimo-v2.6-flash | Command execution |
| 🖌️ frontend-dev | opencode-go/kimi-k2.7-code | Frontend development |
| 🖌️ frontend-dev-lite | opencode-go/mimo-v2.6-flash | Frontend development (lite) |
| ⚖️ frontend-reviewer | opencode-go/mimo-v2.6-flash | Frontend review |
| 🌿 git-assistant | opencode-go/qwen3.8-flash | Git workflow |
| 🔄 migration | opencode-go/deepseek-v4.1-flash | Migration |
| ⚡ perf-optimizer | opencode-go/qwen3.7-plus | Performance optimization |
| 🗺️ plan-writer | opencode-go/qwen3.7-plus | Implementation planning |
| 🗺️ project-manager | opencode-go/qwen3.8-flash | Project management |
| 🧹 refactorer | opencode-go/mimo-v2.6-pro | Code refactoring |
| 🧹 refactorer-lite | opencode-go/mimo-v2.6-flash | Code refactoring (lite) |
| 🔎 research | opencode-go/qwen3.8-flash | Technical research |
| 🔎 research-lite | opencode-go/mimo-v2.6-flash | Technical research (lite) |
| ⚖️ reviewer | opencode-go/deepseek-v4.1-flash | Code review (Stage 2) |
| ⚖️ reviewer-lite | opencode-go/mimo-v2.6-flash | Code review (lite) |
| 🛡️ security-auditor | opencode-go/deepseek-v4.1-flash | Security audit |
| ⚙️ software-engineer | opencode-go/mimo-v2.6-pro | Full-stack implementation |
| 🔍 spec-reviewer | opencode-go/deepseek-v4.1-flash | Spec compliance review (Stage 1) |
| 🧪 test-writer | opencode-go/kimi-k2.7-code | Test writing |
| 🧪 test-writer-lite | opencode-go/mimo-v2.6-flash | Test writing (lite) |
| 🎨 ui-designer | opencode-go/glm-5.3-flash | UI design |
| ✅ validator | opencode-go/deepseek-v4.1-flash | Validation |
| 👁️ vision-dev | opencode-go/mimo-v2.6-flash | Visual development |
| 🧭 workflow-orchestrator | opencode-go/glm-5.3-flash | Workflow orchestration |

If I'm missing a provider, tell me which models need additional configuration.
If I already have the corresponding models, proceed to Step 3.

## Step 3: Update agent files

Read all .md files under ~/.config/opencode/agents/ and replace the `model:` field
in each file's frontmatter with the model you selected for that agent in Step 2.

## Step 4: Set primary agent

Set `default_agent` in ~/.config/opencode/opencode.json to "smart-router" (recommended default; use "Erribaba" for production-code mode, "Zero" for rapid prototyping).

## Step 5: Configure reference docs

Add the references configuration to ~/.config/opencode/opencode.json, pointing at the workflow docs:

```json
"references": {
  "workflow-docs": {
    "path": "~/.config/opencode/references/workflow",
    "description": "智能体工作流文档和快速参考，包含结构化工作流指南、代理配置和最佳实践",
    "hidden": false
  }
}
```

## Step 6: Verify

List all agents and their assigned models to confirm configuration is complete.
Verify that the references configuration is correct.
````

</details>

## Directory Structure

```
opencode-agentcrew/
├── agents/                      # Agent configuration files (39)
│   ├── smart-router.md          # Primary agent (intelligent dispatch, recommended default)
│   ├── Zero.md                  # Primary agent (rapid prototyping, multimodal)
│   ├── Erribaba.md              # Primary agent (production code, deep analysis)
│   ├── api-designer.md          # API design
│   ├── api-designer-lite.md     # API design (lite)
│   ├── architect.md             # Architecture design
│   ├── code-generator.md        # Code generation
│   ├── code-generator-lite.md   # Code generation (lite)
│   ├── db-engineer.md           # Database engineering
│   ├── debugger.md              # Debugging & diagnostics
│   ├── debugger-lite.md         # Debugging (lite)
│   ├── devops.md                # DevOps/CI-CD
│   ├── doc-writer.md            # Documentation writing
│   ├── doc-writer-lite.md       # Documentation (lite)
│   ├── e2e-tester.md            # End-to-end testing
│   ├── executor.md              # Command execution
│   ├── frontend-dev.md          # Frontend development
│   ├── frontend-dev-lite.md     # Frontend development (lite)
│   ├── frontend-reviewer.md     # Frontend code review
│   ├── git-assistant.md         # Git workflow
│   ├── migration.md             # Migration expert
│   ├── perf-optimizer.md        # Performance optimization
│   ├── plan-writer.md           # Implementation planning
│   ├── project-manager.md       # Project management
│   ├── refactorer.md            # Code refactoring
│   ├── refactorer-lite.md       # Code refactoring (lite)
│   ├── research.md              # Technical research
│   ├── research-lite.md         # Technical research (lite)
│   ├── reviewer.md              # Code review (Stage 2)
│   ├── reviewer-lite.md         # Code review (lite)
│   ├── security-auditor.md      # Security audit
│   ├── software-engineer.md     # Full-stack implementation
│   ├── spec-reviewer.md         # Spec compliance review (Stage 1)
│   ├── test-writer.md           # Test writing
│   ├── test-writer-lite.md      # Test writing (lite)
│   ├── ui-designer.md           # UI design & styling
│   ├── validator.md             # Final validation
│   ├── vision-dev.md            # Visual development
│   └── workflow-orchestrator.md # Workflow orchestration
├── references/                  # Reference docs (OpenCode References feature)
│   ├── lessons.md               # Team memory: field lessons (environment traps, model-compliance findings)
│   └── workflow/                # Workflow documentation
│       ├── WORKFLOW-QUICKREF.md         # Structured workflow quick reference (one-page cheat sheet)
│       ├── parallel-task-management.md  # Parallel task protocol shared by the 3 primary agents (phase barriers, completion check)
│       ├── review-feedback-discipline.md # Review feedback discipline: verify each finding before implementing, no sycophancy
│       ├── debug-methodology.md          # Debug methodology: no fix before root-cause investigation is done, three-strikes rule
│       ├── drill-playbook.md             # Behavior drill playbook: post-change regression drills for the contract
│       └── isolated-workspace.md         # Isolated workspace: worktree isolation for parallel writes, provenance-based cleanup
├── .gitignore                   # Git ignore rules
├── AGENTS.md                    # Agent configuration and usage guide
├── install.sh                   # Linux/macOS one-command install script
├── install.ps1                  # Windows one-command install script
├── LICENSE                      # MIT license
├── README.en.md                 # Project README (English)
└── README.md                    # Project README (Chinese)
```

## Agent Overview

### Primary Agents

| File | Model | Description |
|------|-------|-------------|
| 🎯 `smart-router.md` | console-xiaomi-token-plan/mimo-v2.6-flash | Intelligent dispatch (complexity + domain + cost routing), recommended default |
| 🌱 `Zero.md` | opencode-go/mimo-v2.6-flash | Rapid prototyping, multimodal input, lightweight tasks |
| 🛠️ `Erribaba.md` | opencode-go/mimo-v2.6-pro | Production code, complex algorithms, deep analysis |

### Subagents

| File | Responsibility | Writable | Executable | Delegation |
|------|---------------|:--------:|:----------:|:----------:|
| 🏗️ `api-designer.md` | API endpoint design, OpenAPI specs | ✓ | ✗ | ✗ |
| 🏗️ `architect.md` | System design, module planning, tech selection | ✗ | ✗ | ✗ |
| ⚙️ `code-generator.md` | High-quality code generation, bug fixes | ✓ | ✗ | ✗ |
| 🗄️ `db-engineer.md` | Database schema, migrations, SQL optimization | ✓ | ✓ | ✗ |
| 🐛 `debugger.md` | Systematic bug isolation and fixing | ✓ | ✓ | ✗ |
| 🚀 `devops.md` | Docker, CI/CD, Kubernetes, deployment | ✓ | ✓ | ✗ |
| 📚 `doc-writer.md` | Technical docs, API references, README | ✓ | ✗ | ✗ |
| 🎭 `e2e-tester.md` | Playwright/Cypress end-to-end tests | ✓ | ✗ | ✗ |
| 🖥️ `executor.md` | Run commands, execute tests, build projects | ✓ | ✓ | ✗ |
| 🖌️ `frontend-dev.md` | React/Vue/Svelte component development | ✓ | ✗ | ✗ |
| ⚖️ `frontend-reviewer.md` | Frontend review, accessibility, performance | ✗ | ✗ | ✗ |
| 🌿 `git-assistant.md` | Commit messages, branch naming, PR descriptions | ✗ | ✗ | ✗ |
| 🔄 `migration.md` | Framework upgrades, DB migrations, tech stack switches | ✓ | ✓ | ✗ |
| ⚡ `perf-optimizer.md` | Performance profiling and optimization | ✗ | ✓ | ✗ |
| 🗺️ `plan-writer.md` | Implementation planning, TDD task breakdown | Partial* | ✗ | ✗ |
| 🗺️ `project-manager.md` | Requirement analysis, task breakdown, sprint planning | Partial* | ✗ | ✗ |
| 🧹 `refactorer.md` | Code refactoring, duplication removal, structure improvement | ✓ | ✗ | ✗ |
| 🔎 `research.md` | Documentation lookup, tech research | ✗ | ✗ | ✗ |
| ⚖️ `reviewer.md` | Code review (Stage 2: code quality) | ✗ | ✗ | ✗ |
| 🛡️ `security-auditor.md` | OWASP Top 10 security audit | ✓ | ✓ | ✗ |
| ⚙️ `software-engineer.md` | Full-stack feature end-to-end implementation | ✓ | ✓ | ✗ |
| 🔍 `spec-reviewer.md` | Spec compliance review (Stage 1) | ✗ | ✗ | ✗ |
| 🧪 `test-writer.md` | Unit, integration, and edge-case tests | ✓ | ✗ | ✗ |
| 🎨 `ui-designer.md` | CSS/Tailwind, responsive layouts, animations | ✓ | ✗ | ✗ |
| ✅ `validator.md` | Final validation (build, tests, type check) | ✗ | ✓ | ✗ |
| 👁️ `vision-dev.md` | Design analysis, screenshot reproduction, visual dev | ✓ | ✗ | ✗ |
| 🧭 `workflow-orchestrator.md` | Workflow orchestration plan output (read-only advisor, does not dispatch subagents) | ✗ | ✗ | ✗ |

> \* **Partial write**: can only write under the `~/.opencode/plan/` directory (a directory-level allow exception placed after the wildcard denies); read-only everywhere else, and cannot run commands.
> **Delegation**: all 36 subagents (lite variants included) deny `subagent` in their frontmatter — none can delegate further; only the 3 primary agents (smart-router, Zero, Erribaba) dispatch subagents.

### Lite Subagents

All use `mimo-v2.6-flash`, dispatched by `smart-router` for `complexity: simple` tasks. Their permission rules mirror their standard counterparts (all deny `subagent` — no further delegation).

| File | Standard Variant | Responsibility |
|------|------------------|----------------|
| ⚙️ `code-generator-lite.md` | `code-generator` | Simple code generation, boilerplate |
| ⚖️ `reviewer-lite.md` | `reviewer` | Quick diff review (obvious issues) |
| 🐛 `debugger-lite.md` | `debugger` | Simple reproducible bugs |
| 🧪 `test-writer-lite.md` | `test-writer` | Unit tests for single functions |
| 📚 `doc-writer-lite.md` | `doc-writer` | Docstrings, README sections, changelog |
| 🖌️ `frontend-dev-lite.md` | `frontend-dev` | Simple presentational components |
| 🔎 `research-lite.md` | `research` | Factual lookups (API, syntax) |
| 🧹 `refactorer-lite.md` | `refactorer` | Rename, extract, simplify conditional |
| 🏗️ `api-designer-lite.md` | `api-designer` | Simple API endpoint design, OpenAPI drafts |

## Structured Workflow

This agent collection supports a structured development workflow inspired by the MiMo Compose pattern, suitable for complex, multi-step tasks.

### Workflow Phases

```
User Request
    ↓
[Phase 1: Brainstorm] — architect, research (optional but recommended)
    ↓
[Phase 2: Plan] — plan-writer, project-manager (required for 3+ step tasks)
    ↓
[Phase 3: Execute] — test-writer, code-generator, executor (TDD cycle)
    ↓
[Phase 4: Review] — spec-reviewer (Stage 1) → reviewer (Stage 2)
    ↓
[Phase 5: Merge] — validator, git-assistant (test gate → state detection → 4 options: merge locally/open PR/keep as-is/discard → provenance cleanup)
```

### Key Concepts

#### Two-Stage Review
The review phase uses a two-stage process:
1. **Stage 1: Spec Compliance Review** (`@spec-reviewer`) — Verifies the implementation matches requirements
2. **Stage 2: Code Quality Review** (`@reviewer`) — Verifies the code is well built

**Important:** Stage 1 must pass before Stage 2 runs.

**Reviewer Tier Rule:** the reviewer's model tier must not be lower than the tier of the implementer under review — a weaker reviewer shares the implementer's blind spots and turns the quality gate into decoration.

#### TDD Integration
The execute phase follows Test-Driven Development:
1. Write a failing test (`@test-writer`)
2. Verify the test fails (`@executor`)
3. Write the minimal implementation (`@code-generator`)
4. Verify the test passes (`@executor`)
5. Refactor (if needed)
6. Commit (`@git-assistant`)

#### Workflow Orchestration
For complex tasks, use `@workflow-orchestrator` to produce a full workflow orchestration plan (phases, dispatch order, phase barriers, quality gates). It is a read-only advisor (deny edit + shell + subagent) — the primary agent executes the plan by dispatching subagents in the specified order.

#### Verification & Safety Rules
On top of the workflow phases, all three primary agents (`smart-router`/`Zero`/`Erribaba`) enforce three disciplines:

1. **Verification Iron Law** — no completion claim without fresh evidence: the verification command must have been run within the current message and its full output read and checked. A subagent's `Status: done` is a claim, not evidence — the primary agent must independently verify the work (`git diff`, run the test, read the changed file) before anything counts as done. Prose is not evidence.
2. **Destructive Operations are never auto-approved** — force push, deleting branches, discarding work, removing a worktree not created in this session, or a hard reset always require explicit user confirmation, even when autonomous mode is active. Silence ≠ approval.
3. **Ask Discipline** — user decisions and approvals are requested through the structured question tool with concrete options, never a trailing natural-language question (which stalls headless and background runs).

#### Orchestration Hard Rules
Every `@workflow-orchestrator` plan enforces three hard rules:

1. **Reviewer Tier Parity** — the review subagent's model tier (T1/T2/T3; the tier ladder is defined in `agents/workflow-orchestrator.md`) must never be lower than the tier of the implementer under review.
2. **Pre-Flight Plan Review** — before any Execute-phase dispatch, scan the whole plan once for conflicts (overlapping file ownership, ordering issues) and report all findings **in one batch**; resolve them, then dispatch tasks.
3. **Continuous Execution Within a Phase** — no per-task check-ins inside a phase; stop only at BLOCKED, genuine ambiguity, phase barriers, or phase boundaries that require user sign-off.

#### Workflow Reference Documents
Cross-agent protocols live in `references/workflow/`; the primary agents keep only core-rule summaries in their bodies:

- [parallel-task-management.md](references/workflow/parallel-task-management.md) — Parallel dispatch protocol: phase barriers, first-come-first-serve within a phase, exclusive file ownership, timeout and completion checks
- [WORKFLOW-QUICKREF.md](references/workflow/WORKFLOW-QUICKREF.md) — One-page cheat sheet of the whole protocol
- [review-feedback-discipline.md](references/workflow/review-feedback-discipline.md) — Receiving review feedback: verify each finding against the codebase before implementing, no sycophantic agreement
- [debug-methodology.md](references/workflow/debug-methodology.md) — Debug methodology: no fix proposal before root-cause investigation is complete; stop and escalate after three failed attempts
- [isolated-workspace.md](references/workflow/isolated-workspace.md) — Isolated workspace: `worktree_create` + `session_move` to isolate parallel write tasks, provenance-based cleanup

After any change to the handoff contract, its copies, or a prompt batch, run the behavior drill per [drill-playbook.md](references/workflow/drill-playbook.md) — the consistency gate verifies files, drills verify that models actually honor the contract at runtime; receipts can be spot-checked with `scripts/check-receipt.ps1`, and field lessons accumulate in [lessons.md](references/lessons.md).

### When to Use the Structured Workflow

| Task Type | Recommended Approach |
|-----------|---------------------|
| Simple, single-step | Handle directly |
| 2-3 steps, clear requirements | Direct implementation + review |
| 3+ steps, complex | Full structured workflow |
| New feature, ambiguous requirements | Full workflow + brainstorm |
| Bug fix, clear issue | Skip brainstorm, use plan + execute |

### Agent Roles in the Workflow

| Phase | Primary Agents | Supporting Agents |
|-------|---------------|-------------------|
| Brainstorm | `architect`, `research` | `project-manager` |
| Plan | `plan-writer`, `project-manager` | `architect` |
| Execute | `test-writer`, `code-generator` | `executor`, `git-assistant` |
| Review | `spec-reviewer`, `reviewer` | `security-auditor`, `frontend-reviewer` |
| Merge | `validator` | `git-assistant`, `devops` |

> 📖 See [WORKFLOW-QUICKREF](references/workflow/WORKFLOW-QUICKREF.md) for details. The install script automatically copies `references/` into `~/.config/opencode/references/`; you must also configure the `references` field in `~/.config/opencode/opencode.json` (see [Manual Install](#manual-install)) for the structured workflow reference docs to take effect.

## Usage

1. **Recommended: use `smart-router` as default** — automatically dispatches skills and models by complexity, domain, and cost
2. Or switch to `Erribaba` (production code, deep analysis) or `Zero` (rapid prototyping/multimodal)
3. Describe your task in the conversation — the primary agent automatically delegates to the appropriate subagent
4. Subagents are invoked via `@agent-name` by the primary agent

### Choosing a Primary Agent

> All three primaries are natively multimodal — any of them analyzes images pasted into the conversation directly, with no need to switch; on-disk image files (design mockups, screenshots, etc.) can be delegated to vision-dev.

- **smart-router** (recommended): Intelligent dispatch — simple tasks go to `-lite` (fastest, cheapest), complex tasks use multi-agent workflows
- **Erribaba**: Production code, complex tasks, deep analysis
- **Zero**: Rapid prototyping, lightweight tasks

Set in `~/.config/opencode/opencode.json`:
```json
{
  "default_agent": "smart-router"
}
```

### Smart Routing Policy

`smart-router` routes along three axes:

| Axis | Values | Effect |
|------|--------|--------|
| **Domain** | `frontend` / `backend` / `fullstack` / `db` / `docs` / `review` / `security` / `debug` / `test` / `e2e` / `research` / `refactor` / `perf` / `api` / `arch` / `plan` / `pm` / `git` / `migration` / `devops` / `exec` / `validate` / `vision` / `workflow` | Picks the subagent |
| **Complexity** | `simple` / `medium` / `complex` | `simple` → the `-lite` variant when the domain has one, otherwise always the standard subagent; `complex` → multi-agent combination |
| **Cost** | bias-to-cheap by default | Only escalate to `mimo-v2.6-pro` / `glm-5.2` / `kimi-k2.7-code` when clearly required |

**Manual override**: users can bypass smart routing by naming an agent (`@agent-name`) or a model ("use mimo-v2.6-pro"). `smart-router` detects this and dispatches directly.

## File Format

Each agent file consists of YAML frontmatter + Markdown body:

```yaml
---
description: Chinese description (used by OpenCode for trigger matching)
mode: primary | subagent
model: provider/model-name
permissions:        # primary agents may omit (all tools allowed); subagents must declare it, including a subagent deny
  - action: edit
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: deny
  - action: subagent    # required for every subagent — only primary agents may delegate
    resource: "*"
    effect: deny
---

<System prompt>
```

> ℹ️ Since 2026-09 this repo has fully migrated from the V1 `tools:` field to the V2 `permissions:` list (the V1 `tools:` key is silently ignored by OpenCode V2). The `edit` action covers all three file-modification tools (edit/write/patch), the `shell` action covers command execution, the `subagent` action controls further delegation, and the last matching rule wins. All 36 subagents deny `subagent`; only the 3 primary agents dispatch subagents.

## Contributing

1. Fork the repository
2. Create a `Feat_xxx` branch
3. Commit your code
4. Create a Pull Request

## License

[MIT](LICENSE)
