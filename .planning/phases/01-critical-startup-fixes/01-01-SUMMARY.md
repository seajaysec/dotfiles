---
phase: 01-critical-startup-fixes
plan: "01-01"
subsystem: shell
tags: [zsh, perf, cursor]

requires: []
provides:
  - Clean interactive zsh startup without Cursor agent shell-integration eval
  - Baseline `time zsh -i -c exit` samples for later plans
affects: [01-02, 01-03]

tech-stack:
  added: []
  patterns: [Edit deployed ~/.zshrc when it is not symlinked to repo]

key-files:
  created: []
  modified:
    - .planning/phases/01-critical-startup-fixes/01-DISCUSSION-LOG.md

key-decisions:
  - "Removed agent shell-integration from ~/.zshrc (deployed); dotfiles/.zshrc was already clean"

patterns-established: []

requirements-completed: [PERF-02, PERF-01]

duration: 15min
completed: 2026-04-21
---

# Phase 1: Plan 01-01 Summary

Removed the blocking Cursor agent shell-integration `eval` from the deployed `~/.zshrc` and recorded three cold/warm `time zsh -i -c exit` samples for comparison in later plans.

## Performance

- **Tasks:** 2
- **Files modified:** 1 (repo); `~/.zshrc` edited outside repo

## Accomplishments

- PERF-02: no `agent shell-integration` in `~/dotfiles/.zshrc` or `~/.zshrc`
- Recorded startup benchmark section for plan 01-01 in discussion log

## Task Commits

1. **Task 1: Remove agent eval** — `e576f78` (feat)
2. **Task 2: Startup benchmark** — `d60af5a` (docs)

## Files Created/Modified

- `~/.zshrc` — Removed first-line `eval "$(~/.local/bin/agent shell-integration zsh)"` (not tracked in this repo)
- `.planning/phases/01-critical-startup-fixes/01-DISCUSSION-LOG.md` — PERF-02 note and benchmark numbers

## Self-Check: PASSED

- `grep -Ei 'agent shell-integration' ~/dotfiles/.zshrc` → exit 1
- `grep -Ei 'agent shell-integration' ~/.zshrc` → exit 1
- Discussion log contains `## Startup benchmark (plan 01-01)` with three timing lines
