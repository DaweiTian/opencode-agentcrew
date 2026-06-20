# 结构化工作流快速参考

## 新增代理

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
Erribaba: 直接修改 CSS，无需结构化工作流
```

### 复杂任务（使用结构化工作流）
```
用户: "添加用户认证系统，支持 JWT 和 OAuth"
Erribaba: 我将使用结构化工作流来实现这个功能

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

## 两阶段审查

### Stage 1: 规范合规性审查 (@spec-reviewer)
- 验证实现是否符合原始需求
- 使用规范锚定（[Sn] 引用）
- 证据优先原则

### Stage 2: 代码质量审查 (@reviewer)
- 检查代码质量、性能、安全性
- 在 Stage 1 通过后才能运行
- 输出结构化审查报告

## TDD 原则

每个任务都遵循测试驱动开发：
1. **RED**: 编写失败测试
2. **GREEN**: 编写最小实现让测试通过
3. **REFACTOR**: 重构代码

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
# 启动 OpenCode 并使用 Erribaba 主代理
opencode

# 在对话中使用结构化工作流
@workflow-orchestrator 请帮我实现用户认证系统

# 单独使用某个阶段
@plan-writer 请为这个功能创建实现计划
@spec-reviewer 请验证这个实现是否符合需求
```
