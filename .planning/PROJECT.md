# Dotfiles Overhaul

## What This Is

A comprehensive review and modernization of a macOS terminal environment (zsh, tmux, aliases, functions, install tooling) that has accumulated years of cruft, conflicting configurations, and structural issues causing startup hangs. The goal is a fast, clean, correct shell that preserves every piece of existing functionality while eliminating dead weight, fixing bugs, and establishing a maintainable architecture.

## Core Value

Every function, alias, and keybinding the user relies on must continue to work exactly as expected — zero functionality loss — while making the shell start instantly and the configs easy to maintain.

## Requirements

### Validated

These capabilities exist in the current codebase and must be preserved:

- ✓ Zsh as default shell with vi-mode editing and cursor shape feedback — existing
- ✓ Starship prompt with custom Gruvbox Dark theme — existing
- ✓ Zap plugin manager with 5 plugins (fast-syntax-highlighting, autosuggestions, history-substring-search, you-should-use, autoswitch-virtualenv) — existing
- ✓ Modern CLI replacements: eza, bat, ripgrep, fd, zoxide, delta — existing
- ✓ fzf with ag backend, bat preview, custom keybindings — existing
- ✓ bat as PAGER and MANPAGER — existing
- ✓ pyenv with optimized lazy-load wrapper (no subshell) — existing
- ✓ Go, Rust/Cargo, Bun, Node/npm runtimes on PATH — existing
- ✓ History: 10M lines, extended format, dedup, share across sessions — existing
- ✓ Daily-cached compinit for fast completion init — existing
- ✓ tmux with gpakosz base + Dracula local overrides + TPM plugins — existing
- ✓ Security/pentesting functions: grepip, grepeml, iplist, whocerts, cve40438, nmapr — existing
- ✓ Network diagnostics: dualping, localip, publicip — existing
- ✓ Git workflow: finish-branch, git_current_branch, git_main_branch, gcx, gistx — existing
- ✓ Clipboard/text wrangling: pb2csv, clipsort, srt, uniqip, impaste, grepcve — existing
- ✓ Python dev: pipr, ipy, srcenv, de — existing
- ✓ System maintenance: brewup (via bubu), bcbc, btfix, flushDNS, audiofix — existing
- ✓ Media conversion: m2d, mp4togif — existing
- ✓ File operations: mcd, fatsort_volume, alph_sort, remove_dups — existing
- ✓ Docker management: dockstop, dockrm — existing
- ✓ SwiftBar plugins: Zoom, Slack, tail, tmux — existing
- ✓ iTerm2 shell integration — existing
- ✓ Homebrew auto-maintenance via brewup.sh — existing
- ✓ Global gitignore — existing
- ✓ zoxide aliased as cd — existing
- ✓ Keybindings: arrow history-substring-search, word movement, home/end, vi-mode menu select — existing
- ✓ Auto-ls on directory change — existing
- ✓ REPORTTIME=10 for slow command alerts — existing

### Active

- [ ] Fix startup hang caused by Cursor agent `exec` replacement and slow eval
- [ ] Fix `bindkey -v` wiping all emacs-mode keybindings set before it
- [ ] Fix `precmd()`/`preexec()` overwriting starship's hook functions
- [ ] Fix `zle-keymap-select` overwriting starship's keymap widget
- [ ] Fix `ARCHFLAGS="-arch x86_64"` on Apple Silicon (should be arm64)
- [ ] Fix `fff` alias (aliases don't accept `$1` — convert to function)
- [ ] Fix `audiofix` alias (backtick evaluation at parse time — use `$()`)
- [ ] Fix Docker completions added to fpath after compinit
- [ ] Fix `$ZSH_CACHE_DIR` reference in completions.zsh (oh-my-zsh variable, undefined)
- [ ] Remove oh-my-zsh vestiges: `export ZSH`, `unset ZSH`, `unset ZSH_THEME`, `DISABLE_AUTO_UPDATE`
- [ ] Remove dead `source ~/secrets.sh` (file is empty)
- [ ] Remove unused Mono framework export
- [ ] Remove unused `.p10k.zsh`
- [ ] Remove deleted Kali/ directory from git
- [ ] Eliminate double-loading of cargo env and bun completions (.zshenv + .zshrc)
- [ ] Eliminate redundant PATH construction (currently rebuilt 5+ times)
- [ ] Consolidate completion system — merge completions.zsh into .zshrc or vice versa, eliminate conflicting zstyle rules
- [ ] Fix `HIST_STAMPS` set twice with different values
- [ ] Reconcile repo vs deployed .zshrc divergence
- [ ] Replace cp-based install with symlinks for .zshrc
- [ ] Remove or replace Cursor agent shell integration with lighter approach
- [ ] Establish correct .zshenv / .zprofile / .zshrc separation
- [ ] Ensure keybindings work correctly with vi-mode (set vi-mode first, then add emacs-style convenience bindings in viins keymap)
- [ ] Clean up stale .zcompdump files
- [ ] Optimize startup time (target: under 500ms)
- [ ] Fix pyenv completions hardcoded to specific Cellar version path (deployed)

### Out of Scope

- Switching from Zap to another plugin manager — Zap is correct, just needs cleanup
- Switching from Starship to another prompt — Starship is correct
- Rewriting tmux config — .tmux.conf is gpakosz framework (don't touch), .tmux.conf.local is fine
- Adding new functionality — this is a cleanup/fix project, not a feature project
- Cross-platform portability — this is macOS-only, keep it that way

## Context

- This is a brownfield dotfiles repo accumulated over years
- User is a security professional / developer who uses the terminal heavily
- Zero tolerance for lost functionality — every alias, function, and keybinding must survive
- The deployed `~/.zshrc` has diverged from the repo version due to cp-based install
- The deployed version includes Cursor agent shell integration (`eval "$(~/.local/bin/agent shell-integration zsh)"`) which takes 1.47s and uses `exec` to replace the shell process — primary hang suspect
- `.zshenv` and `.zprofile` exist outside the repo and are not tracked
- `.p10k.zsh` is a ~1600-line Powerlevel10k config that's completely unused (Starship replaced it)
- The Kali/ directory has been deleted but not committed

### Diagnosed Issues Inventory

**Startup performance:**
- Cursor agent shell integration: 1.47s (exec replacement — hang risk)
- Starship init: 54ms, Zoxide init: 11ms, fzf: 21ms (all fine)
- MANPATH subshell pipeline at source time
- Double compinit path (completions.zsh + .zshrc)
- Four stale .zcompdump files on disk

**Ordering / override bugs:**
- `bindkey -v` (line 230) wipes all emacs bindings set on earlier lines
- `precmd()` definition (line 246) shadows starship's `prompt_starship_precmd` in `precmd_functions`
- `zle-keymap-select` (line 244) overwrites starship's `starship_zle-keymap-select`
- Docker fpath addition after compinit means docker completions never load

**Dead code:**
- oh-my-zsh: `export ZSH=~/.oh-my-zsh`, `unset ZSH`, `unset ZSH_THEME`, `DISABLE_AUTO_UPDATE`
- `source ~/secrets.sh` — file is empty (0 bytes)
- `export MONO_GAC_PREFIX="/usr/local"` — likely unused
- `.p10k.zsh` — 1600 lines, never sourced
- `.fzf.zsh` — legacy, replaced by `source <(fzf --zsh)`

**Double-loading:**
- cargo env: `.zshenv` line 1 + `.zshrc` line 205
- bun completions: `.zshenv` line 4 + `.zshrc` line 202
- `/opt/homebrew/bin` in PATH: `.zprofile` + `.zshrc` typeset array

## Constraints

- **Zero functionality loss**: Every alias, function, and keybinding must be preserved or improved (never silently dropped)
- **macOS only**: No need for Linux/cross-platform. Apple Silicon (ARM64) is the target
- **Repo as source of truth**: After this work, the repo must be the canonical source, deployed via symlinks
- **No new frameworks**: Fix what's there, don't introduce new plugin managers or prompt engines

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep Zap + Starship | Modern, fast, already migrated. Validated by benchmarks | — Pending |
| Remove Cursor agent shell-integration from .zshrc | 1.47s + exec replacement = hang risk. Handle via Cursor-native mechanism or skill | — Pending |
| Switch install.sh from cp to symlinks for .zshrc | Prevents deployed/repo divergence. Aliases/functions already sourced from repo | — Pending |
| Establish .zshenv/.zprofile/.zshrc separation | .zshenv = minimal (PATH only), .zprofile = login-only (brew shellenv), .zshrc = interactive | — Pending |
| Vi-mode first, then emacs convenience bindings in viins | Prevents bindkey -v from wiping bindings. Standard practice for hybrid vi/emacs | — Pending |
| Remove .p10k.zsh from repo | Completely unused since Starship migration. 1600 lines of dead config | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-21 after initialization*
