# Phase 2: Architecture Restructuring — Research

**Researched:** 2026-04-21  
**Status:** Complete

## RESEARCH COMPLETE

## Summary

Phase 2 applies the **flat split** pattern (see `.planning/research/ARCHITECTURE.md`): keep `.zshrc` + `.zsh.aliases` + `.zsh.functions`, add **canonical `.zshenv` and `.zprofile`** (repo + home), merge `completions.zsh` into `.zshrc`, fix **plugin / compinit order** (`fast-syntax-highlighting` last; all `fpath` before `compinit`), fix **`$ZSH_CACHE_DIR`** (undefined today in `completions.zsh`), add **`~/.zshrc.local`**, and align **Starship** as the last interactive tool `eval` where roadmap requires ARCH-06.

**Aliases & functions (efficiency, not only load order):** `.zsh.aliases` contains many piped `grep`/`awk` chains (e.g. `lsock*`, clipboard helpers); `.zsh.functions` is large with diagnostics that spawn subprocess trees (`ifconfig`, `docker`, `ping`). Plan **02-04** inventories these, prefers **`rg`** only where flags/output are equivalent, collapses `grep|awk` to single-stage tools when safe, and defers risky changes to Phase 4 (**FIX-02** / **FIX-03** alias→function) when behavior is ambiguous. Completion **zstyle** and **compinit** efficiency remain owned by **02-02**.

macOS Terminal/iTerm tabs are typically **login + interactive**, so `.zprofile` runs per tab; subshells inherit `PATH` without re-sourcing `.zprofile`.

## Key decisions (for planners)

| Topic | Recommendation |
|-------|----------------|
| `.zshenv` | Roadmap success criterion: `typeset -U`, `EDITOR`, `VISUAL`, ≤5 lines of *config*. No `eval`. Optional one-line **PATH bootstrap** only if needed for Cursor-style empty `PATH` (counts toward line budget — prefer reuse of Phase 1 pattern, moved from `.zshrc` if it fits). |
| `.zprofile` | `eval "$(/opt/homebrew/bin/brew shellenv)"` (guard if file missing), then `typeset -U path` + `path+=(…)` for login PATH. Avoid duplicating the entire interactive `path=(…)` block from `.zshrc` until `.zshrc` is slimmed in plan 02-02. |
| `completions.zsh` | Inline into `.zshrc` **once**; remove duplicate `zstyle`/menu rules that conflict with existing `.zshrc` `zstyle` after `compinit`. Replace `$ZSH_CACHE_DIR` with e.g. `$HOME/.cache/zsh` or `$HOME/.zsh/cache` (create dir in task). |
| Plugin order (FIX-08) | Load **fast-syntax-highlighting** after other Zap plugins (last `plug`). |
| Docker fpath (FIX-09) | If `brew --prefix docker-completion` exists, `fpath+=` that site-functions dir **before** `compinit`. If absent, document skip in SUMMARY. |
| `.zshrc.local` (ARCH-7) | Source at end of `.zshrc` (after PATH dedupe or immediately before dedupe — pick one and document); keep `secrets.sh` sourced until user migrates secrets into `.zshrc.local` (note in plan, do not delete secrets line without replacement story). |

## Risks

- **PATH regression:** Moving PATH build to `.zprofile` without trimming `.zshrc` duplicates → double PATH or missing tools in non-login shells. Mitigation: document `zsh -il` vs `zsh -i` test matrix in plans.
- **Non-login interactive shells:** Rare on macOS; if `PATH` incomplete, `.zshenv` bootstrap line covers.
- **Merge conflicts:** `completions.zsh` and `.zshrc` both set completion zstyles — dedupe during merge.

## References

- `.planning/research/ARCHITECTURE.md` — sourcing order, zshenv/zprofile/zshrc split
- `.planning/phases/02-architecture-restructuring/02-CONTEXT.md`
- `.planning/phases/01-critical-startup-fixes/01-CONTEXT.md` — Phase 1 locks (`${(j.:.)path}`, thin `~/.zshrc`)

---

## Validation Architecture

Phase 2 has **no unit-test framework** for shell config. Verification is **static + manual smoke**.

| Dimension | Approach |
|-----------|----------|
| Syntax | `zsh -n ~/dotfiles/.zshrc` after each structural edit |
| Login PATH | `zsh -il -c 'command -v brew; command -v python3'` |
| Interactive | `zsh -i -c 'command -v starship; autoload +X compinit'` |
| Completion cache dir | Test `[ -d "${ZSH_COMPDUMP%/*}" ]` or chosen cache path exists |

Sampling: after **each plan’s final task**, run `zsh -n` on edited files. After phase: open new terminal tab (human) or `env -i … zsh -i -c exit` smoke.
