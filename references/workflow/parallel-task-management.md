# Parallel Task Management — Shared Protocol

> This file is a shared reference used by the three primary agents (`smart-router`, `Zero`, `Erribaba`). It is the canonical home of the parallel task management protocol — phase barriers, within-phase parallelism, timeout recovery, and the task completion check. Each primary body keeps only a short core-rules summary; edit protocol text here, not in the agent bodies.

## Phase Barriers (CRITICAL — MUST FOLLOW)

When executing a multi-phase workflow (explore → plan → fix → review), you **MUST** respect phase boundaries:

```
Phase 1: Explore/Research
  ├── @explore (module A, background=true)
  ├── @explore (module B, background=true)
  ├── @explore (module C, background=true)
  └── @explore (module D, background=true)
  
  ⛔ BARRIER: Wait for ALL explore tasks to complete
  ⛔ DO NOT launch any fix/implementation tasks yet
  ⛔ Even if one explore returns early, WAIT for the rest
  
Phase 2: Analyze & Plan
  ├── Synthesize ALL explore results together
  ├── Identify dependencies between issues
  ├── Create prioritized fix plan
  └── Get user approval (if applicable)
  
Phase 3: Execute Fixes
  ├── Launch fix tasks based on COMPLETE information
  └── Use parallel delegation for independent fixes
```

**WHY THIS MATTERS:**
- Explore tasks discover root causes and dependencies
- Launching fix agents with incomplete information leads to:
  - Fixing symptoms instead of root causes
  - Missing cross-module dependencies
  - Duplicate or conflicting fixes
  - Wasted agent cycles on wrong problems

**COMMON MISTAKE TO AVOID:**
```
❌ WRONG: Launch explore → first explore returns → immediately launch fix agents
✅ RIGHT: Launch explore → wait for ALL explores → analyze together → then launch fix agents
```

## Within-Phase Parallel Tasks (First-Come-First-Serve)

**ONLY** use first-come-first-serve processing for tasks **within the same phase**:

When multiple independent tasks are launched in the same phase (e.g., multiple explore tasks, or multiple independent fix tasks):

When any task completes, **immediately**:
1. **Verify** the result
2. **Process** the result — record findings, update state
3. **Wait for remaining tasks** — do NOT launch next-phase tasks yet
4. **Only after ALL phase tasks complete** — synthesize results and proceed to next phase

**Implementation Pattern:**
```
Step 1: Launch multiple independent tasks in single message
        Use background=true for independent tasks:
        @explore (module A, background=true), @explore (module B, background=true)

Step 2: As soon as ANY task completes (first-come-first-serve):
        - Immediately verify the result
        - Process the result (record findings, update state)
        - Continue waiting for remaining phase tasks
        - ⛔ DO NOT launch next-phase tasks yet

Step 3: Repeat Step 2 for each subsequent completion

Step 4: ONLY after ALL phase tasks are processed:
        - Synthesize all results
        - Proceed to next phase
        - Now you can launch next-phase tasks
```

## No Polling (NEVER)

**NEVER** poll for subagent task status. Completions arrive as notifications — do not proactively query task status; keep processing other work and handle each result as it arrives.

## Phase Transition Checklist

Before moving from one phase to the next, verify:

- [ ] All tasks in current phase have completed (check background tasks)
- [ ] All results have been verified and processed
- [ ] Results have been synthesized into coherent understanding
- [ ] Any blockers or issues have been resolved
- [ ] Next phase tasks have clear requirements based on current phase output

## Result Merging & Conflict Resolution

When delegating to multiple subagents in parallel (independent tasks within the same phase):

1. **Use background=true** for independent tasks that can run asynchronously
2. **Check each metadata header** — if any subagent is `blocked` or `needs_input`, resolve that first.
3. **Merge results by scope**: each subagent owns its domain.
4. **When two subagents give conflicting suggestions**, prefer the one with higher domain authority: `security-auditor` > `reviewer` > `validator` > other subagents. **Architecture decisions** from `architect` take precedence over suggestions from `code-generator`. **Security findings** from `security-auditor` override convenience suggestions from other agents.
5. **Synthesize before delegating next**: after parallel results are collected, combine relevant context from all subagents into a coherent prompt for the next phase / next sequential delegation.

## Subagent Timeout Detection & Recovery

When launching subagent tasks, include timeout awareness.

**Before launching a task:**
```
bash: date +%s  →  record as TASK_START_{agent_name}
```

**Timeout thresholds:**
- Simple tasks (review, lint): 10 minutes
- Medium tasks (code generation, single feature): 20 minutes
- Complex tasks (full-stack implementation, architecture): 30 minutes

**When a task exceeds its threshold:**
1. Log the timeout: `bash: echo "TIMEOUT: {agent_name} exceeded {threshold} minutes"`
2. Abandon the stuck sub-session and re-dispatch: the `subagent` tool has no cancellation parameter, so a stuck task cannot be stopped — give up on that sub-session and launch a fresh one
3. Retry with a simplified prompt (reduce scope, add explicit time constraint)
4. Include in retry: `"Complete within 10 minutes. If you cannot finish, return partial results with Status: partial."`
5. If retry also fails: escalate — try a different subagent or handle the task yourself

**Embed timeout instructions in subagent prompts:**
When delegating tasks, always include: `"If you cannot complete this task within 15 minutes, return your partial progress with Status: partial and explain what remains."` (shorter form also acceptable: `"If you cannot complete within 15 minutes, return partial results with Status: partial."`)

## Task Completion Check (CRITICAL)

**⚠️ MANDATORY: Before outputting any task completion summary, you MUST verify all subagent tasks are complete.**

### Problem This Solves
When multiple subagents are dispatched in parallel (background=true), some may still be processing when you receive results from others. If you output a completion summary before all tasks finish:
- Users may close OpenCode, interrupting incomplete subagent tasks
- Completed subagents later trigger another summary, creating confusion
- The overall task is actually incomplete despite your summary

### Completion Check Protocol

**Step 1: Track Dispatched Tasks**
Before outputting any summary, mentally list all subagent tasks you've dispatched:
- Which agents were called?
- Which have returned results?
- Which are still processing?

**Step 2: Verify All Tasks Complete**
For each dispatched task, confirm:
- Has the subagent returned a result with `Status: done`?
- If `Status: partial` or `blocked`, the task is NOT complete
- If no result received, the task is still processing

**Step 3: Output Decision**
- **If ALL tasks complete**: Proceed with completion summary
- **If ANY tasks incomplete**: Output waiting message instead

### Waiting Message Template
When tasks are still pending, output:
```
⏳ 任务进行中：我已派出 {N} 个子智能体处理此任务。

已完成：
- ✅ {agent1}: {brief description of completed work}
- ✅ {agent2}: {brief description of completed work}

仍在处理：
- 🔄 {agent3}: {task description}
- 🔄 {agent4}: {task description}

请稍等，我会在所有任务完成后提供完整的总结。您可以继续等待，或者稍后回来查看结果。
```

### Common Scenarios
1. **All 5 subagents dispatched, 3 returned**: Output waiting message for remaining 2
2. **All tasks complete**: Output full completion summary
3. **Some tasks failed**: Report failures, but still wait for remaining tasks

### Implementation Rules
- **NEVER** output "task complete" or "all done" if any subagent is still processing
- **NEVER** assume a task is complete just because you received some results
- **ALWAYS** explicitly check for pending tasks before summarizing
- **ALWAYS** use the waiting message template when tasks are pending
