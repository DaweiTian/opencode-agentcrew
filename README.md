# opencode-agentcrew

**开箱即用的 OpenCode 智能体团队，29 个专业角色覆盖全栈开发流程。**

## ✨ 特点

- **29 个专业智能体** — 架构设计、代码生成、调试诊断、测试编写、前端开发、安全审计等
- **结构化工作流** — 参考 MiMo Compose 模式，支持 brainstorm→plan→execute→review→merge 完整流程
- **两阶段审查** — 规范合规性审查 + 代码质量审查，确保实现符合需求且代码质量高
- **双主智能体** — Erribaba（生产代码）+ Zero（快速原型/多模态）
- **多模型协作** — MiMo-V2.5、GLM-5.1、Kimi K2.6、Qwen3.6 Plus、DeepSeek V4 Pro 等 7 个模型
- **图片处理** — 自动拦截粘贴图片，委托 vision-dev 分析
- **开箱即用** — 一条命令安装，自动配置

## 快速安装

### Linux / macOS

```bash
curl -fsSL https://gitee.com/aerlee/opencode-agents/raw/master/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://gitee.com/aerlee/opencode-agents/raw/master/install.ps1 | iex
```

> 脚本会自动下载所有智能体文件到 `~/.config/opencode/agents/`，并备份已有配置。

### 手动安装

```bash
git clone --depth 1 https://gitee.com/aerlee/opencode-agents.git /tmp/opencode-agents
cp /tmp/opencode-agents/agents/*.md ~/.config/opencode/agents/
rm -rf /tmp/opencode-agents
```

## 推荐：OpenCode Go 套餐

本智能体集合需要多个模型配合使用。推荐使用 [OpenCode Go 套餐](https://opencode.ai/go?ref=4BZQW1YPFK)，一次订阅即可使用全部 12 个模型，无需单独配置 API Key。

**优势：**
- 模型丰富：覆盖 12 个主流模型，满足不同智能体的需求
- 性价比高：相比单独购买 API，价格更优惠
- 开箱即用：无需配置多个 provider，`opencode-go/` 前缀直接可用

**套餐模型及配额：**

| 模型 | 每 5 小时 | 每周 | 每月 |
|------|----------|------|------|
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

> 本智能体集合的 29 个智能体使用的 7 个模型（MiMo-V2.5、MiMo-V2.5-Pro、DeepSeek V4 Pro、Kimi K2.6、Qwen3.6 Plus、MiniMax M2.7、GLM-5.1）全部包含在 Go 套餐中。

## 配置模型

安装后，需要为每个智能体配置你可用的模型。将以下提示词复制并发送给你的 OpenCode 智能体，它会自动完成配置：

<details>
<summary>📋 点击展开配置提示词</summary>

```
我刚刚安装了 opencode-agents 智能体集合（位于 ~/.config/opencode/agents/）。
请你帮我完成以下配置：

## 第一步：确认已有 provider 和模型

请读取 ~/.config/opencode/opencode.json，列出我当前已配置的 provider 和模型。

## 第二步：选择模型

以下是智能体集合中每个智能体默认使用的模型，请根据我已有的 provider 和模型，
为每个智能体选择一个可用的模型（优先选择能力更强的模型）：

| 智能体 | 默认模型 | 角色 |
|--------|----------|------|
| Zero | opencode-go/mimo-v2.5 | 主智能体（快速原型，多模态） |
| Erribaba | Xianyu/mimo-v2.5-pro | 主智能体（生产代码，深度分析） |
| api-designer | opencode-go/mimo-v2.5-pro | API 设计 |
| architect | opencode-go/glm-5.1 | 架构设计 |
| code-generator | opencode-go/mimo-v2.5-pro | 代码生成 |
| db-engineer | opencode-go/deepseek-v4-pro | 数据库工程 |
| debugger | opencode-go/deepseek-v4-pro | 调试诊断 |
| devops | opencode-go/mimo-v2.5-pro | DevOps/CI-CD |
| doc-writer | opencode-go/qwen3.7-plus | 文档编写 |
| e2e-tester | opencode-go/mimo-v2.5-pro | 端到端测试 |
| executor | opencode-go/minimax-m2.7 | 命令执行 |
| frontend-dev | opencode-go/kimi-k2.6 | 前端开发 |
| frontend-reviewer | opencode-go/mimo-v2.5 | 前端审查 |
| git-assistant | opencode-go/mimo-v2.5 | Git 工作流 |
| migration | opencode-go/deepseek-v4-pro | 迁移专家 |
| perf-optimizer | opencode-go/mimo-v2.5-pro | 性能优化 |
| plan-writer | opencode-go/mimo-v2.5-pro | 实现计划编写 |
| project-manager | opencode-go/qwen3.7-plus | 项目管理 |
| refactorer | opencode-go/mimo-v2.5-pro | 代码重构 |
| research | opencode-go/qwen3.7-plus | 信息研究 |
| reviewer | opencode-go/deepseek-v4-pro | 代码审查（Stage 2） |
| security-auditor | opencode-go/deepseek-v4-pro | 安全审计 |
| software-engineer | opencode-go/mimo-v2.5 | 全栈实现 |
| spec-reviewer | opencode-go/deepseek-v4-pro | 规范合规性审查（Stage 1） |
| test-writer | opencode-go/mimo-v2.5-pro | 测试编写 |
| ui-designer | opencode-go/kimi-k2.6 | UI 设计 |
| validator | opencode-go/minimax-m2.7 | 结果验证 |
| vision-dev | opencode-go/mimo-v2.5 | 视觉开发 |
| workflow-orchestrator | opencode-go/mimo-v2.5-pro | 工作流编排 |

如果我没有某个 provider，告诉我哪些模型需要额外配置。
如果我已有对应的模型，直接进入第三步。

## 第三步：更新智能体文件

读取 ~/.config/opencode/agents/ 下所有 .md 文件，将每个文件 frontmatter 中的 `model:`
字段替换为你在第二步中为该智能体选择的模型。

## 第四步：设置主智能体

将 ~/.config/opencode/opencode.json 中的 `default_agent` 设置为 "Erribaba"。
（如果用户更喜欢快速原型模式，改为 "Zero"）

## 第五步：验证

列出所有智能体及其使用的模型，确认配置完成。
```

</details>

## 目录结构

```
├── agents/                    # 智能体配置文件（29个）
│   ├── Zero.md              # 主智能体（快速原型，多模态）
│   ├── Erribaba.md          # 主智能体（生产代码，深度分析）
│   ├── architect.md         # 架构设计
│   ├── code-generator.md    # 代码生成
│   ├── db-engineer.md       # 数据库工程
│   ├── debugger.md          # 调试诊断
│   ├── devops.md            # DevOps/CI-CD
│   ├── doc-writer.md        # 文档编写
│   ├── e2e-tester.md        # 端到端测试
│   ├── executor.md          # 命令执行
│   ├── frontend-dev.md      # 前端开发
│   ├── frontend-reviewer.md # 前端审查
│   ├── git-assistant.md     # Git 工作流
│   ├── migration.md         # 迁移专家
│   ├── perf-optimizer.md    # 性能优化
│   ├── plan-writer.md       # 实现计划编写
│   ├── project-manager.md   # 项目管理
│   ├── refactorer.md        # 代码重构
│   ├── research.md          # 信息研究
│   ├── reviewer.md          # 代码审查（Stage 2）
│   ├── security-auditor.md  # 安全审计
│   ├── software-engineer.md # 全栈实现
│   ├── spec-reviewer.md     # 规范合规性审查（Stage 1）
│   ├── test-writer.md       # 测试编写
│   ├── ui-designer.md       # UI 设计
│   ├── validator.md         # 结果验证
│   ├── vision-dev.md        # 视觉开发
│   └── workflow-orchestrator.md # 工作流编排
├── references/                # 参考文档（OpenCode References 功能）
│   └── workflow/            # 工作流相关文档
│       └── WORKFLOW-QUICKREF.md # 结构化工作流快速参考
├── plugins/                   # OpenCode 插件
│   └── image-paste-saver.js # 图片粘贴保存插件
├── install.sh                 # Linux/macOS 一键安装脚本
├── install.ps1                # Windows 一键安装脚本
├── AGENTS.md                  # 代理配置和使用指南
├── README.md                  # 项目说明
├── WORKFLOW-QUICKREF.md       # 工作流快速参考（项目根目录副本）
└── LICENSE                    # MIT 许可证
```

## 智能体一览

### 主智能体（Primary）

| 文件 | 模型 | 说明 |
|------|------|------|
| `Zero.md` | mimo-v2.5 | 快速原型、多模态输入、轻量级任务 |
| `Erribaba.md` | mimo-v2.5-pro | 生产代码、复杂算法、深度分析 |

### 子智能体（Subagent）

| 文件 | 职责 | 可写 | 可执行 |
|------|------|:----:|:------:|
| `api-designer.md` | API 端点设计、OpenAPI 规范 | ✓ | ✗ |
| `architect.md` | 系统设计、模块划分、技术选型 | ✗ | ✗ |
| `code-generator.md` | 高质量代码生成、bug 修复 | ✓ | ✗ |
| `db-engineer.md` | 数据库 Schema、Migration、SQL 优化 | ✓ | ✓ |
| `debugger.md` | 系统化定位和修复代码缺陷 | ✓ | ✓ |
| `devops.md` | Docker、CI/CD、Kubernetes、部署 | ✓ | ✓ |
| `doc-writer.md` | 技术文档、API 参考、README | ✓ | ✗ |
| `e2e-tester.md` | Playwright/Cypress 端到端测试 | ✓ | ✗ |
| `executor.md` | 运行命令、执行测试、构建项目 | ✓ | ✓ |
| `frontend-dev.md` | React/Vue/Svelte 组件开发 | ✓ | ✗ |
| `frontend-reviewer.md` | 前端审查、无障碍合规、性能 | ✗ | ✗ |
| `git-assistant.md` | 提交消息、分支命名、PR 描述 | ✗ | ✗ |
| `migration.md` | 框架升级、数据库迁移、技术栈切换 | ✓ | ✓ |
| `perf-optimizer.md` | 性能分析与优化 | ✗ | ✓ |
| `plan-writer.md` | 实现计划编写、TDD 任务分解 | ✓ | ✗ |
| `project-manager.md` | 需求分析、任务拆解、Sprint 规划 | ✓ | ✗ |
| `refactorer.md` | 代码重构、消除重复、改善结构 | ✓ | ✗ |
| `research.md` | 查找文档、调研技术方案 | ✗ | ✗ |
| `reviewer.md` | 代码审查（Stage 2：代码质量） | ✗ | ✗ |
| `security-auditor.md` | OWASP Top 10 安全审计 | ✗ | ✗ |
| `software-engineer.md` | 全栈功能端到端实现 | ✓ | ✓ |
| `spec-reviewer.md` | 规范合规性审查（Stage 1） | ✗ | ✗ |
| `test-writer.md` | 单元/集成/边界测试 | ✓ | ✗ |
| `ui-designer.md` | CSS/Tailwind/响应式布局/动画 | ✓ | ✗ |
| `validator.md` | 最终验证（构建/测试/类型检查） | ✗ | ✓ |
| `vision-dev.md` | 设计稿分析、截图还原、视觉开发 | ✓ | ✗ |
| `workflow-orchestrator.md` | 工作流编排、多阶段任务管理 | ✓ | ✓ |

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
2. **阶段 2：代码质量审查**（@reviewer）— 验证代码是否良好构建

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
对于复杂任务，使用 `@workflow-orchestrator` 管理完整工作流。它协调其他代理按正确顺序执行，并确保质量门控。

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

## 使用方式

1. 主智能体（`Zero.md` 或 `Erribaba.md`）作为默认智能体
2. 在对话中直接描述任务，主智能体会自动调度对应的子智能体
3. 子智能体通过 `@agent-name` 方式被主智能体调用

### 选择主智能体

- **Erribaba**（推荐）：适合生产代码、复杂任务、需要深度分析的场景
- **Zero**：适合快速原型、多模态输入（图片）、轻量级任务

在 `~/.config/opencode/opencode.json` 中设置：
```json
{
  "default_agent": "Erribaba"
}
```

## 配置格式

每个智能体文件由 YAML frontmatter + Markdown 正文组成：

```yaml
---
description: 中文描述（OpenCode 用于匹配触发场景）
mode: primary | subagent
model: provider/model-name
temperature: 0.0-1.0
tools:              # 可选，限制工具权限
  write: false
  edit: false
  bash: false
---

<系统提示词>
```

## 参与贡献

1. Fork 本仓库
2. 新建 `Feat_xxx` 分支
3. 提交代码
4. 新建 Pull Request

## 许可证

[MIT](LICENSE)
