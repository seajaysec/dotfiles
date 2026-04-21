---
status: complete
phase: 01-critical-startup-fixes
source:
  - 01-01-SUMMARY.md
  - 01-02-SUMMARY.md
  - 01-03-SUMMARY.md
started: 2026-04-21T12:00:00Z
updated: 2026-04-21T20:00:00Z
---

## Current Test

number: —
name: —
expected: |
  All planned checks for this UAT slice are done.
awaiting: none

## Tests

### 1. New interactive shell (Cursor / minimal parent PATH)
expected: |
  No `command not found` for core utilities; prompt and tools load normally.
result: pass
reported: "y (after PATH join + bootstrap + clipsort hotfix)"

### 2. Automated smoke (minimal parent environment)
expected: |
  `env -i HOME=$HOME USER=$USER TERM=xterm-256color zsh -i -c 'command -v starship'` resolves to Homebrew starship; no `command not found` during startup.
result: pass

### 3. Regression — full `.zsh.aliases` restored
expected: |
  Full `.zsh.aliases` (153 lines); only `clipsort` quoting changed from pre-hotfix baseline.
result: pass

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Interactive zsh finds standard UNIX utilities and Homebrew tools on PATH before Zap plugins run."
  status: resolved
  reason: "User reported widespread command-not-found after Phase 1."
  severity: blocker
  test: 1
  root_cause: "`export PATH=\"${path[*]}\"` joins the `path` array with IFS (space), producing an invalid PATH string (spaces where colons belong). Parent environments with empty PATH (e.g. Cursor) hit Zap/compinit before any usable PATH."
  artifacts:
    - .zshrc
  missing: []
  debug_session: ""

- truth: "clipsort alias parses without glob errors at source time."
  status: resolved
  reason: "Broken double-quote nesting in clipsort alias definition."
  severity: minor
  test: 1
  root_cause: "Outer double quotes ended before `^$`; zsh attempted filename generation on `clipsort=pbpaste | ...`."
  artifacts:
    - .zsh.aliases
  missing: []
  debug_session: ""
