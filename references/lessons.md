# Lessons Learned — Agentcrew Field Log

> A living document. Every entry below is a scar or a verified win from real work
> on this repo — model behavior, environment traps, process findings.
> Nothing here is theoretical.

## Purpose

This file accumulates field lessons for the agentcrew. It complements the
consistency gate (`scripts/check-agents.ps1`), which checks **files**: byte-identical
handoff contracts, badge families, roster coverage, table/directory reconciliation.
The gate cannot see the other half of what goes wrong in practice:

- **Model behavior** — whether an agent actually follows the prompt it was handed.
- **Environment traps** — PowerShell encoding, terminal rendering, git stderr quirks.
- **Process findings** — how multi-agent coordination succeeds or fails under real load.

Those lessons live here.

## How to use

1. **Primary agents consult this file at two moments:**
   - BEFORE dispatching complex or multi-agent work.
   - BEFORE any large edit batch (multi-file fixes).
2. **Every AAR / behavioral-drill result appends a dated entry here** — the drill
   program itself is defined in `references/workflow/drill-playbook.md`; the entry
   format is defined in the Append Log convention section at the bottom of this file.
3. The four category sections hold the distilled rules. The Append Log holds new
   entries as they arrive; promote a stable entry into its category section once it
   stops being surprising.

## Table of contents

- [Encoding & Environment Traps](#encoding--environment-traps)
- [Model Behavior & Compliance](#model-behavior--compliance)
- [Process & Coordination](#process--coordination)
- [Git & Tooling](#git--tooling)
- [Append Log convention](#append-log-convention)
- [Append Log](#append-log)

---

## Encoding & Environment Traps

The most expensive bugs in this repo were never logic errors — they were the
platform reading files differently than we did.

- **PowerShell 5.1 misreads UTF-8 no-BOM files as GBK — always read via .NET `File` APIs with an explicit UTF-8 encoding, and keep `.ps1` sources pure ASCII.**
  Evidence: round-1 audit false alarms; the constraint is now baked into the checker script's design.

- **Console mojibake (GBK terminal) is a DISPLAY artifact, not file corruption — verify file state via `git diff` or the read tool, never via console echo.**
  Evidence: repeated false corruption alarms across sessions, each dissolved by reading the file directly.

- **PowerShell pipeline truncation (`Select-Object -First N`) sets `$LASTEXITCODE=1` spuriously — read the full output, or drop the truncation whenever exit codes matter.**
  Evidence: a clean run appeared to fail solely because the output was piped through `-First`.

- **git stderr progress lines surface as PowerShell `NativeCommandError` — check `$LASTEXITCODE`, not the red text.**
  Evidence: `git push` reported an "error" in red while the push itself succeeded.

- **The repo has mixed line endings — CRLF in docs, LF in agents — normalize line endings in any hash comparison.**
  Evidence: the checker script's contract-hash design had to normalize before hashing to avoid false drift.

- **Emoji need consistent VS16 (U+FE0F) forms for byte-level comparisons; the badge gate is VS16-insensitive by design.**
  Evidence: the 38-badge rollout verified zero drift only after the gate stopped caring about variation selectors.

---

## Model Behavior & Compliance

A perfect prompt file does not guarantee perfect behavior. Compliance is measured,
never assumed.

- **File-perfect contract does not mean the model follows it: flash-tier agents dropped the entire metadata header, and spec-reviewer used legacy `Status` vocabulary, DESPITE byte-identical prompt blocks — reinforcement sentences must live OUTSIDE the hashed contract block; if drift recurs after reinforcement, escalate to a model-tier upgrade, not more wording.** [CORRECTION 2026-10-22: see Append Log — the drill ran against a stale local config (pre-training prompts); spec-reviewer's legacy vocabulary was old-prompt fidelity, NOT model disobedience. The lite dropped-header finding still stands as an old-prompt compliance failure; compliance with the NEW reinforced prompts remains untested.]
  Evidence: the first behavior drill.

- **Verify WHICH prompt version the runtime actually loaded before attributing behavior to the model** — the local config (~/.config/opencode/agents) silently lags the repo; the first drill tested the pre-training snapshot, producing a false misattribution. Diff local config against the repo (or confirm a fresh install) before trusting any behavioral finding. (evidence: 38/38 local files stale; install.ps1 had never been run this session)

- **Pro-tier (`mimo-v2.6-pro`) showed 100% contract compliance in the drill while flash / deepseek-flash tiers degrade — weight critical-coordination roles toward pro when budget allows.**
  Evidence: drill scenario 2 vs scenario 1.

- **Weak models follow placement cues: a strengthening sentence placed immediately after the artifact it protects outperforms the same rule stated far away in the prompt.**
  Evidence: the lite-header reinforcement placement.

---

## Process & Coordination

What the org chart cannot tell you — how parallel agents and multi-round fixes
actually behave under load.

- **Parallel zone execution with disjoint file ownership works at 4–5 way concurrency — but execution agents MUST report judgment calls in `Context For Next` for the primary to rule on.**
  Evidence: the validator-retention call and the T2/T3 tier tension were both caught this way.

- **Large fix batches CAN introduce new contradictions: always run two-stage review after multi-file edit batches, never ship on implementer self-reports.**
  Evidence: after Round-4 fixes, Stage-2 review found 2 Critical self-inflicted conflicts — the complex-column vs two-stage-gate conflict, and executor not inheriting the browser domain.

- **The New Agent Checklist paid for itself on the 39th agent (`api-designer-lite`) — first try, zero missed sync points; keep the checklist authoritative.**
  Evidence: positive result from the agent-39 rollout.

- **The consistency gate's badge map is an intentional maintenance ratchet: an unmapped new agent = red gate, by design — extend the map, never weaken the check.**
  Evidence: the gate's stated design constraint, exercised on every badge-family addition.

---

## Git & Tooling

- **Before `git add -A`, run `git status --porcelain` and exclude unrelated untracked files.**
  Evidence: a stray `share-zip` directory was nearly swept into an unrelated commit.

- **Behavioral drills need a scratch worktree (`tools.opencode.worktree_create`) so drill artifacts never pollute the main repo; remove it with `force=true` only after explicit user confirmation.**
  Evidence: the agent-drill worktree lifecycle.

---

## Append Log convention

New lessons are appended under **Append Log** below. Format, exactly one entry per
lesson:

```markdown
### YYYY-MM-DD — <category> — <one-line lesson>
<one sentence of evidence>
```

Rules:

- `<category>` names one of the four sections above (short form is fine:
  `encoding`, `model`, `process`, `git`).
- The lesson line must stand alone — a future reader must grasp the rule without
  reopening the session transcript.
- Evidence is one sentence: what happened, and where it was observed.
- Once an entry stops being surprising, promote it into its category section
  (bold rule + evidence); leave the append-log entry in place as the record.
- Dates are real session dates, not backfills.

## Append Log

*(empty — new dated entries go here)*

### 2026-10-22 — environment — install.ps1 crashed under Windows PowerShell 5.1 (UTF-8 no-BOM + GBK); pwsh 7 bypassed it
Evidence: direct `& install.ps1` → parser errors on markdown-table lines (here-string boundary broken by GBK mojibake); `pwsh -File install.ps1` → exit 0, 39 agents installed, content verified 0-diff after newline normalization. Fix: added UTF-8 BOM (parse errors → 0 under 5.1). The GBK trap is not theoretical — it broke the installer itself; any .ps1 shipping CJK text to 5.1 users needs a BOM, and pure-ASCII source (scripts/*.ps1) remains the stronger alternative.
