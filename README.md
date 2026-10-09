# opencode-agentcrew

<div align="right">

**[English](README.en.md)** | **中文**

</div>

**开箱即用的 OpenCode 智能体团队，38 个专业角色覆盖全栈开发流程。**

## 📑 目录

- [快速安装](#快速安装)
- [推荐：OpenCode Go 套餐](#推荐opencode-go-套餐)
- [配置模型](#配置模型)
- [目录结构](#目录结构)
- [智能体一览](#智能体一览)
- [结构化工作流](#结构化工作流)
- [使用方式](#使用方式)
- [配置格式](#配置格式)
- [参与贡献](#参与贡献)
- [许可证](#许可证)

## ✨ 特点

- **38 个专业智能体** — 架构设计、代码生成、调试诊断、测试编写、前端开发、安全审计等
- **智能调度** — `smart-router` 根据任务复杂度、领域、成本自动调度 skill 与模型
- **分层子智能体** — 8 个高频角色提供 `-lite` 轻量版（`mimo-v2.6-flash`），简单任务最快最省
- **结构化工作流** — 参考 MiMo Compose 模式，支持 brainstorm→plan→execute→review→merge 完整流程
- **两阶段审查** — 规范合规性审查 + 代码质量审查，确保实现符合需求且代码质量高
- **三主智能体** — smart-router（智能调度）+ Erribaba（生产代码）+ Zero（快速原型/多模态）
- **多模型协作** — MiMo-V2.6-Flash、MiMo-V2.6-Pro、DeepSeek V4.1 Flash、GLM-5.2、Kimi K2.7 Code、Qwen3.8 Flash、MiniMax M3、LongCat 2.5 Preview Free、Step 5 Preview Free 共 9 个模型
- **图片处理** — 三个主智能体均为原生全模态，粘贴图片直接分析；磁盘上的图片文件可交 vision-dev 处理
- **开箱即用** — 一条命令安装，自动配置

## 快速安装

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/DaweiTian/opencode-agentcrew/master/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/DaweiTian/opencode-agentcrew/master/install.ps1 | iex
```

> 安装脚本会自动完成三件事：
>
> 1. **安装智能体** — 下载 `agents/*.md` 到 `~/.config/opencode/agents/`（已有的 agents 目录会先备份到 `~/.config/opencode/agents-备份-<时间戳>`）；
> 2. **安装参考文档** — 复制 `references/*` 到 `~/.config/opencode/references/`（含结构化工作流快速参考 WORKFLOW-QUICKREF 与三主智能体共享的并行任务协议 parallel-task-management）；
> 3. **启用后台子智能体并行** — 向 `~/.bashrc` 或 `~/.zshrc` 追加 `export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true`（Windows 脚本改为设置同名用户级环境变量）。该环境变量用于启用主智能体后台并行派发子任务的能力；如需撤销，删除 shell 配置文件末尾对应的 export 行（Windows：移除该用户环境变量）后重开终端即可。

### 手动安装

```bash
git clone --depth 1 https://github.com/DaweiTian/opencode-agentcrew.git /tmp/opencode-agents

# 1. 复制智能体文件
mkdir -p ~/.config/opencode/agents
cp /tmp/opencode-agents/agents/*.md ~/.config/opencode/agents/

# 2. 复制参考文档（结构化工作流快速参考等）
mkdir -p ~/.config/opencode/references
cp -r /tmp/opencode-agents/references/* ~/.config/opencode/references/

# 3. 启用后台子智能体并行（zsh 用户请改用 ~/.zshrc）
echo 'export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true' >> ~/.bashrc
source ~/.bashrc

rm -rf /tmp/opencode-agents
```

> Windows（PowerShell）手动安装：目标路径为 `$env:USERPROFILE\.config\opencode\`，环境变量改用
> `[Environment]::SetEnvironmentVariable("OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS", "true", "User")` 设置。

最后，在 `~/.config/opencode/opencode.json` 中添加 `references` 字段指向参考文档目录——**缺少此配置时，结构化工作流参考文档不会生效**：

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

## 推荐：OpenCode Go 套餐

本智能体集合需要多个模型配合使用。推荐使用 [OpenCode Go 套餐](https://opencode.ai/go?ref=4BZQW1YPFK)，一次订阅即可使用套餐内全部模型（官方共 36 个模型），无需单独配置 API Key。

**优势：**
- 模型丰富：官方套餐覆盖 36 个模型，本集合使用的全部 9 个模型均包含于 Go 套餐
- 性价比高：相比单独购买 API，价格更优惠
- 开箱即用：无需配置多个 provider，按 `opencode-go/<model-id>` 格式直接可用

> 本集合 38 个智能体使用的 9 个模型（MiMo-V2.6-Flash、MiMo-V2.6-Pro、DeepSeek V4.1 Flash、GLM-5.2、Kimi K2.7 Code、Qwen3.8 Flash、MiniMax M3、LongCat 2.5 Preview Free、Step 5 Preview Free）已全部确认包含于 Go 套餐。其中 LongCat 2.5 Preview Free 与 Step 5 Preview Free 为**限时免费**模型（价格 $0、用量无限，活动结束后需更换）。
> 本集合选用的模型均为**国产模型**，国内可直接使用，无需 GPT/Claude/Grok 等国外模型。
>
> 各模型配额由官方维护且变动频繁，本 README 不保留本地配额快照，请以官方页面为准：
> - 套餐总览：<https://opencode.ai/go>
> - 用量限制：<https://opencode.ai/docs/go#usage-limits>

## 配置模型

安装后，需要为每个智能体配置你可用的模型。将以下提示词复制并发送给你的 OpenCode 智能体，它会自动完成配置：

<details>
<summary>📋 点击展开配置提示词</summary>

````
--- 复制以下提示词发送给你的 OpenCode 智能体 ---

我刚刚安装了 opencode-agents 智能体集合（位于 ~/.config/opencode/agents/）。
请你帮我完成以下配置：

## 第一步：确认已有 provider 和模型

请读取 ~/.config/opencode/opencode.json，列出我当前已配置的 provider 和模型。

## 第二步：选择模型

以下是智能体集合中每个智能体默认使用的模型，请根据我已有的 provider 和模型，
为每个智能体选择一个可用的模型（优先选择能力更强的模型）：

| 智能体 | 默认模型 | 角色 |
|--------|----------|------|
| smart-router | opencode-go/mimo-v2.6-flash | 主智能体（智能调度，推荐默认） |
| Zero | opencode-go/mimo-v2.6-flash | 主智能体（快速原型，多模态） |
| Erribaba | opencode-go/mimo-v2.6-pro | 主智能体（生产代码，深度分析） |
| api-designer | opencode-go/mimo-v2.6-pro | API 设计 |
| architect | opencode-go/glm-5.2 | 架构设计 |
| code-generator | opencode-go/mimo-v2.6-pro | 代码生成 |
| code-generator-lite | opencode-go/mimo-v2.6-flash | 代码生成（轻量版） |
| db-engineer | opencode-go/deepseek-v4.1-flash | 数据库工程 |
| debugger | opencode-go/deepseek-v4.1-flash | 调试诊断 |
| debugger-lite | opencode-go/mimo-v2.6-flash | 调试诊断（轻量版） |
| devops | opencode-go/mimo-v2.6-flash | DevOps/CI-CD |
| doc-writer | opencode-go/qwen3.8-flash | 文档编写 |
| doc-writer-lite | opencode-go/mimo-v2.6-flash | 文档编写（轻量版） |
| e2e-tester | opencode-go/mimo-v2.6-flash | 端到端测试 |
| executor | opencode-go/minimax-m3 | 命令执行 |
| frontend-dev | opencode-go/kimi-k2.7-code | 前端开发 |
| frontend-dev-lite | opencode-go/mimo-v2.6-flash | 前端开发（轻量版） |
| frontend-reviewer | opencode-go/mimo-v2.6-flash | 前端审查 |
| git-assistant | opencode-go/longcat-2.5-preview-free | Git 工作流 |
| migration | opencode-go/deepseek-v4.1-flash | 迁移专家 |
| perf-optimizer | opencode-go/mimo-v2.6-pro | 性能优化 |
| plan-writer | opencode-go/mimo-v2.6-pro | 实现计划编写 |
| project-manager | opencode-go/qwen3.8-flash | 项目管理 |
| refactorer | opencode-go/mimo-v2.6-pro | 代码重构 |
| refactorer-lite | opencode-go/mimo-v2.6-flash | 代码重构（轻量版） |
| research | opencode-go/qwen3.8-flash | 信息研究 |
| research-lite | opencode-go/mimo-v2.6-flash | 信息研究（轻量版） |
| reviewer | opencode-go/deepseek-v4.1-flash | 代码审查（Stage 2） |
| reviewer-lite | opencode-go/mimo-v2.6-flash | 代码审查（轻量版） |
| security-auditor | opencode-go/deepseek-v4.1-flash | 安全审计 |
| software-engineer | opencode-go/mimo-v2.6-flash | 全栈实现 |
| spec-reviewer | opencode-go/deepseek-v4.1-flash | 规范合规性审查（Stage 1） |
| test-writer | opencode-go/mimo-v2.6-pro | 测试编写 |
| test-writer-lite | opencode-go/mimo-v2.6-flash | 测试编写（轻量版） |
| ui-designer | opencode-go/kimi-k2.7-code | UI 设计 |
| validator | opencode-go/step-5-preview-free | 结果验证 |
| vision-dev | opencode-go/mimo-v2.6-flash | 视觉开发 |
| workflow-orchestrator | opencode-go/mimo-v2.6-pro | 工作流编排 |

如果我没有某个 provider，告诉我哪些模型需要额外配置。
如果我已有对应的模型，直接进入第三步。

## 第三步：更新智能体文件

读取 ~/.config/opencode/agents/ 下所有 .md 文件，将每个文件 frontmatter 中的 `model:`
字段替换为你在第二步中为该智能体选择的模型。

## 第四步：设置主智能体

将 ~/.config/opencode/opencode.json 中的 `default_agent` 设置为 "smart-router"（推荐默认；生产代码模式用 "Erribaba"，快速原型用 "Zero"）。

## 第五步：配置参考文档

在 ~/.config/opencode/opencode.json 中添加 references 配置，指向工作流文档：

```json
"references": {
  "workflow-docs": {
    "path": "~/.config/opencode/references/workflow",
    "description": "智能体工作流文档和快速参考，包含结构化工作流指南、代理配置和最佳实践",
    "hidden": false
  }
}
```

## 第六步：验证

列出所有智能体及其使用的模型，确认配置完成。
验证 references 配置是否正确。
````

</details>

## 目录结构

```
opencode-agentcrew/
├── agents/                      # 智能体配置文件（38 个）
│   ├── smart-router.md          # 主智能体（智能调度，推荐默认）
│   ├── Zero.md                  # 主智能体（快速原型，多模态）
│   ├── Erribaba.md              # 主智能体（生产代码，深度分析）
│   ├── api-designer.md          # API 设计
│   ├── architect.md             # 架构设计
│   ├── code-generator.md        # 代码生成
│   ├── code-generator-lite.md   # 代码生成（轻量版）
│   ├── db-engineer.md           # 数据库工程
│   ├── debugger.md              # 调试诊断
│   ├── debugger-lite.md         # 调试诊断（轻量版）
│   ├── devops.md                # DevOps/CI-CD
│   ├── doc-writer.md            # 文档编写
│   ├── doc-writer-lite.md       # 文档编写（轻量版）
│   ├── e2e-tester.md            # 端到端测试
│   ├── executor.md              # 命令执行
│   ├── frontend-dev.md          # 前端开发
│   ├── frontend-dev-lite.md     # 前端开发（轻量版）
│   ├── frontend-reviewer.md     # 前端审查
│   ├── git-assistant.md         # Git 工作流
│   ├── migration.md             # 迁移专家
│   ├── perf-optimizer.md        # 性能优化
│   ├── plan-writer.md           # 实现计划编写
│   ├── project-manager.md       # 项目管理
│   ├── refactorer.md            # 代码重构
│   ├── refactorer-lite.md       # 代码重构（轻量版）
│   ├── research.md              # 信息研究
│   ├── research-lite.md         # 信息研究（轻量版）
│   ├── reviewer.md              # 代码审查（Stage 2）
│   ├── reviewer-lite.md         # 代码审查（轻量版）
│   ├── security-auditor.md      # 安全审计
│   ├── software-engineer.md     # 全栈实现
│   ├── spec-reviewer.md         # 规范合规性审查（Stage 1）
│   ├── test-writer.md           # 测试编写
│   ├── test-writer-lite.md      # 测试编写（轻量版）
│   ├── ui-designer.md           # UI 设计
│   ├── validator.md             # 结果验证
│   ├── vision-dev.md            # 视觉开发
│   └── workflow-orchestrator.md # 工作流编排
├── references/                  # 参考文档（OpenCode References 功能）
│   └── workflow/                # 工作流相关文档
│       ├── WORKFLOW-QUICKREF.md        # 结构化工作流快速参考
│       └── parallel-task-management.md # 三主智能体共享的并行任务协议
├── .gitignore                   # Git 忽略规则
├── AGENTS.md                    # 代理配置和使用指南
├── install.sh                   # Linux/macOS 一键安装脚本
├── install.ps1                  # Windows 一键安装脚本
├── LICENSE                      # MIT 许可证
├── README.en.md                 # 项目说明（英文）
└── README.md                    # 项目说明（中文）
```

## 智能体一览

### 主智能体（Primary）

| 文件 | 模型 | 说明 |
|------|------|------|
| `smart-router.md` | mimo-v2.6-flash | 智能调度（复杂度 + 领域 + 成本路由），推荐默认 |
| `Zero.md` | mimo-v2.6-flash | 快速原型、多模态输入、轻量级任务 |
| `Erribaba.md` | mimo-v2.6-pro | 生产代码、复杂算法、深度分析 |

### 子智能体（Subagent）

| 文件 | 职责 | 可写 | 可执行 | 可派发 |
|------|------|:----:|:------:|:------:|
| `api-designer.md` | API 端点设计、OpenAPI 规范 | ✓ | ✗ | ✗ |
| `architect.md` | 系统设计、模块划分、技术选型 | ✗ | ✗ | ✗ |
| `code-generator.md` | 高质量代码生成、bug 修复 | ✓ | ✗ | ✗ |
| `db-engineer.md` | 数据库 Schema、Migration、SQL 优化 | ✓ | ✓ | ✗ |
| `debugger.md` | 系统化定位和修复代码缺陷 | ✓ | ✓ | ✗ |
| `devops.md` | Docker、CI/CD、Kubernetes、部署 | ✓ | ✓ | ✗ |
| `doc-writer.md` | 技术文档、API 参考、README | ✓ | ✗ | ✗ |
| `e2e-tester.md` | Playwright/Cypress 端到端测试 | ✓ | ✗ | ✗ |
| `executor.md` | 运行命令、执行测试、构建项目 | ✓ | ✓ | ✗ |
| `frontend-dev.md` | React/Vue/Svelte 组件开发 | ✓ | ✗ | ✗ |
| `frontend-reviewer.md` | 前端审查、无障碍合规、性能 | ✗ | ✗ | ✗ |
| `git-assistant.md` | 提交消息、分支命名、PR 描述 | ✗ | ✗ | ✗ |
| `migration.md` | 框架升级、数据库迁移、技术栈切换 | ✓ | ✓ | ✗ |
| `perf-optimizer.md` | 性能分析与优化 | ✗ | ✓ | ✗ |
| `plan-writer.md` | 实现计划编写、TDD 任务分解 | 部分* | ✗ | ✗ |
| `project-manager.md` | 需求分析、任务拆解、Sprint 规划 | 部分* | ✗ | ✗ |
| `refactorer.md` | 代码重构、消除重复、改善结构 | ✓ | ✗ | ✗ |
| `research.md` | 查找文档、调研技术方案 | ✗ | ✗ | ✗ |
| `reviewer.md` | 代码审查（Stage 2：代码质量） | ✗ | ✗ | ✗ |
| `security-auditor.md` | OWASP Top 10 安全审计 | ✗ | ✗ | ✗ |
| `software-engineer.md` | 全栈功能端到端实现 | ✓ | ✓ | ✗ |
| `spec-reviewer.md` | 规范合规性审查（Stage 1） | ✗ | ✗ | ✗ |
| `test-writer.md` | 单元/集成/边界测试 | ✓ | ✗ | ✗ |
| `ui-designer.md` | CSS/Tailwind/响应式布局/动画 | ✓ | ✗ | ✗ |
| `validator.md` | 最终验证（构建/测试/类型检查） | ✗ | ✓ | ✗ |
| `vision-dev.md` | 设计稿分析、截图还原、视觉开发 | ✓ | ✗ | ✗ |
| `workflow-orchestrator.md` | 工作流编排计划输出（只读顾问，不直接派发子智能体） | ✗ | ✗ | ✗ |

> \* **部分可写**：仅可写入 `~/.opencode/plan/` 目录（目录级 allow 例外，置于通配 deny 之后生效）；其余路径只读，且不可执行命令。
> **可派发**：全部 35 个子智能体（含 Lite 版）均在 frontmatter 中 deny `subagent`，即不可再向下派发；只有 3 个主智能体（smart-router、Zero、Erribaba）可派发子智能体。

### 子智能体（Lite 轻量版）

全部使用 `mimo-v2.6-flash`，由 `smart-router` 按复杂度自动选择。权限规则与对应标准版一致（均 deny `subagent`，不可再派发）。

| 文件 | 标准版 | 职责 |
|------|--------|------|
| `code-generator-lite.md` | `code-generator` | 简单代码生成、样板代码 |
| `reviewer-lite.md` | `reviewer` | 快速 diff 审查（明显问题） |
| `debugger-lite.md` | `debugger` | 简单可复现 bug |
| `test-writer-lite.md` | `test-writer` | 单函数单元测试 |
| `doc-writer-lite.md` | `doc-writer` | Docstring、README 段落、changelog |
| `frontend-dev-lite.md` | `frontend-dev` | 简单展示型组件 |
| `research-lite.md` | `research` | 事实查证（API、语法） |
| `refactorer-lite.md` | `refactorer` | 重命名、提取、条件简化 |

## 结构化工作流

本智能体集合支持参考 MiMo Compose 模式的结构化开发工作流，适合复杂、多步骤的任务。

### 工作流阶段

```
用户需求
    ↓
[阶段 1: 构思] — architect, research（可选但推荐）
    ↓
[阶段 2: 计划] — plan-writer, project-manager（3+ 步骤任务必需）
    ↓
[阶段 3: 执行] — test-writer, code-generator, executor（TDD 循环）
    ↓
[阶段 4: 审查] — spec-reviewer（Stage 1）→ reviewer（Stage 2）
    ↓
[阶段 5: 合并] — validator, git-assistant
```

### 关键概念

#### 两阶段审查
审查阶段使用两阶段流程：
1. **阶段 1：规范合规性审查**（`@spec-reviewer`）— 验证实现是否符合需求
2. **阶段 2：代码质量审查**（`@reviewer`）— 验证代码是否良好构建

**重要：** 阶段 1 必须通过后才能运行阶段 2。

#### TDD 集成
执行阶段遵循测试驱动开发：
1. 编写失败测试（`@test-writer`）
2. 验证测试失败（`@executor`）
3. 编写最小实现（`@code-generator`）
4. 验证测试通过（`@executor`）
5. 重构（如需要）
6. 提交（`@git-assistant`）

#### 工作流编排
对于复杂任务，使用 `@workflow-orchestrator` 输出完整的工作流编排计划（阶段划分、派发顺序、阶段屏障与质量门控）。它是只读顾问（deny edit + shell + subagent），由主智能体按计划依次派发子智能体执行。

### 何时使用结构化工作流

| 任务类型 | 推荐方式 |
|---------|---------|
| 简单、单步骤 | 直接处理 |
| 2-3 步骤、需求清晰 | 直接实现 + 审查 |
| 3+ 步骤、复杂 | 完整结构化工作流 |
| 新功能、需求模糊 | 完整工作流 + 构思 |
| Bug 修复、问题清晰 | 跳过构思，使用计划 + 执行 |

### 代理在工作流中的角色

| 阶段 | 主要代理 | 支持代理 |
|------|---------|---------|
| 构思 | `architect`, `research` | `project-manager` |
| 计划 | `plan-writer`, `project-manager` | `architect` |
| 执行 | `test-writer`, `code-generator` | `executor`, `git-assistant` |
| 审查 | `spec-reviewer`, `reviewer` | `security-auditor`, `frontend-reviewer` |
| 合并 | `validator` | `git-assistant`, `devops` |

> 📖 详见 [WORKFLOW-QUICKREF](references/workflow/WORKFLOW-QUICKREF.md)。一键安装脚本会自动将 `references/` 装入 `~/.config/opencode/references/`；还需在 `~/.config/opencode/opencode.json` 中配置 `references` 字段（见[手动安装](#手动安装)），结构化工作流参考文档才会生效。

## 使用方式

1. **推荐：`smart-router` 作为默认主智能体** — 自动按复杂度、领域、成本调度 skill 与模型
2. 也可手动切换到 `Erribaba`（生产代码深度分析）或 `Zero`（快速原型/多模态）
3. 在对话中直接描述任务，主智能体会自动调度对应的子智能体
4. 子智能体通过 `@agent-name` 方式被主智能体调用

### 选择主智能体

> 三个主智能体均为原生全模态，对话中粘贴的图片可直接由任一主智能体分析，无需专门切换；磁盘上的图片文件（设计稿、截图等）可委托 vision-dev 处理。

- **smart-router**（推荐）：智能调度，简单任务用 lite 版（最快最省），复杂任务组合多智能体
- **Erribaba**：适合生产代码、复杂任务、需要深度分析的场景
- **Zero**：适合快速原型、轻量级任务

在 `~/.config/opencode/opencode.json` 中设置：
```json
{
  "default_agent": "smart-router"
}
```

### 智能调度策略

`smart-router` 沿三个维度路由：

| 维度 | 取值 | 作用 |
|------|------|------|
| **领域** | frontend / backend / fullstack / db / docs / review / security / debug / test / e2e / research / refactor / perf / api / arch / plan / pm / git / migration / devops / exec / validate / vision / workflow | 选择子智能体 |
| **复杂度** | simple / medium / complex | simple 且该领域存在 `-lite` 变体时走 `-lite` 版，否则一律标准版；complex 组合多智能体 |
| **成本** | 默认偏向便宜模型 | 只有明确需要时才升级到 `mimo-v2.6-pro` / `glm-5.2` / `kimi-k2.7-code` |

**手动覆盖**：用户可以显式指定 `@agent-name` 或模型（如 "用 mimo-v2.6-pro 实现"），smart-router 会跳过智能调度直接执行。

## 配置格式

每个智能体文件由 YAML frontmatter + Markdown 正文组成：

```yaml
---
description: 中文描述（OpenCode 用于匹配触发场景）
mode: primary | subagent
model: provider/model-name
permissions:        # 主智能体可省略（省略则允许所有工具）；子智能体必须声明且包含 subagent deny
  - action: edit
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: deny
  - action: subagent    # 所有子智能体必填 — 只有主智能体可派发
    resource: "*"
    effect: deny
---

<系统提示词>
```

> ℹ️ 2026-09 起本仓库已从 V1 的 `tools:` 字段全面迁移到 V2 的 `permissions:` 列表（V1 `tools:` 在 OpenCode V2 中会被静默忽略）。`edit` 动作覆盖 edit/write/patch 三种文件修改工具，`shell` 动作覆盖命令执行，`subagent` 动作控制能否再向下派发子智能体；多条规则同时命中时以最后一条为准。35 个子智能体全部 deny `subagent`，只有 3 个主智能体可派发。

## 参与贡献

1. Fork 本仓库
2. 新建 `Feat_xxx` 分支
3. 提交代码
4. 新建 Pull Request

## 许可证

[MIT](LICENSE)
