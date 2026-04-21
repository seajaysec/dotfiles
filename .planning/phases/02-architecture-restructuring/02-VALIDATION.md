---
phase: 02
slug: architecture-restructuring
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 02 — Validation Strategy

> Shell configuration phase — no pytest/jest; verification is `zsh -n`, path checks, and manual tab smoke.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — zsh built-in checks |
| **Config file** | `~/dotfiles/.zshrc`, `~/dotfiles/.zshenv`, `~/dotfiles/.zprofile` (as created in repo) |
| **Quick run command** | `zsh -n ~/dotfiles/.zshrc && zsh -n ~/dotfiles/.zshenv 2>/dev/null; zsh -n ~/dotfiles/.zprofile 2>/dev/null` |
| **Full suite command** | Same as quick + `zsh -i -c 'command -v starship; command -v compdef'` |
| **Estimated runtime** | &lt; 5 seconds |

---

## Sampling Rate

- **After every task commit:** Quick `zsh -n` on any file touched
- **After every plan wave:** Full quick command on all three startup files
- **Before `/gsd-verify-work`:** New tab smoke (manual) documented in UAT

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-1 | 02-01 | 1 | ARCH-01 | T1 | No secrets in tracked zshenv | shell | `zsh -n .zshenv` | ✅ | ⬜ |
| 02-01-2 | 02-01 | 1 | ARCH-02 | T2 | brew shellenv guarded | shell | `zsh -n .zprofile` | ✅ | ⬜ |
| 02-02-1 | 02-02 | 2 | ARCH-04, ARCH-05 | T3 | single compinit | shell | `grep -c compinit .zshrc` = 1 | ✅ | ⬜ |
| 02-03-1 | 02-03 | 3 | FIX-08, FIX-09 | T4 | fpath order | shell | `grep -n plug .zshrc` order check | ✅ | ⬜ |
| 02-04-1 | 02-04 | 4 | EFF-01 | T1 | Inventory logged | manual | `grep -c '## Aliases inventory' 02-DISCUSSION-LOG.md` ≥ 1 | ✅ | ⬜ |
| 02-04-2 | 02-04 | 4 | EFF-02, EFF-03 | T2 | Syntax + semantics | shell | `zsh -n .zsh.aliases`; `zsh -fc 'source ~/.zshrc'` smoke optional | ✅ | ⬜ |

---

## Wave 0 Requirements

Existing infrastructure covers requirements — no new test framework. Wave 0 = **syntax checks only**.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| New tab loads | ARCH-03 | GUI / integration | Open new Terminal or Cursor tab; confirm prompt, no `command not found` spam |
| Tab-completion menu | ARCH-05 | UI | Type partial command, Tab twice — menu appears |

---

## Validation Sign-Off

- [x] All tasks have shell verify commands or manual table above (including plan 02-04)
- [x] Sampling: zsh -n between edits
- [x] No watch-mode flags
- [ ] `nyquist_compliant: true` set after execute-phase passes

**Approval:** pending
