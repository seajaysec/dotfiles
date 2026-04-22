---
phase: 07
slug: functionality-preservation
status: draft
created: 2026-04-21
reopened: 2026-04-22
---

# Phase 7 — Functionality preservation

**Reopened** with milestone phases 3–9: prior `passed` was premature. Use this file for **evidence-backed** UAT (commands + outcome), not checkbox theater.

## Automated (re-run each close attempt)

- `zsh -n` on all sourced configs
- `zsh -fc 'source ~/.zshrc'` (or `$DOTFILES/.zshrc` when testing non-default layout)

## Human (unchanged)

- tmux / iTerm / SwiftBar / Brewfile parity, subjective startup feel.
