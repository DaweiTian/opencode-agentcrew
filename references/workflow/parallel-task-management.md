# Parallel Task Management — Shared Protocol

> This file is a shared reference used by the three primary agents (`smart-router`, `Zero`, `Erribaba`). It is the canonical home of the parallel task management protocol — phase barriers, within-phase parallelism, the file-ownership mutex for parallel write tasks, timeout recovery, and the task completion check. Each primary body keeps only a short core-rules summary; edit protocol text here, not in the agent bodies.

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
1. **Sanity-check** the result (does it address the task?) — command-level verification is **batched per phase**, not run per arrival (see [Task Completion Check](#task-completion-check-critical))
2. **Process** the result — record findings, update state
3. **Wait for remaining tasks** — do NOT launch next-phase tasks yet
4. **Only after ALL phase tasks complete** — run the ONE batched verification pass over the phase's changes, synthesize results, and proceed to next phase

**Implementation Pattern:**
```
Step 1: Launch multiple independent tasks in single message
        Use background=true for independent tasks:
        @explore (module A, background=true), @explore (module B, background=true)

Step 2: As soon as ANY task completes (first-come-first-serve):
        - Sanity-check the result (command verification is batched per phase)
        - Process the result (record findings, update state)
        - Continue waiting for remaining phase tasks
        - ⛔ DO NOT launch next-phase tasks yet

Step 3: Repeat Step 2 for each subsequent completion

Step 4: ONLY after ALL phase tasks are processed:
        - Run ONE batched verification pass over the phase's changes
        - Synthesize all results
        - Proceed to next phase
        - Now you can launch next-phase tasks
```

> **"Independent" includes file independence.** Before applying this pattern to write tasks, confirm their file sets are pairwise disjoint — see [Parallel Write Tasks: File Ownership Mutex](#parallel-write-tasks-file-ownership-mutex-critical--must-follow).

## Parallel Write Tasks: File Ownership Mutex (CRITICAL — MUST FOLLOW)

**Hard rule: parallel write tasks MUST have mutually exclusive file ownership.** A file (or a tightly-coupled group of files) may have **exactly one write-task owner at any given moment**.

When you are about to dispatch multiple write tasks in the same phase, apply this decision:

```
Same-phase tasks all read-only (explore / research / review)?
  └── YES → dispatch freely with background=true. No isolation needed.

Any task writes files?
  ├── Compute each task's candidate file set (a cheap read-only pass suffices)
  ├── Are the file sets pairwise disjoint?
  │     ├── YES → dispatch in parallel, but declare each task's file boundary
  │     │         explicitly in its prompt. If a task crosses its boundary,
  │     │         stop treating the set as disjoint.
  │     └── NO (any overlap, or overlap merely *possible*) → choose ONE of:
  │           (A) worktree isolation — one isolated workspace per write task
  │               (see `references/workflow/isolated-workspace.md`, OpenCode native
  │                `worktree_create` + `session_move`), merge sequentially afterwards; or
  │           (B) serialize the tasks — dispatch one, verify, then dispatch the next.
```

⛔ **Never** dispatch overlapping write tasks against the same checkout and hope they don't collide. Shared index files, route tables, dependency manifests, lockfiles, barrel exports (`index.ts`), and i18n resources are collision magnets — assume overlap until proven otherwise.

**Watch for false independence:** two tasks touching *different* files that both import or both register into a common file (e.g. `app/routes.ts`) are **not** file-disjoint. The coupling is on the shared file, not the visible ones.

### Relationship to the Conflict Resolution clause

This rule and the "higher domain authority wins" rule in [Result Merging & Conflict Resolution](#result-merging--conflict-resolution) address **two different kinds of conflict** and are complementary, not contradictory:

| Conflict kind | What it is | Resolution mechanism |
|---------------|-----------|----------------------|
| **Review-opinion conflict** | Two completed subagents give contradictory *recommendations* about the same code | Authority ordering: `security-auditor` > `reviewer` > `validator` > others; `architect` > `code-generator` for architecture decisions |
| **File-ownership conflict** | Two *in-flight* write tasks would edit the same file at the same time | Isolation (worktree) or serialization — **never** priority arbitration |

Priority ordering cannot fix a file-ownership conflict: letting a "lower-priority" agent write the same file concurrently still corrupts the file, and a higher-priority agent's result can be silently overwritten by a lower-priority one that finishes later. Conversely, worktree isolation does not tell you whose *recommendation* to follow once both agents have reported. Use each mechanism for the conflict it addresses.

**Sequence in practice:** prevent ownership collisions up front (this section) → let both tasks finish → then arbitrate any remaining *opinion* disagreements with the authority ordering (that section).

## No Polling (NEVER)

**NEVER** poll for subagent task status. Completions arrive as notifications — do not proactively query task status; keep processing other work and handle each result as it arrives.

## Phase Transition Checklist

Before moving from one phase to the next, verify:

- [ ] All tasks in current phase have completed (check background tasks)
- [ ] All results have been processed and the phase's ONE batched verification pass has run (full output read)
- [ ] Results have been synthesized into coherent understanding
- [ ] Next-phase write tasks have been checked for file overlap (disjoint, worktree-isolated, or serialized — see [Parallel Write Tasks: File Ownership Mutex](#parallel-write-tasks-file-ownership-mutex-critical--must-follow))
- [ ] Any blockers or issues have been resolved
- [ ] Next phase tasks have clear requirements based on current phase output

## Result Merging & Conflict Resolution

When delegating to multiple subagents in parallel (independent tasks within the same phase):

1. **Use background=true** for independent tasks that can run asynchronously
2. **Check each metadata header** — if any subagent is `blocked` or `needs_input`, resolve that first.
3. **Merge results by scope**: each subagent owns its domain.
4. **When two subagents give conflicting suggestions**, prefer the one with higher domain authority: `security-auditor` > `reviewer` > `validator` > other subagents. **Architecture decisions** from `architect` take precedence over suggestions from `code-generator`. **Security findings** from `security-auditor` override convenience suggestions from other agents.
   > This arbitration applies to **conflicting recommendations from completed tasks** only. It does **not** apply to concurrent write tasks targeting the same file — that is a file-ownership conflict, resolved by isolation or serialization up front (see [Parallel Write Tasks: File Ownership Mutex](#parallel-write-tasks-file-ownership-mutex-critical--must-follow)).
5. **Synthesize before delegating next**: after parallel results are collected, combine relevant context from all subagents into a coherent prompt for the next phase / next sequential delegation.

## Subagent Timeout Detection & Recovery

When launching subagent tasks, include timeout awareness.

**Before launching a task:**
```
bash: date +%s  →  record as TASK_START_{agent_name}
```

**Timeout thresholds:**
- Simple tasks (review, lint): 5 minutes
- Medium tasks (code generation, single feature): 10 minutes
- Complex tasks (full-stack implementation, architecture): 15 minutes

**When a task exceeds its threshold:**
1. Log the timeout: `bash: echo "TIMEOUT: {agent_name} exceeded {threshold} minutes"`
2. Abandon the stuck sub-session and re-dispatch: the `subagent` tool has no cancellation parameter, so a stuck task cannot be stopped — give up on that sub-session and launch a fresh one
3. Retry with a simplified prompt (reduce scope, add explicit time constraint)
4. Include in retry: `"Complete within {threshold} minutes (5 simple / 10 medium / 15 complex). If you cannot finish, return partial results with Status: partial."`
5. If retry also fails: escalate — try a different subagent or handle the task yourself

**Embed timeout instructions in subagent prompts:**
When delegating tasks, always include: `"If you cannot complete this task within {threshold} minutes (use the timeout threshold for this task's complexity from the thresholds above), return your partial progress with Status: partial and explain what remains."` (shorter form also acceptable: `"If you cannot complete within {threshold} minutes (use the timeout threshold for this task's complexity from the thresholds above), return partial results with Status: partial."`)

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

**Step 2: Verify All Completed Tasks in ONE Batched Pass**
For each dispatched task, confirm:
- Has the subagent returned a result with `Status: done`?
- If `Status: partial` or `blocked`, the task is NOT complete
- If no result received, the task is still processing
- **A `Status: done` is a *claim*, not evidence** — but verification is **batched per phase, not per task**. Before the completion summary, verify the phase's completed tasks together in ONE pass: a single `git diff` covering all changes plus one test/build run (yourself or a single `executor` / `validator` dispatch covering all tasks), and read its **full** output. Do not dispatch a serial verification round-trip per `done`. Prose is not evidence. Only after the batch passes do the tasks count as **verified done** — an unverified `Status: done` does NOT satisfy this protocol and must not be counted as "completed".
  > Verification is **your own next action**, not a reason to keep waiting on the subagent. "Still processing" refers **only** to tasks that have not returned a result yet. A task that returned `Status: done` is *reported* — fold it into the batched verification pass instead of asking the subagent to re-report.

**Step 3: Output Decision**
Classify each dispatched task into exactly one bucket, then decide:

| Bucket | Meaning | Your action |
|--------|---------|-------------|
| **Verified done** | Result returned **and** confirmed in the phase's batched verification pass this message | Counts as complete |
| **Reported, unverified** | `Status: done` received, not yet checked | **Fold into the phase's batched verification pass now** (your own next step) — do NOT show it under "仍在处理", do NOT ask the subagent to re-report |
| **Still processing** | No result received yet | Include in the waiting message |
| **partial / blocked / needs_input** | Returned but not done | Resolve (re-dispatch, handle yourself, or ask the user) — never silently counted as complete |

- **If ALL tasks are verified done**: proceed with the completion summary
- **If ANY task is still processing** (no result yet): output the waiting message instead
- **If any task is reported-but-unverified**: run the batched verification first, then re-evaluate

### Waiting Message Template
When tasks are still pending (no result received yet), output — list only tasks under "仍在处理" that genuinely have not returned; tasks that returned `Status: done` belong under "已完成" **only after you have verified them**:
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
1. **All 5 subagents dispatched, 3 returned**: verify the 3 returned claims in ONE batched pass, then output a waiting message for the remaining 2 (which have not returned at all)
2. **All 5 returned `Status: done`**: do **not** summarize yet — verify them in ONE batched pass (a single `git diff` + test run covering all changes, or one `executor` dispatch), then output the full completion summary
3. **All tasks verified done**: output full completion summary
4. **Some tasks failed**: report failures, but still wait for remaining tasks
5. **A `Status: done` claim fails your verification**: treat the task as incomplete — re-dispatch with the specific gap, or handle it yourself; never report it as done

### Implementation Rules
- **NEVER** output "task complete" or "all done" if any subagent is still processing
- **NEVER** assume a task is complete just because you received some results
- **NEVER** treat an unverified subagent `Status: done` as complete — the claim is not evidence
- **ALWAYS** explicitly check for pending tasks before summarizing
- **ALWAYS** independently verify the phase's claimed-done tasks in ONE batched check within the current message (one `git diff` + test run covering all changes, or a single `executor` dispatch) and read its full output before declaring completion (Verification Iron Law)
- **ALWAYS** use the waiting message template when tasks are pending

## Related References

- Worktree-based isolation for overlapping parallel write tasks (how to actually create, use, and clean up an isolated workspace): [`isolated-workspace.md`](isolated-workspace.md).
