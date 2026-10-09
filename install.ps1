# opencode-agents 一键安装脚本 (Windows PowerShell)
# 用法: irm https://raw.githubusercontent.com/DaweiTian/opencode-agentcrew/master/install.ps1 | iex
# 注: URL 中的 raw/master 分支已核实——GitHub 仓库默认分支为 master（2026-10-09 推送验证）

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/DaweiTian/opencode-agentcrew.git"
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

# 配置提示词（安装结束时输出给用户复制）。
# 其"第二步"表格同时是本脚本内嵌模型表的唯一数据源，下方安装校验会解析它与 agents/*.md 的 frontmatter 比对。
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
"@

# 统计（@() 包裹保证空目录时计数为 0；-ErrorAction SilentlyContinue 显式处理缺失目录）
$AgentCount = @(Get-ChildItem -Path $TargetDir -Filter "*.md" -File -ErrorAction SilentlyContinue).Count
$ReferenceCount = @(Get-ChildItem -Path $ReferencesDir -Filter "*.md" -File -Recurse -ErrorAction SilentlyContinue).Count
Write-Host ""
Write-Host "✅ 安装完成！共 $AgentCount 个智能体，$ReferenceCount 个参考文档" -ForegroundColor Green

# ============================================
# 安装一致性校验（仅醒目告警，不中断安装）
# ============================================
$ExpectedAgentCount = 38

# 1) 数量断言：动态统计已安装 .md 数量，与内置期望值 38 比对
if ($AgentCount -ne $ExpectedAgentCount) {
    Write-Host ""
    Write-Host "⚠️  =============================================" -ForegroundColor Yellow
    Write-Host "⚠️  WARNING: 智能体数量与预期不符！" -ForegroundColor Yellow
    Write-Host "⚠️  预期 $ExpectedAgentCount 个，实际安装 $AgentCount 个。" -ForegroundColor Yellow
    Write-Host "⚠️  仓库 agents/ 目录可能已变更，请同步更新安装脚本内置断言。" -ForegroundColor Yellow
    Write-Host "⚠️  =============================================" -ForegroundColor Yellow
}

# 2) 模型表漂移断言：内嵌模型表（提示词第二步表格）vs agents/*.md frontmatter 的 model: 字段
$TableDriftFound = $false
$TableAgentNames = @{}
foreach ($line in ($Prompt -split "\r?\n")) {
    if ($line -match '^\|\s*([A-Za-z][A-Za-z0-9-]*)\s*\|\s*(\S+)\s*\|') {
        $agentName = $Matches[1]
        $expectedModel = $Matches[2]
        $TableAgentNames[$agentName] = $expectedModel
        $agentFile = Join-Path $TargetDir "$agentName.md"
        if (Test-Path $agentFile) {
            # Select-String 逐文件读取，兼容 CRLF 文件与带引号的 model 值
            $modelLine = Select-String -Path $agentFile -Pattern '^model:' | Select-Object -First 1
            $actualModel = ""
            if ($modelLine) {
                $actualModel = ($modelLine.Line -replace '^model:\s*', '').Trim().Trim('"').Trim("'")
            }
            if ($actualModel -ne $expectedModel) {
                if (-not $TableDriftFound) {
                    Write-Host ""
                    Write-Host "⚠️  =============================================" -ForegroundColor Yellow
                    Write-Host "⚠️  WARNING: 脚本内嵌模型表与 agents/*.md frontmatter 不一致（表已漂移）！" -ForegroundColor Yellow
                }
                $shownActual = if ($actualModel) { $actualModel } else { "<无 model 字段>" }
                Write-Host "⚠️  - ${agentName}: 表=$expectedModel，实际=$shownActual" -ForegroundColor Yellow
                $TableDriftFound = $true
            }
        }
    }
}

# 反向检查：已安装但内嵌模型表中缺失的智能体同样属于"表已漂移"
Get-ChildItem -Path $TargetDir -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
    $agentName = $_.BaseName
    if (-not $TableAgentNames.ContainsKey($agentName)) {
        if (-not $TableDriftFound) {
            Write-Host ""
            Write-Host "⚠️  =============================================" -ForegroundColor Yellow
            Write-Host "⚠️  WARNING: 脚本内嵌模型表与 agents/*.md frontmatter 不一致（表已漂移）！" -ForegroundColor Yellow
        }
        Write-Host "⚠️  - ${agentName}: 已安装但内嵌模型表中缺失" -ForegroundColor Yellow
        $TableDriftFound = $true
    }
}
if ($TableDriftFound) {
    Write-Host "⚠️  请同步更新安装脚本内嵌模型表（提示词第二步表格）。" -ForegroundColor Yellow
    Write-Host "⚠️  =============================================" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "已安装的智能体:"
Write-Host "  主智能体:"
@("smart-router", "Zero", "Erribaba") | ForEach-Object {
    $f = Join-Path $TargetDir "$_.md"
    if (Test-Path $f) { Write-Host "    - $_" }
}
Write-Host "  子智能体:"
Get-ChildItem -Path $TargetDir -Filter "*.md" | Where-Object { $_.Name -notin @("smart-router.md", "Zero.md", "Erribaba.md") } | ForEach-Object {
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
Write-Host $Prompt
Write-Host ""
