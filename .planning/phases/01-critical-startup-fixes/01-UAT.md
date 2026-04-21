---
status: partial
phase: 01-critical-startup-fixes
source:
  - 01-01-SUMMARY.md
  - 01-02-SUMMARY.md
  - 01-03-SUMMARY.md
started: 2026-04-21T12:00:00Z
updated: 2026-04-21T12:00:00Z
---

## Current Test

number: 1
name: New interactive shell (Cursor / minimal parent PATH)
expected: |
  Open a new terminal tab or window. There should be no "command not found" for
  mkdir, uname, date, stat, grep, fzf, zoxide, or starship. The prompt should load.
awaiting: user response

## Tests

### 1. New shell after PATH hotfix
expected: |
  No `command not found` for core utilities; `clipsort` alias loads without `no matches found`.
result: issue
reported: |
  User: new shell fails with mkdir/uname/date/stat/grep/awk/fzf/zoxide/starship not found;
  python3 not on PATH for autoswitch-virtualenv.
severity: major

### 2. Automated smoke (minimal parent environment)
expected: |
  `env -i HOME=$HOME USER=$USER TERM=xterm-256color zsh -i -c 'command -v starship'` resolves to Homebrew starship.
result: pass

## Summary

total: 2
passed: 1
issues: 1
pending: 1
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
