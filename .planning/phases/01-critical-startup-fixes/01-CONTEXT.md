# Phase 1: Critical Startup Fixes - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminate the 1.47s Cursor agent shell-integration hang and all double-loading / redundant startup work so interactive zsh startup meets PERF-01 through PERF-07. This phase does not restructure `.zshenv` / `.zprofile` / `.zshrc` separation (Phase 2) — it only removes redundant work and the blocking eval within the current file layout.

</domain>

<decisions>
## Implementation Decisions

### Cursor agent / shell integration
- **D-01:** Remove Cursor agent `eval "$(… agent shell-integration zsh)"` (or equivalent) from `.zshrc`. Do not replace it with another in-dotfiles integration hook. Rely on Cursor’s native terminal / shell integration instead of a startup-time eval in zsh config.

### Double-load deduplication (cargo, bun)
- **D-02:** Remove `cargo` env and bun completions from `~/.zshenv` so they load only from `.zshrc` (interactive path). This aligns with Phase 2’s direction to slim `.zshenv` later and satisfies PERF-03 / PERF-04 for the current layout.

### PATH construction
- **D-03:** **Claude’s discretion** — consolidate PATH construction as needed to eliminate redundant `export PATH` churn and duplicate entries after startup, without dropping any required tool locations (Homebrew, pyenv, Go, Bun, cargo, npm, user bins, etc.). Prefer minimal diff if a deeper merge would fight Phase 2; prefer a single coherent `path` + one export if it stays clearly reversible.

### MANPATH
- **D-04:** Remove the entire MANPATH subshell block from `.zshrc`. User does not use TeX; no static TeX exclusion replacement is required (PERF-06: no subshell pipeline at source time for MANPATH).

### Claude's Discretion
- **D-03** (PATH depth and exact consolidation strategy) — planner/researcher may choose minimal vs fuller consolidation within Phase 1 boundary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, plan stubs (01-01 … 01-03)
- `.planning/REQUIREMENTS.md` — PERF-01 … PERF-07 traceability for Phase 1
- `.planning/PROJECT.md` — Core value, constraints, diagnosed issues inventory

### Research / architecture (supporting context)
- `.planning/research/SUMMARY.md` — consolidated research (if present and relevant to startup)
- `.planning/research/ARCHITECTURE.md` — shell startup architecture notes
- `.planning/codebase/STRUCTURE.md` — file roles (.zshrc, .zshenv, completions)
- `.planning/codebase/CONVENTIONS.md` — shell config conventions

No external ADR/spec URLs were referenced for this phase.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.zshrc` already uses `typeset -U path` and a `path=(...)` array — extend or dedupe rather than inventing a new pattern.
- Pyenv lazy wrapper and completion sourcing live in `.zshrc` — preserve behavior when touching PATH order.

### Established Patterns
- Aliases/functions stay in `~/dotfiles/.zsh.aliases` and `~/dotfiles/.zsh.functions`; Phase 1 should not move them.
- `completions.zsh` is sourced before `compinit` in `.zshrc` — Phase 1 does not merge completions (Phase 2 / ARCH-04).

### Integration Points
- Deployed `~/.zshenv` currently sources `~/.cargo/env` and `~/.bun/_bun` — edits required there when deduping (user home file, not in repo until INST-04).
- Deployed `~/.zprofile` sets brew `PATH` / `shellenv` — overlaps with `.zshrc` PATH; note for PERF-05 but full login/interactive split is Phase 2.

</code_context>

<specifics>
## Specific Ideas

- User explicitly chose **Cursor-native** handling over in-shell agent integration for terminal features.
- User confirmed **no TeX** — safe to drop MANPATH manipulation entirely.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-critical-startup-fixes*
*Context gathered: 2026-04-21*
