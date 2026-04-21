---
phase: 01-critical-startup-fixes
plan: "01-02"
subsystem: shell
tags: [zsh, path, zshenv, perf]

requires:
  - plan: "01-01"
    provides: Cursor agent eval removed; startup benchmark baseline
provides:
  - Single interactive load of cargo and bun from dotfiles `.zshrc`
  - Reduced `export PATH=` count (5 → 3) with merged Go/Bun path updates
affects: [01-03]

tech-stack:
  added: []
  patterns: [Keep pyenv `export PATH="$PYENV_ROOT/shims:..."` line intact per plan]

key-files:
  created: []
  modified:
    - .zshrc
    - .planning/phases/01-critical-startup-fixes/01-DISCUSSION-LOG.md

key-decisions:
  - "Emptied cargo/bun hooks from ~/.zshenv; replaced with comment-only file"
  - "Dropped standalone Homebrew PATH export; merged final path+= exports"

patterns-established: []

requirements-completed: [PERF-03, PERF-04, PERF-05, PERF-01]

duration: 20min
completed: 2026-04-21
---

# Phase 1: Plan 01-02 Summary

Stopped double-sourcing Rust and Bun from `~/.zshenv`, kept a single guarded load in `~/dotfiles/.zshrc`, and cut redundant `export PATH=` lines without breaking `command -v cargo` / `command -v bun`.

## Accomplishments

- PERF-03/04: `~/.zshenv` no longer references cargo env or bun `_bun` script
- PERF-05: `grep -c '^export PATH='` on `.zshrc` is 3 (was 5)
- Startup `time zsh -i -c exit` improved vs plan 01-01 worst timing (documented in discussion log)

## Task Commits

1. **Task 1: zshenv dedupe** — `9a05a1e`
2. **Task 2: PATH consolidation** — `f773042`
3. **Task 3: Verification** — `aef3d13`

## Deviations

- Plan task 3 expected raw stdout exactly `OK\n`; iTerm2 / zle emit control sequences before `OK`. Logged evidence; exit code and `command -v` checks pass.

## Self-Check: PASSED

- `zsh -i -c 'command -v cargo; command -v bun'` prints two paths
- `grep -c '^export PATH=' ~/dotfiles/.zshrc` → 3
- `grep -qF '.cargo/env' ~/dotfiles/.zshrc` and bun `_bun` grep succeed
