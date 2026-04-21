# Phase 2: Architecture Restructuring - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning
**Mode:** Smart discuss — infrastructure phase (autonomous-smart-discuss.md: skip grey-area tables; ROADMAP success criteria are technical)

<domain>
## Phase Boundary

Establish the macOS zsh startup split described in `.planning/ROADMAP.md`: minimal `~/.zshenv`, login-only `~/.zprofile` (Homebrew `path` + `brew shellenv`), and interactive `~/dotfiles/.zshrc` with the documented sourcing order. Merge `completions.zsh` into `.zshrc`, ensure a single `compinit`, move Docker `fpath` before `compinit`, load `fast-syntax-highlighting` as the last Zap plugin, and add optional `~/.zshrc.local`. **In the same phase**, treat **`~/dotfiles/.zsh.aliases`** and **`~/dotfiles/.zsh.functions`** as first-class efficiency scope (plan **02-04**): inventory pipeline-heavy aliases and fork-heavy functions, apply targeted improvements or document explicit no-ops, without changing semantics of security/daily workflows. Preserve Phase 1 outcomes: thin home `~/.zshrc` sourcing dotfiles, `${(j.:.)path}` PATH exports, early PATH bootstrap when `mkdir` is missing, and cargo/bun only from interactive config.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion

All file moves and ordering details are at implementer discretion within ROADMAP success criteria and `ARCH-01`–`ARCH-07` in `.planning/REQUIREMENTS.md`, provided behavior matches Phase 1 benchmarks and zero functionality loss (PROJECT.md core value).

### Locked from Phase 1 (do not regress)

- Home `~/.zshrc` remains a thin `source` of `~/dotfiles/.zshrc` unless Phase 6 symlink work explicitly replaces that pattern.
- No return of Cursor agent shell-integration eval in tracked configs.
- PATH must remain colon-separated (`${(j.:.)path}`); never `${path[*]}` for `export PATH=`.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets

- `~/dotfiles/.zshrc` — single large interactive file; Phase 2 target for reorder and completion merge (see `.planning/codebase/STRUCTURE.md`).
- `~/dotfiles/completions.zsh` — completion zstyles and cache; to be inlined per ROADMAP Phase 2 plan 02-02.
- `~/dotfiles/.zsh.aliases`, `~/dotfiles/.zsh.functions` — stay sourced from `.zshrc`; not moved in Phase 2 unless plans say otherwise.

### Established Patterns

- Zap plugins under `~/.local/share/zap/plugins/`; `plug` ordering in `.zshrc` must respect “fast-syntax-highlighting last” per roadmap.
- Pyenv lazy function and completion path already optimized in Phase 1 — preserve when reshuffling blocks.

### Integration Points

- Deployed `~/.zprofile` (outside repo) currently sets brew PATH — align with ARCH-02 and avoid double PATH with new layout.
- `~/.zshenv` currently comment-only after Phase 1 — expand only within ARCH-01 minimalism (≤ 5 lines of real config).

</code_context>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — Phase 2 goal, success criteria, plan stubs 02-01 … 02-04
- `.planning/REQUIREMENTS.md` — ARCH-01 … ARCH-07, FIX-08, FIX-09
- `.planning/phases/01-critical-startup-fixes/01-CONTEXT.md` — decisions that constrain Phase 2
- `.planning/codebase/STRUCTURE.md`, `.planning/codebase/ARCHITECTURE.md` — file roles and startup notes

</canonical_refs>

<specifics>
## Specific Ideas

No additional user grey areas — infrastructure phase per autonomous smart-discuss rules.

</specifics>

<deferred>
## Deferred Ideas

- Keybinding / Starship hook fixes remain Phase 3 per roadmap dependency on Phase 2.

</deferred>

---

*Phase: 02-architecture-restructuring*
