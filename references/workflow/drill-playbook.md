# Agentcrew Behavioral Drill Playbook

> **Read this first:** the consistency gate (`scripts/check-agents.ps1`) verifies **files** — byte-identical contract copies, roster coverage, badge families. Drills verify **behavior** — whether the models actually honor the handoff contract and workflow gates at runtime. The two are complementary: a green gate says the prompts are correct; only a green drill says the prompts *work*. Receipt *shape* is statically checkable (`scripts/check-receipt.ps1`, documented in AGENTS.md — it exists and is available as a mechanical receipt spot-checker); receipt *workflow behavior* — ordering, gating, discipline — never will be.

## Table of Contents

1. [Purpose](#2-purpose) — behavioral golden tests, complementary to the file gate
2. [Cadence](#3-cadence) — when to run, minimum viable drill
3. [General Procedure](#4-general-procedure) — worktree, run, record, clean up
4. [Scenarios S1–S5](#5-scenarios) — scripted requests with scored checklists
5. [Scoring & Escalation](#6-scoring--escalation) — turning FAILs into fixes

## 2. Purpose

Behavioral golden tests for the agentcrew. Each scenario pins one runtime expectation of the three-primary + 36-subagent system:

- Receipts follow `references/workflow/handoff-contract.md` (4-field header, literal Status, gap-naming `Context For Next`).
- The two-stage review gate orders and blocks as specified.
- Routing tie-break rules and Ask Discipline are applied, not improvised.
- Escalation Policy branches fire on `partial`/`blocked` receipts.
- The browser domain chain (primary skill-load → `executor` CLI) holds.

Drills are **observational**: record what the model did, never coach it mid-scenario, never edit an agent file to make a scenario pass.

Scenario selection is evidence-driven: S1 targets the dropped-metadata-header regression and S2 the legacy-vocabulary regression — both observed in the first drill and recorded in `references/lessons.md` § Model Behavior & Compliance.

## 3. Cadence

Run a drill when any of these change (behavior depends on prompts and models, not just files):

- [ ] Any change to `references/workflow/handoff-contract.md` or its 36 embedded copies
- [ ] Any model-tier change (an agent's `model:` line, or a provider/model rename)
- [ ] Any prompt-batch change (a batch of agent bodies edited at once, e.g. contract propagation)
- [ ] Before declaring a major milestone (version tag, README feature claims)
- [ ] Optional: monthly, as a drift smoke test

**Cost control — minimum viable drill = S1 + S3** (~4 dispatches total, both mandatory scenarios). Full suite S1–S5 only when contract or tier changes justify it. S4/S5 are optional by design; S2 is recommended on any review-gate or spec-reviewer touch.

## 4. General Procedure

Every drill run follows the same loop:

1. **Isolate.** Create a scratch worktree via `tools.opencode.worktree_create` (see `references/workflow/isolated-workspace.md`). Never drill in the main repo — scenarios dispatch real implementers that write files.
2. **Run as scripted.** In a fresh primary session (default entry: `smart-router`) inside the worktree, paste each scenario's scripted user request verbatim. Observe receipts **as the primary would**: read the full 4-field header, the gate vocabulary, the dispatch order. Run each receipt through `scripts/check-receipt.ps1` as a mechanical cross-check of your observation and record its verdict. Do not paraphrase the subagent output when recording; quote it.
3. **Record.** Append dated entries to `references/lessons.md` § Append Log, following its **Append Log convention**: `### YYYY-MM-DD — <category> — <one-line lesson>` plus one evidence sentence. Category is `model` for receipt-compliance results and `process` for workflow-level results (ordering, gating, discipline). The entry body carries the drill detail: scenario ID first, then one pass/fail line per expected-behavior checkbox, then quoted deviations. Keep entries factual — deviations are data, not verdicts. Promote a recurring finding into its category section once it stops being surprising; the log entry stays as the record.
4. **Clean up.** Report worktree path and contents to the user; remove the worktree **only after explicit user confirmation** (Destructive Operations rule — silence ≠ approval). Drill worktrees hold modified and untracked files, so removal needs `force=true` — discarding those artifacts is exactly what the confirmation guards. Leaving the worktree in place is a valid default.

## 5. Scenarios

Format per scenario: **ID / Objective / Setup / Scripted request / Expected behaviors / Pass criteria / Runtime budget.** Checkboxes are the scoring units — tick each during the run.

| ID | Scenario | Priority | Dispatches | Budget |
|----|----------|----------|:---------:|:------:|
| S1 | Lite contract compliance | **mandatory** | 1 | ~5 min |
| S2 | Two-stage gate | recommended | 4–6 | ~15 min |
| S3 | Routing tie-break | **mandatory** | 1–2 | ~5 min |
| S4 | Escalation branch | optional | 2–3 | ~10 min |
| S5 | Browser domain chain | optional (dry-run ok) | 1 | ~10/3 min |

### S1 · Lite Contract Compliance (mandatory)

- **Objective:** a lite-tier agent under minimal load still emits a fully contract-compliant receipt.
- **Setup:** scratch worktree with any small file present; trivial single-file backend task.
- **Scripted user request:** `帮我写一个 Python 函数，把字符串反转，放到 reverse.py`
- **Expected behaviors:**
  - [ ] Routing picks `code-generator-lite` (domain `backend`, complexity `simple`)
  - [ ] Receipt carries the full 4-field header: `Agent` / `Status` / `Suggest Next` / `Context For Next`
  - [ ] `Status` is one literal word (`done`/`partial`/`blocked`/`needs_input`) — the bracket menu was replaced, not left in
  - [ ] `Suggest Next` is sane: comma-separated roster names or `none` (not prose, not a fake agent name)
  - [ ] `Context For Next` carries a real decision/constraint, not filler
- **Pass criteria:** all five boxes. **Runtime budget:** ~5 min, 1 dispatch.

### S2 · Two-Stage Gate (recommended)

- **Objective:** Stage 1 → Stage 2 ordering and gate-blocking fire on high-risk complex work.
- **Setup:** scratch worktree; a payments/auth-flavored complex implementation request.
- **Scripted user request:** `实现一个带 JWT 认证的转账接口，含幂等键`
- **Expected behaviors:**
  - [ ] Review tiering applies (complex + auth/payments ⇒ two-stage), per the Review tiering note
  - [ ] `spec-reviewer` is dispatched **first**; `reviewer` is not dispatched before or alongside it
  - [ ] Stage-1 receipt uses gate vocabulary — `Overall Gate` / `Claim Status` — and its only `Status:` line is the 4-value metadata header (no legacy `Overall Status: pass`)
  - [ ] On a passing gate (`Status: done`), Stage-2 `reviewer` follows
  - [ ] Simulating a failing claim (ask for one requirement, omit it from the implementation prompt): Stage 2 must **not** dispatch; primary re-dispatches the implementer with the failing claim IDs from `Context For Next`
- **Pass criteria:** ordering + vocabulary + block-on-fail all hold. **Runtime budget:** ~15 min, 4–6 dispatches.

### S3 · Routing Tie-Break (mandatory)

- **Objective:** boundary-ambiguous requests resolve via the tie-break rule or the question tool — never a silent wrong pick.
- **Setup:** none beyond the worktree; observation is mostly of the analysis block.
- **Scripted user request:** `页面变慢了，帮我看看` (hits debug / perf / browser signals at once)
- **Expected behaviors:**
  - [ ] Regression wording ("变慢了 / used to be fast") routes to `debugger`, not `perf-optimizer`
  - [ ] If the router instead finds it genuinely ambiguous, it asks via the structured question tool with concrete options
  - [ ] The turn never ends on a trailing plain-text question (Ask Discipline)
  - [ ] The 📋 analysis block is emitted before any dispatch
  - [ ] Control probe `接口一直很慢，帮我优化` routes to `perf-optimizer` (steady-state branch)
- **Pass criteria:** correct branch taken, discipline box holds. **Runtime budget:** ~5 min, 1–2 dispatches.

### S4 · Escalation Branch (optional)

- **Objective:** a `partial` receipt drives the right Escalation Policy branch.
- **Setup:** dispatch with deliberately missing context — e.g. `按之前的方案改一下那个模块` with no prior "之前的方案" in existence.
- **Expected behaviors:**
  - [ ] Subagent returns `Status: partial` or `blocked` naming the exact gap in `Context For Next`
  - [ ] Primary reads `Context For Next` and picks a branch: capability → re-tier / context → refill and re-dispatch / scope → split
  - [ ] Primary never re-dispatches the same prompt unchanged
  - [ ] At most 2 escalation attempts before reporting back to the user
- **Pass criteria:** gap named + branch taken + no repeat dispatch. **Runtime budget:** ~10 min, 2–3 dispatches.

### S5 · Browser Domain Chain (optional, dry-run acceptable)

- **Objective:** the one-off browser request follows primary-skill → executor-CLI, with primary never touching the browser itself.
- **Setup:** scratch worktree; one-off screenshot/console request. Dry-run = inspect routing, skill-load, and dispatch text without launching a browser.
- **Scripted user request:** `打开 https://example.com，截个图并把 console 报错列出来`
- **Expected behaviors:**
  - [ ] Primary loads the `agent-browser` skill before dispatching
  - [ ] Primary dispatches `executor` for the CLI calls; primary never claims to run the browser CLI itself
  - [ ] Skill usage excerpts are embedded in the dispatch prompt (subagents don't load skills themselves)
  - [ ] `executor` receipt references the delegated browser-automation section and its evidence
  - [ ] One-off observation routes `browser`, not `e2e-tester` (no reusable test asset requested)
- **Pass criteria:** chain shape correct even in dry-run. **Runtime budget:** ~10 min live / ~3 min dry-run, 1 dispatch.

## 6. Scoring & Escalation

- **Any FAIL box** → append the finding to `references/lessons.md` (§ Append Log) and pick one remediation:
  - **Wording reinforcement** — add clarification to agent bodies or references, placed **outside the hashed synced block** so `check-agents.ps1` byte comparison stays green;
  - **Model-tier escalation** — move the failing agent to a stronger model (Dimension C override);
  - **Static-gate extension** — push the pattern into `scripts/check-agents.ps1` (file level) or `scripts/check-receipt.ps1` (receipt-shape level) so future drift is caught mechanically before a drill has to find it.
- **Two consecutive FAILs on the same expectation** → treat as structural, not noise: open a training round (re-state the expectation in the SSOT contract, propagate, re-drill S1–S3 before closing the round).
- **The log closes the loop:** all three primary agents consult `references/lessons.md` before complex dispatches and large edit batches — a FAIL recorded here already changes routing behavior before the next drill runs.
- A drill is only as good as its log: no dated `lessons.md` entry, no verified run.
