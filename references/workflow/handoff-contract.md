# Subagent Handoff Contract (SSOT)

> This document is the authoritative definition of the receipt every subagent must emit at the top of its final output. The identical block is embedded in every subagent's system prompt. See section 4 for how to change it.

## 1. Metadata header — four fields

Every subagent presents this header before its detailed output:

    ---
    **Agent**: <agent name, i.e. the file name minus .md>
    **Status**: [done | partial | blocked | needs_input]
    **Suggest Next**: [agent names, e.g. "code-generator, devops" or "none"]
    **Context For Next**: [key decisions, constraints, gaps the next agent needs]
    ---

Field purposes, one per field:

- **Agent** — which subagent produced this receipt; always the delegation name (file name minus `.md`).
- **Status** — exactly one of the four values defined in the synced block; the bracket menu is replaced by the chosen word.
- **Suggest Next** — which agent(s) the primary should dispatch next, comma-separated, or `none`.
- **Context For Next** — decisions, constraints and gaps carried forward; when Status is `partial` or `blocked` this field is mandatory and must name the exact gap plus what the next agent must change.

## 2. The synced block

The seven lines below are copied **verbatim** into every subagent file under `agents/` (every file except `smart-router.md`, `Zero.md`, `Erribaba.md` — the three primaries consume the contract instead of emitting it). Keep the block contiguous and byte-identical in every copy.

**Status semantics:**
- `done` — deliverable complete AND evidence read in this message
- `partial` — usable output exists but a named gap remains (put the gap in `Context For Next`)
- `blocked` — cannot proceed without info/permission you do not have
- `needs_input` — a decision only the user can make (primary will ask via the question tool)

Fill in exactly one value — literally `done`, `partial`, `blocked`, or `needs_input`; never leave the bracket menu. For `partial`/`blocked`, `Context For Next` is mandatory and must name the exact gap + what the next agent should do differently.

Reading guide (not part of the synced block):

- `done` claims require evidence actually read in the same message — a plan to verify is not verification.
- `partial` is the honest "usable but incomplete" answer; the named gap belongs in `Context For Next`.
- `blocked` means the missing input is not the user's call to make (info/permission), while `needs_input` means it is; the primary asks the user via the question tool.
- The final line of the block is the mandatory-value rule: one literal word out of the four, and a mandatory `Context For Next` naming the gap whenever the answer is `partial` or `blocked`.

## 3. Exception — spec-reviewer's Gate -> Status mapping

`spec-reviewer` additionally reports an internal review field in its detailed output: `Gate: pass | fail`. Gate is INTERNAL — it never replaces or extends the four metadata fields. Its mapping into the contract's Status values:

- `done` — only when the overall gate passes (every in-scope claim is `pass` with evidence). Never emit `done` when the gate result is `fail`.
- `partial` — the gate fails on at least one in-scope claim (`fail` or `unverifiable`); the failing claim IDs go into `Context For Next`.
- `blocked` — the spec or the diff is missing or insufficient to review.
- `needs_input` — unchanged from the synced block.

## 4. Sync rule

This file is the single source of truth. To change the contract: edit HERE first, then propagate the exact block to every subagent via scripts/check-agents.ps1 -Sync (or manual copy). The script fails if any copy drifts.

Enforcement detail: `scripts/check-agents.ps1` extracts the block from every subagent file and from this document — from the `**Status semantics:**` line through the `Fill in exactly one value ...` line — normalizes line endings to LF, and SHA256-compares all copies. CRLF/LF differences alone are not treated as drift; any text difference is. The `-Sync` propagation mode is implemented: run `pwsh -NoProfile -File scripts/check-agents.ps1 -Sync` to propagate this block to every subagent copy in one command (preserves each file's line endings; audit runs automatically after sync).
