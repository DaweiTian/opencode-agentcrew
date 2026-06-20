# opencode-agents 一键安装脚本 (Windows PowerShell)
# 用法: irm https://gitee.com/aerlee/opencode-agents/raw/master/install.ps1 | iex

$ErrorActionPreference = "Stop"

$RepoUrl = "https://gitee.com/aerlee/opencode-agents.git"
$TargetDir = "$env:USERPROFILE\.config\opencode\agents"
$ReferencesDir = "$env:USERPROFILE\.config\opencode\references"
$BackupDir = "$env:USERPROFILE\.config\opencode\agents-备份-$(Get-Date -Format 'yyyyMMddHHmmss')"
$TempDir = Join-Path $env:TEMP "opencode-agents-$(Get-Random)"

Write-Host "🚀 opencode-agents 安装脚本" -ForegroundColor Cyan
Write-Host "================================"

# 检查 git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 需要安装 git。请访问 https://git-scm.com/download/win 下载安装。" -ForegroundColor Red
    exit 1
}

# 备份已有 agents
if (Test-Path $TargetDir) {
    Write-Host "📦 备份已有 agents 到: $BackupDir"
    Copy-Item -Path $TargetDir -Destination $BackupDir -Recurse
}

# 克隆仓库到临时目录
Write-Host "📥 正在下载 agents..."
git clone --depth 1 $RepoUrl $TempDir 2>$null

# 创建目标目录
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}
if (-not (Test-Path $ReferencesDir)) {
    New-Item -ItemType Directory -Path $ReferencesDir -Force | Out-Null
}

# 复制 agents 文件
Write-Host "📂 安装 agents 到: $TargetDir"
Copy-Item -Path "$TempDir\agents\*.md" -Destination $TargetDir -Force

# 复制 references 文件
if (Test-Path "$TempDir\references") {
    Write-Host "📚 安装 references 到: $ReferencesDir"
    Copy-Item -Path "$TempDir\references\*" -Destination $ReferencesDir -Recurse -Force
}

# 复制 plugins 文件
$PluginDir = "$env:USERPROFILE\.config\opencode\plugins"
$PluginFiles = Get-ChildItem -Path "$TempDir\plugins" -Filter "*.js" -ErrorAction SilentlyContinue
$PluginFiles += Get-ChildItem -Path "$TempDir\plugins" -Filter "*.ts" -ErrorAction SilentlyContinue
if ($PluginFiles.Count -gt 0) {
    if (-not (Test-Path $PluginDir)) {
        New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null
    }
    Write-Host "🔌 安装 plugins 到: $PluginDir"
    $PluginFiles | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $PluginDir -Force
    }
}

# 清理
Remove-Item -Path $TempDir -Recurse -Force

# 配置环境变量以启用异步子代理处理
Write-Host "⚙️  配置环境变量..." -ForegroundColor Cyan

# 设置用户环境变量
$CurrentValue = [Environment]::GetEnvironmentVariable("OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS", "User")
if (-not $CurrentValue) {
    [Environment]::SetEnvironmentVariable("OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS", "true", "User")
    $env:OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true"
    Write-Host "  ✅ 已添加用户环境变量 OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS" -ForegroundColor Green
    Write-Host "  ℹ️  重启终端后永久生效" -ForegroundColor Yellow
} else {
    Write-Host "  ℹ️  环境变量已存在"
}

# 统计
$AgentCount = (Get-ChildItem -Path $TargetDir -Filter "*.md").Count
$ReferenceCount = (Get-ChildItem -Path $ReferencesDir -Filter "*.md" -Recurse).Count
Write-Host ""
Write-Host "✅ 安装完成！共 $AgentCount 个智能体，$ReferenceCount 个参考文档" -ForegroundColor Green
Write-Host ""
Write-Host "已安装的智能体:"
Write-Host "  主智能体:"
@("Zero", "Erribaba") | ForEach-Object {
    $f = Join-Path $TargetDir "$_.md"
    if (Test-Path $f) { Write-Host "    - $_" }
}
Write-Host "  子智能体:"
Get-ChildItem -Path $TargetDir -Filter "*.md" | Where-Object { $_.Name -notin @("Zero.md", "Erribaba.md") } | ForEach-Object {
    Write-Host "    - $($_.BaseName)"
}

Write-Host ""
Write-Host "已安装的参考文档:"
Get-ChildItem -Path $ReferencesDir -Filter "*.md" -Recurse | ForEach-Object {
    Write-Host "    - $($_.BaseName)"
}

Write-Host ""
Write-Host "📋 下一步：" -ForegroundColor Yellow
Write-Host "  1. 编辑 $env:USERPROFILE\.config\opencode\opencode.json 配置模型和 provider"
Write-Host "  2. 在 opencode.json 中设置 `"default_agent`" 选择主智能体"
Write-Host "  3. 在 opencode.json 中配置 `"references`" 指向参考文档目录"
Write-Host "  4. 启动 opencode 开始使用"
Write-Host ""
Write-Host "⚡ 已启用异步子代理处理功能，主智能体现在可以并行处理多个子任务！" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 提示：将下方提示词复制到你的 OpenCode 智能体中，" -ForegroundColor Yellow
Write-Host "   它会帮你自动配置模型并更新智能体文件。"
Write-Host ""
Write-Host "================================"

$Prompt = @"
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
"@

Write-Host $Prompt
Write-Host ""
