#!/usr/bin/env bash
# opencode-agents 一键安装脚本
# 用法: curl -fsSL https://raw.githubusercontent.com/DaweiTian/opencode-agentcrew/master/install.sh | bash
# 注: URL 中的 raw/master 分支已核实——GitHub 仓库默认分支为 master（2026-10-09 推送验证）

set -euo pipefail

REPO_URL="https://github.com/DaweiTian/opencode-agentcrew.git"
TARGET_DIR="${HOME}/.config/opencode/agents"
REFERENCES_DIR="${HOME}/.config/opencode/references"
BACKUP_DIR="${HOME}/.config/opencode/agents-备份-$(date +%Y%m%d%H%M%S)"
TEMP_DIR=$(mktemp -d)

echo "🚀 opencode-agents 安装脚本"
echo "================================"

# 检查 git
if ! command -v git &>/dev/null; then
    echo "❌ 需要安装 git"
    exit 1
fi

# 备份已有 agents
if [ -d "$TARGET_DIR" ]; then
    echo "📦 备份已有 agents 到: $BACKUP_DIR"
    cp -r "$TARGET_DIR" "$BACKUP_DIR"
fi

# 克隆仓库到临时目录
echo "📥 正在下载 agents..."
git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null

# 创建目标目录
mkdir -p "$TARGET_DIR"
mkdir -p "$REFERENCES_DIR"

# 复制 agents 文件
echo "📂 安装 agents 到: $TARGET_DIR"
cp "$TEMP_DIR"/agents/*.md "$TARGET_DIR/"

# 复制 references 文件
if [ -d "$TEMP_DIR/references" ]; then
    echo "📚 安装 references 到: $REFERENCES_DIR"
    cp -r "$TEMP_DIR"/references/* "$REFERENCES_DIR/"
fi

# 清理
rm -rf "$TEMP_DIR"

# 配置环境变量以启用异步子代理处理
echo "⚙️  配置环境变量..."

# 设置 shell 环境变量
SHELL_RC=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS" "$SHELL_RC"; then
        echo "" >> "$SHELL_RC"
        echo "# OpenCode 异步子代理支持" >> "$SHELL_RC"
        echo "export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true" >> "$SHELL_RC"
        echo "  ✅ 已添加环境变量到 $SHELL_RC"
        # 立即生效
        export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
    else
        echo "  ℹ️  环境变量已存在于 $SHELL_RC"
    fi
fi

# 配置提示词（安装结束时输出给用户复制）。
# 其"第二步"表格同时是本脚本内嵌模型表的唯一数据源，下方安装校验会解析它与 agents/*.md 的 frontmatter 比对。
PROMPT_TEXT=$(cat <<'PROMPT'
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
PROMPT
)

# 统计（find | wc 不受 pipefail 影响；目录判断显式处理空/缺失目录，避免脚本中断）
AGENT_COUNT=0
REFERENCE_COUNT=0
if [ -d "$TARGET_DIR" ]; then
    AGENT_COUNT=$(find "$TARGET_DIR" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d '[:space:]')
fi
if [ -d "$REFERENCES_DIR" ]; then
    REFERENCE_COUNT=$(find "$REFERENCES_DIR" -type f -name '*.md' | wc -l | tr -d '[:space:]')
fi
echo ""
echo "✅ 安装完成！共 ${AGENT_COUNT} 个智能体，${REFERENCE_COUNT} 个参考文档"

# ============================================
# 安装一致性校验（仅醒目告警，不中断安装）
# ============================================
EXPECTED_AGENT_COUNT=38

# 1) 数量断言：动态统计已安装 .md 数量，与内置期望值 38 比对
if [ "$AGENT_COUNT" -ne "$EXPECTED_AGENT_COUNT" ]; then
    echo ""
    echo "⚠️  ============================================="
    echo "⚠️  WARNING: 智能体数量与预期不符！"
    echo "⚠️  预期 ${EXPECTED_AGENT_COUNT} 个，实际安装 ${AGENT_COUNT} 个。"
    echo "⚠️  仓库 agents/ 目录可能已变更，请同步更新安装脚本内置断言。"
    echo "⚠️  ============================================="
fi

# 2) 模型表漂移断言：内嵌模型表（提示词第二步表格）vs agents/*.md frontmatter 的 model: 字段
TABLE_DRIFT_FOUND=0
TABLE_AGENT_NAMES=" "
while read -r drift_agent drift_expected; do
    [ -n "$drift_agent" ] || continue
    TABLE_AGENT_NAMES="${TABLE_AGENT_NAMES}${drift_agent} "
    drift_file="$TARGET_DIR/$drift_agent.md"
    if [ -f "$drift_file" ]; then
        # awk 逐文件读取，兼容 CRLF 文件与带引号的 model 值
        drift_actual=$(awk '/^model:/{sub(/^model:[ \t]*/,""); sub(/[ \t\r]+$/,""); print; exit}' "$drift_file" | tr -d "\"'")
        if [ "$drift_actual" != "$drift_expected" ]; then
            if [ "$TABLE_DRIFT_FOUND" -eq 0 ]; then
                echo ""
                echo "⚠️  ============================================="
                echo "⚠️  WARNING: 脚本内嵌模型表与 agents/*.md frontmatter 不一致（表已漂移）！"
            fi
            echo "⚠️  - ${drift_agent}: 表=${drift_expected}，实际=${drift_actual:-<无 model 字段>}"
            TABLE_DRIFT_FOUND=1
        fi
    fi
done <<DRIFT_EOF
$(printf '%s\n' "$PROMPT_TEXT" | sed -n '/^| 智能体 |/,/^$/p' | awk -F'|' '/^\| [A-Za-z]/ {gsub(/^[ \t]+|[ \t]+$/,"",$2); gsub(/^[ \t]+|[ \t]+$/,"",$3); print $2, $3}')
DRIFT_EOF

# 反向检查：已安装但内嵌模型表中缺失的智能体同样属于"表已漂移"
for drift_f in "$TARGET_DIR"/*.md; do
    [ -e "$drift_f" ] || continue
    drift_name=$(basename "$drift_f" .md)
    case "$TABLE_AGENT_NAMES" in
        *" $drift_name "*) ;;
        *)
            if [ "$TABLE_DRIFT_FOUND" -eq 0 ]; then
                echo ""
                echo "⚠️  ============================================="
                echo "⚠️  WARNING: 脚本内嵌模型表与 agents/*.md frontmatter 不一致（表已漂移）！"
            fi
            echo "⚠️  - ${drift_name}: 已安装但内嵌模型表中缺失"
            TABLE_DRIFT_FOUND=1
            ;;
    esac
done
if [ "$TABLE_DRIFT_FOUND" -ne 0 ]; then
    echo "⚠️  请同步更新安装脚本内嵌模型表（提示词第二步表格）。"
    echo "⚠️  ============================================="
fi

echo ""
echo "已安装的智能体:"
echo "  主智能体:"
for name in smart-router Zero Erribaba; do
    if [ -f "$TARGET_DIR/$name.md" ]; then
        echo "    - $name"
    fi
done
echo "  子智能体:"
for f in "$TARGET_DIR"/*.md; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .md)
    case "$base" in
        smart-router|Zero|Erribaba) continue ;;
    esac
    echo "    - $base"
done

echo ""
echo "已安装的参考文档:"
find "$REFERENCES_DIR" -name "*.md" 2>/dev/null | while read f; do
    echo "    - $(basename "$f" .md)"
done

echo ""
echo "📋 下一步："
echo "  1. 编辑 ~/.config/opencode/opencode.json 配置模型和 provider"
echo "  2. 在 opencode.json 中设置 \"default_agent\" 选择主智能体"
echo "  3. 在 opencode.json 中配置 \"references\" 指向参考文档目录"
echo "  4. 启动 opencode 开始使用"
echo ""
echo "⚡ 已启用异步子代理处理功能，主智能体现在可以并行处理多个子任务！"
echo ""
echo "💡 提示：将下方提示词复制到你的 OpenCode 智能体中，"
echo "   它会帮你自动配置模型并更新智能体文件。"
echo ""
echo "================================"
printf '%s\n' "$PROMPT_TEXT"
echo ""
