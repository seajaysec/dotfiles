# Phase 1: Critical Startup Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `01-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-21
**Phase:** 1-Critical Startup Fixes
**Areas discussed:** Cursor agent replacement, Dedup destination, PATH consolidation depth, MANPATH TeX exclusion

---

## Cursor agent replacement

| Option | Description | Selected |
|--------|-------------|----------|
| Remove entirely | Delete eval; no replacement | |
| Remove from .zshrc, Cursor settings | Remove eval; Cursor injects / native integration | ✓ |
| You decide | Claude picks safest approach | |

**User's choice:** Remove from `.zshrc`, handle via Cursor settings / native mechanism.

**Notes:** Aligns with PERF-02 and PROJECT.md “lighter approach” intent.

---

## Dedup destination (cargo env, bun completions)

| Option | Description | Selected |
|--------|-------------|----------|
| Remove from .zshrc, keep .zshenv | Fewer edits now; Phase 2 moves again | |
| Remove from .zshenv, keep .zshrc | Aligns Phase 2 minimal `.zshenv` | ✓ |
| You decide | Claude picks | |

**User's choice:** Remove from `~/.zshenv`, keep in `.zshrc`.

**Notes:** Reduces rework when `.zshenv` is reduced to minimal contents in Phase 2.

---

## PATH consolidation depth

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal | Strip redundant exports only | |
| Consolidate | Single `path` array + one export | |
| You decide | Claude picks depth | ✓ |

**User's choice:** Claude’s discretion.

**Notes:** Balance Phase 1 cleanup vs Phase 2 file moves.

---

## MANPATH TeX exclusion

| Option | Description | Selected |
|--------|-------------|----------|
| No TeX — remove block | Drop MANPATH pipeline entirely | ✓ |
| Yes TeX — static exclusion | Replace pipeline with non-subshell exclusion | |
| Not sure — Claude checks | Detect TeX install and decide | |

**User's choice:** No TeX — remove whole MANPATH block.

**Notes:** Satisfies PERF-06 (no subshell MANPATH at source time).

---

## Claude's Discretion

- PATH consolidation depth (see PATH consolidation depth area).

## Deferred Ideas

None recorded.

## PERF-02 (plan 01-01 task 1)

Removed `eval "$(~/.local/bin/agent shell-integration zsh)"` from deployed `~/.zshrc` (home directory; not the same file as `~/dotfiles/.zshrc`). Tracked `~/dotfiles/.zshrc` had no agent shell-integration line.

## Startup benchmark (plan 01-01)

1.084
0.224
0.231
