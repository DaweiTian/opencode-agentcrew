# opencode-agentcrew

**A ready-to-use OpenCode agent team with 26 specialized roles covering the full-stack development workflow.**

## ✨ Features

- **26 Specialized Agents** — Architecture design, code generation, debugging, testing, frontend development, security audit, and more
- **Dual Primary Agents** — Erribaba (production code) + Zero (rapid prototyping/multimodal)
- **Multi-Model Collaboration** — 7 models including MiMo-V2.5, GLM-5.1, Kimi K2.6, Qwen3.6 Plus, DeepSeek V4 Pro
- **Image Handling** — Auto-intercept pasted images, delegate to vision-dev for analysis
- **Ready to Use** — One-command installation, automatic configuration

## Quick Install

### Linux / macOS

```bash
curl -fsSL https://gitee.com/aerlee/opencode-agents/raw/master/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://gitee.com/aerlee/opencode-agents/raw/master/install.ps1 | iex
```

> The script automatically downloads all agent files to `~/.config/opencode/agents/` and backs up existing configurations.

### Manual Install

```bash
git clone --depth 1 https://gitee.com/aerlee/opencode-agents.git /tmp/opencode-agents
cp /tmp/opencode-agents/agents/*.md ~/.config/opencode/agents/
rm -rf /tmp/opencode-agents
```

## Recommended: OpenCode Go Plan

This agent collection requires multiple models working together. We recommend the [OpenCode Go Plan](https://opencode.ai/go?ref=4BZQW1YPFK) — one subscription gives you access to all 12 models with no separate API key configuration needed.

**Benefits:**
- Rich model selection: 12 mainstream models covering all agent needs
- Cost-effective: cheaper than purchasing individual API access
- Ready to use: no multi-provider setup, just use the `opencode-go/` prefix

**Plan Models & Quotas:**

| Model | Per 5 Hours | Weekly | Monthly |
|-------|-------------|--------|---------|
| GLM-5.1 | 880 | 2,150 | 4,300 |
| GLM-5 | 1,150 | 2,880 | 5,750 |
| Kimi K2.6 | 1,150 | 2,880 | 5,750 |
| Kimi K2.5 | 1,850 | 4,630 | 9,250 |
| MiMo-V2.5 | 30,100 | 75,200 | 150,400 |
| MiMo-V2.5-Pro | 3,250 | 8,150 | 16,300 |
| MiniMax M3 | 1,400 | 3,500 | 7,000 |
| MiniMax M2.7 | 3,400 | 8,500 | 17,000 |
| MiniMax M2.5 | 6,300 | 15,900 | 31,800 |
| Qwen3.7 Max | 950 | 2,390 | 4,770 |
| Qwen3.7 Plus | 4,300 | 10,800 | 21,600 |
| Qwen3.6 Plus | 3,300 | 8,200 | 16,300 |
| DeepSeek V4 Pro | 3,450 | 8,550 | 17,150 |
| DeepSeek V4 Flash | 31,650 | 79,050 | 158,150 |

> All 7 models used by this agent collection (MiMo-V2.5, MiMo-V2.5-Pro, DeepSeek V4 Pro, Kimi K2.6, Qwen3.6 Plus, MiniMax M2.7, GLM-5.1) are included in the Go Plan.

## Configure Models

After installation, you need to configure models for each agent. Copy and send the following prompt to your OpenCode agent — it will handle the configuration automatically:

<details>
<summary>📋 Click to expand setup prompt</summary>

```
I just installed the opencode-agents collection (located at ~/.config/opencode/agents/).
Please help me complete the following configuration:

## Step 1: Check existing providers and models

Read ~/.config/opencode/opencode.json and list my currently configured providers and models.

## Step 2: Select models

Below are the default models for each agent in the collection. Based on my existing providers and models, select an available model for each agent (prefer more capable models):

| Agent | Default Model | Role |
|-------|---------------|------|
| Zero | opencode-go/mimo-v2.5 | Primary (rapid prototyping, multimodal) |
| Erribaba | Xianyu/mimo-v2.5-pro | Primary (production code, deep analysis) |
| api-designer | opencode-go/mimo-v2.5-pro | API design |
| architect | opencode-go/glm-5.1 | Architecture design |
| code-generator | opencode-go/mimo-v2.5-pro | Code generation |
| db-engineer | opencode-go/deepseek-v4-pro | Database engineering |
| debugger | opencode-go/deepseek-v4-pro | Debugging |
| devops | opencode-go/mimo-v2.5-pro | DevOps/CI-CD |
| doc-writer | opencode-go/qwen3.7-plus | Documentation |
| e2e-tester | opencode-go/mimo-v2.5-pro | End-to-end testing |
| executor | opencode-go/minimax-m2.7 | Command execution |
| frontend-dev | opencode-go/kimi-k2.6 | Frontend development |
| frontend-reviewer | opencode-go/mimo-v2.5 | Frontend review |
| git-assistant | opencode-go/mimo-v2.5 | Git workflow |
| migration | opencode-go/deepseek-v4-pro | Migration |
| perf-optimizer | opencode-go/mimo-v2.5-pro | Performance optimization |
| project-manager | opencode-go/qwen3.7-plus | Project management |
| refactorer | opencode-go/mimo-v2.5-pro | Code refactoring |
| research | opencode-go/qwen3.7-plus | Technical research |
| reviewer | opencode-go/deepseek-v4-pro | Code review |
| security-auditor | opencode-go/deepseek-v4-pro | Security audit |
| software-engineer | opencode-go/mimo-v2.5 | Full-stack implementation |
| test-writer | opencode-go/mimo-v2.5-pro | Test writing |
| ui-designer | opencode-go/kimi-k2.6 | UI design |
| validator | opencode-go/minimax-m2.7 | Validation |
| vision-dev | opencode-go/mimo-v2.5 | Visual development |

If I'm missing a provider, tell me which models need additional configuration.
If I already have the corresponding models, proceed to Step 3.

## Step 3: Update agent files

Read all .md files under ~/.config/opencode/agents/ and replace the `model:` field
in each file's frontmatter with the model you selected for that agent in Step 2.

## Step 4: Set primary agent

Set `default_agent` in ~/.config/opencode/opencode.json to "Erribaba".
(Change to "Zero" if the user prefers rapid prototyping mode)

## Step 5: Verify

List all agents and their assigned models to confirm configuration is complete.
```

</details>

## Directory Structure

```
agents/
├── Zero.md              # Primary agent (rapid prototyping, multimodal)
├── Erribaba.md          # Primary agent (production code, deep analysis)
├── architect.md         # Architecture design
├── code-generator.md    # Code generation
├── db-engineer.md       # Database engineering
├── debugger.md          # Debugging & diagnostics
├── devops.md            # DevOps/CI-CD
├── doc-writer.md        # Documentation writing
├── e2e-tester.md        # End-to-end testing
├── executor.md          # Command execution
├── frontend-dev.md      # Frontend development
├── frontend-reviewer.md # Frontend code review
├── git-assistant.md     # Git workflow
├── migration.md         # Migration expert
├── perf-optimizer.md    # Performance optimization
├── project-manager.md   # Project management
├── refactorer.md        # Code refactoring
├── research.md          # Technical research
├── reviewer.md          # Code review
├── security-auditor.md  # Security audit
├── software-engineer.md # Full-stack implementation
├── test-writer.md       # Test writing
├── ui-designer.md       # UI design & styling
├── validator.md         # Final validation
└── vision-dev.md        # Visual development
```

## Agent Overview

### Primary Agents

| File | Model | Description |
|------|-------|-------------|
| `Zero.md` | mimo-v2.5 | Rapid prototyping, multimodal input, lightweight tasks |
| `Erribaba.md` | mimo-v2.5-pro | Production code, complex algorithms, deep analysis |

### Subagents

| File | Responsibility | Writable | Executable |
|------|---------------|:--------:|:----------:|
| `api-designer.md` | API endpoint design, OpenAPI specs | ✓ | ✗ |
| `architect.md` | System design, module planning, tech selection | ✗ | ✗ |
| `code-generator.md` | High-quality code generation, bug fixes | ✓ | ✗ |
| `db-engineer.md` | Database schema, migrations, SQL optimization | ✓ | ✓ |
| `debugger.md` | Systematic bug isolation and fixing | ✓ | ✓ |
| `devops.md` | Docker, CI/CD, Kubernetes, deployment | ✓ | ✓ |
| `doc-writer.md` | Technical docs, API references, README | ✓ | ✗ |
| `e2e-tester.md` | Playwright/Cypress end-to-end tests | ✓ | ✗ |
| `executor.md` | Run commands, execute tests, build projects | ✓ | ✓ |
| `frontend-dev.md` | React/Vue/Svelte component development | ✓ | ✗ |
| `frontend-reviewer.md` | Frontend review, accessibility, performance | ✗ | ✗ |
| `git-assistant.md` | Commit messages, branch naming, PR descriptions | ✗ | ✗ |
| `migration.md` | Framework upgrades, DB migrations, tech stack switches | ✓ | ✓ |
| `perf-optimizer.md` | Performance profiling and optimization | ✗ | ✓ |
| `project-manager.md` | Requirement analysis, task breakdown, sprint planning | ✓ | ✗ |
| `refactorer.md` | Code refactoring, duplication removal, structure improvement | ✓ | ✗ |
| `research.md` | Documentation lookup, tech research | ✗ | ✗ |
| `reviewer.md` | Code review (logic, security, performance) | ✗ | ✗ |
| `security-auditor.md` | OWASP Top 10 security audit | ✗ | ✗ |
| `software-engineer.md` | Full-stack feature end-to-end implementation | ✓ | ✓ |
| `test-writer.md` | Unit, integration, and edge-case tests | ✓ | ✗ |
| `ui-designer.md` | CSS/Tailwind, responsive layouts, animations | ✓ | ✗ |
| `validator.md` | Final validation (build, tests, type check) | ✗ | ✓ |
| `vision-dev.md` | Design analysis, screenshot reproduction, visual dev | ✓ | ✗ |

## Usage

1. Set a primary agent (`Zero.md` or `Erribaba.md`) as your default
2. Describe your task in the conversation — the primary agent automatically delegates to the appropriate subagent
3. Subagents are invoked via `@agent-name` by the primary agent

### Choosing a Primary Agent

- **Erribaba** (recommended): Production code, complex tasks, deep analysis
- **Zero**: Rapid prototyping, multimodal input (images), lightweight tasks

Set in `~/.config/opencode/opencode.json`:
```json
{
  "default_agent": "Erribaba"
}
```

## File Format

Each agent file consists of YAML frontmatter + Markdown body:

```yaml
---
description: Chinese description (used by OpenCode for trigger matching)
mode: primary | subagent
model: provider/model-name
temperature: 0.0-1.0
tools:              # optional — restrict tool access
  write: false
  edit: false
  bash: false
---

<System prompt>
```

## Contributing

1. Fork the repository
2. Create a `Feat_xxx` branch
3. Commit your code
4. Create a Pull Request

## License

[MIT](LICENSE)
