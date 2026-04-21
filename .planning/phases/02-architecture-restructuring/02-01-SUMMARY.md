---
phase: 02-architecture-restructuring
plan: "02-01"
subsystem: shell
tags: [zsh, zshenv, zprofile, arch]

requires: []
provides:
  - Tracked minimal `~/dotfiles/.zshenv` and login `~/dotfiles/.zprofile`
  - Deployed copies under `$HOME` with Obsidian PATH preserved as local-only tail
affects: [02-02, 02-03]

tech-stack:
  added: []
  patterns: [typeset -U path; brew shellenv guard; export PATH j.: join]

key-files:
  created:
    - .zshenv
    - .zprofile
  modified:
    - .planning/phases/02-architecture-restructuring/02-DISCUSSION-LOG.md

key-decisions:
  - "Home `~/.zprofile` intentionally differs from repo: Obsidian PATH under ## Local overrides (not in dotfiles)."

patterns-established: [ARCH-01 zshenv split, ARCH-02 zprofile PATH]

requirements-completed: [ARCH-01, ARCH-02]

duration: resumed
completed: 2026-04-21
---

# Phase 2: Plan 02-01 Summary

Added canonical **`.zshenv`** (minimal env, PATH bootstrap when `mkdir` missing) and **`.zprofile`** (guarded `brew shellenv`, single `path=(…)` + `${(j.:.)path}` export). Deployed to `$HOME`; documented Obsidian-only tail in discussion log because it is not tracked.

## Verification

- `zsh -n` on both repo files
- `diff -q ~/dotfiles/.zshenv ~/.zshenv` matches
- `~/.zprofile` differs only by documented local overrides block
