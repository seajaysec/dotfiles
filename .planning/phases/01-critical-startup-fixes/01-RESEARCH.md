# Phase 1 — Technical Research

**Phase:** 1 — Critical Startup Fixes  
**Question:** What do we need to know to plan startup performance fixes well?

---

## Findings

### Cursor agent shell integration (PERF-02)

- The hang is caused by `eval "$(… agent shell-integration zsh)"` (or similar) running at every interactive startup. Current **repo** `.zshrc` may already omit it; the **deployed** `~/.zshrc` symlink must be verified with `grep` so no variant remains.
- Removal is safe per CONTEXT D-01: rely on Cursor’s built-in terminal integration instead of zsh-side eval.

### Double-loading cargo and bun (PERF-03, PERF-04)

- `.zshrc` sources `~/.cargo/env` and `~/.bun/_bun` (lines ~190–191).
- CONTEXT D-02: remove these from **`~/.zshenv`** only (not necessarily from `.zshrc` until Phase 2), so non-interactive shells do not duplicate what `.zshrc` does for interactive sessions.
- **Note:** `~/.zshenv` is not in this git repo today; the executor must edit the real home file and record the change in the plan summary.

### PATH redundancy (PERF-05)

- `.zshrc` uses `typeset -U path` then repeatedly `export PATH="${path[*]}"` after each `path+=` block (Pyenv, Go, Bun). `typeset -U` dedupes the **array** but repeated exports are still churn.
- Minimal Phase-1 approach: collapse to one `path=(…)` construction where safe, or a single final `export PATH` after all `path+=` mutations, without removing required prefixes (pyenv shims first per current intent).

### MANPATH subshell (PERF-06)

- Current block (lines ~90–93) runs `manpath`, pipelines through `grep`/`paste`. CONTEXT D-04: **delete the entire block**; user confirmed no TeX requirement.

### `.zcompdump` hygiene (PERF-07)

- `compinit` uses `~/.zcompdump` with day-of-year check. Multiple stale dumps may exist under `~/.zcompdump*` or legacy names; plan should list/remove extras **after** compinit behavior is preserved in `.zshrc`.

### Benchmark (PERF-01)

- Authoritative measure: `time zsh -i -c exit` (cold vs warm). Target **< 200ms** after changes; document baseline in SUMMARY after execution.

---

## Pitfalls

- Editing only repo `.zshrc` while `~/.zshrc` is not symlinked → no user-visible fix. Verify symlink or copy path before closing tasks.
- Removing `~/.zshenv` cargo/bun lines without ensuring `.zshrc` still sources them → broken PATH in some login scenarios; keep `.zshrc` sources until Phase 2 validates `.zprofile` / login path.

---

## Validation Architecture

Phase 1 has **no unit-test framework** for shell config. Validation is **manual + CLI timing**:

| Dimension | Approach |
|-----------|----------|
| Performance | `time zsh -i -c exit` (repeat 3×, report median) |
| Correctness | `command -v` for `brew`, `pyenv`, `go`, `cargo`, `bun`, `node` after startup |
| Hygiene | `grep` for forbidden strings; `echo $PATH \| tr ':' '\n' \| sort \| uniq -d` empty |

Nyquist sampling: run the quick timing command after each task that touches startup files.

---

## RESEARCH COMPLETE
