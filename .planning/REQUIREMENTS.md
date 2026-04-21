# Requirements: Dotfiles Overhaul

**Defined:** 2026-04-21
**Core Value:** Every function, alias, and keybinding the user relies on must continue to work exactly as expected — zero functionality loss — while making the shell start instantly and the configs easy to maintain.

## v1 Requirements

Requirements for this overhaul. Each maps to roadmap phases.

### Startup Performance

- [ ] **PERF-01**: Shell startup completes in under 200ms (measured via `time zsh -i -c exit`)
- [ ] **PERF-02**: Remove Cursor agent shell-integration eval from .zshrc (1.47s + exec hang risk)
- [ ] **PERF-03**: Eliminate double-loading of cargo env (.zshenv + .zshrc)
- [ ] **PERF-04**: Eliminate double-loading of bun completions (.zshenv + .zshrc)
- [ ] **PERF-05**: Eliminate redundant PATH construction (currently rebuilt 5+ times with export)
- [ ] **PERF-06**: Remove MANPATH subshell pipeline — use MANPATH array or static exclusion
- [ ] **PERF-07**: Clean up stale .zcompdump files (4 on disk)

### Keybinding Correctness

- [ ] **KEYS-01**: `bindkey -v` set before all other keybindings (not after, wiping them)
- [ ] **KEYS-02**: Emacs convenience bindings (ctrl-a, ctrl-e, word movement, arrow keys) work in vi insert mode via `-M viins`
- [ ] **KEYS-03**: History-substring-search arrow bindings work in vi insert mode
- [ ] **KEYS-04**: Vi-mode menu-select bindings (hjkl) work in completion menu
- [ ] **KEYS-05**: `KEYTIMEOUT` set to safe value (10 instead of 1) to avoid breaking multi-key sequences

### Hook & Prompt Correctness

- [ ] **HOOK-01**: Starship's precmd hook not overwritten — remove bare `precmd()` definition
- [ ] **HOOK-02**: Starship's preexec hook not overwritten — remove bare `preexec()` definition
- [ ] **HOOK-03**: Starship's `zle-keymap-select` widget not overwritten — remove custom widget or let Starship wrap it
- [ ] **HOOK-04**: Vi-mode cursor shape changes work correctly (beam in insert, block in normal)
- [ ] **HOOK-05**: `chpwd_functions` auto-ls hook preserved using `add-zsh-hook` pattern

### Bug Fixes

- [ ] **FIX-01**: `ARCHFLAGS` set to `-arch arm64` (not x86_64) on Apple Silicon
- [ ] **FIX-02**: `fff` alias converted to function (aliases don't accept `$1`)
- [ ] **FIX-03**: `audiofix` alias converted to function (backtick eval at parse time → `$()`)
- [ ] **FIX-04**: `clipsort` alias quoting fixed (nested double quotes broken)
- [ ] **FIX-05**: `rmenv` alias made safe (remove unnecessary `sudo`, add confirmation)
- [ ] **FIX-06**: `HIST_STAMPS` set once (currently set twice with different values)
- [ ] **FIX-07**: `SHARE_HISTORY` and `INC_APPEND_HISTORY` conflict resolved (remove INC_APPEND_HISTORY — SHARE_HISTORY implies it)
- [ ] **FIX-08**: `fast-syntax-highlighting` moved to load LAST (currently loaded first)
- [ ] **FIX-09**: Docker completions fpath addition moved before compinit
- [ ] **FIX-10**: `$ZSH_CACHE_DIR` reference removed from completions (undefined oh-my-zsh variable)
- [ ] **FIX-11**: pyenv completions path not hardcoded to specific Cellar version

### Dead Code Removal

- [ ] **DEAD-01**: Remove `export ZSH=~/.oh-my-zsh` and corresponding `unset ZSH`
- [ ] **DEAD-02**: Remove `unset ZSH_THEME` (oh-my-zsh vestige)
- [ ] **DEAD-03**: Remove `DISABLE_AUTO_UPDATE=true` (oh-my-zsh variable)
- [ ] **DEAD-04**: Remove `source ~/secrets.sh` (file is empty, 0 bytes)
- [ ] **DEAD-05**: Remove `export MONO_GAC_PREFIX="/usr/local"` (unused)
- [ ] **DEAD-06**: Delete `.p10k.zsh` from repo (1600 lines, completely unused)
- [ ] **DEAD-07**: Delete `.fzf.zsh` from repo if present (replaced by `source <(fzf --zsh)`)
- [ ] **DEAD-08**: Commit Kali/ directory deletion (already deleted, not committed)
- [ ] **DEAD-09**: Remove `__git_files` performance hack (oh-my-zsh workaround, not needed with Zap)

### Architecture & Structure

- [ ] **ARCH-01**: Establish .zshenv with minimal contents (typeset -U, EDITOR, VISUAL only)
- [ ] **ARCH-02**: Establish .zprofile with PATH array construction and brew shellenv
- [ ] **ARCH-03**: .zshrc contains only interactive config with correct sourcing order
- [ ] **ARCH-04**: Merge completions.zsh into .zshrc (eliminate split file with conflicting zstyles)
- [ ] **ARCH-05**: Single compinit call with all fpath additions before it
- [ ] **ARCH-06**: Starship init as last tool initialization in .zshrc
- [ ] **ARCH-07**: Support `~/.zshrc.local` for machine-specific overrides (replaces secrets.sh pattern)

### Shell efficiency (aliases & functions)

Interactive efficiency in **`~/dotfiles/.zsh.aliases`** and **`~/dotfiles/.zsh.functions`** — not only startup time. Satisfied by Phase 2 plan **02-04** together with completion merge (**ARCH-04** / **02-02**).

- [ ] **EFF-01**: Documented inventory of pipeline-heavy aliases and subprocess-heavy functions (fork counts, `grep` vs `rg`, parse-time risks)
- [ ] **EFF-02**: At least three concrete efficiency edits **or** three documented no-change decisions with rationale (portability, BSD vs GNU, correctness)
- [ ] **EFF-03**: `zsh -n` / smoke checks pass for both files after edits; zero behavior regression vs Phase 7 checklist

### External research (public dotfiles)

- [ ] **EXT-01**: At least five external references (repos or articles) with noted overlap to this stack
- [ ] **EXT-02**: `.planning/research/EXTERNAL-PATTERNS.md` contains adopt / reject / defer table with rationale
- [ ] **EXT-03**: At least two recommendations applied in-repo during Phase 8 **or** explicitly deferred with ROADMAP/backlog pointer

### Publication & multi-machine sync

- [ ] **PUB-01**: `git fetch` against public remote; local vs upstream divergence documented; non-conflicting updates integrated
- [ ] **PUB-02**: README updated for current install/layout and **non-secret** publication boundary
- [ ] **PUB-03**: Sync playbook documented (how to push improvements, review before push, use on another machine)
- [ ] **PUB-04**: `.gitignore` and docs reviewed so secret / machine-only paths are not trackable by mistake

### Deployment & Install

- [ ] **INST-01**: install.sh uses symlinks (`ln -sf`) for .zshrc, .zshenv, .zprofile
- [ ] **INST-02**: install.sh is idempotent (safe to re-run)
- [ ] **INST-03**: install.sh backs up existing files before symlinking
- [ ] **INST-04**: .zshenv and .zprofile tracked in repo (currently untracked)
- [ ] **INST-05**: Repo .zshrc is the deployed .zshrc (no divergence possible)

### Functionality Preservation

- [ ] **PRES-01**: All aliases from .zsh.aliases preserved (with bug-fixed versions where applicable)
- [ ] **PRES-02**: All functions from .zsh.functions preserved
- [ ] **PRES-03**: All git aliases preserved
- [ ] **PRES-04**: Security/pentesting functions preserved (grepip, iplist, whocerts, cve40438, etc.)
- [ ] **PRES-05**: tmux config untouched (.tmux.conf and .tmux.conf.local)
- [ ] **PRES-06**: Starship config untouched (starship.toml)
- [ ] **PRES-07**: SwiftBar plugins untouched
- [ ] **PRES-08**: Brewfile and brewup.sh untouched
- [ ] **PRES-09**: iTerm2 shell integration preserved
- [ ] **PRES-10**: fzf configuration preserved (defaults, preview, keybindings)
- [ ] **PRES-11**: zoxide aliased as cd preserved
- [ ] **PRES-12**: Homebrew, pyenv, Go, Rust, Bun, Node all on PATH correctly

## v2 Requirements

Deferred to future work. Not in current roadmap.

### Optimization

- **OPT-01**: Evaluate evalcache for tool init if startup exceeds 200ms after v1 fixes
- **OPT-02**: Consider zcompile for .zshrc and sourced files
- **OPT-03**: Audit Brewfile for unused packages

### Enhancements

- **ENH-01**: Add Zap plugin pre-installation to install.sh (avoid network dependency on first startup)
- **ENH-02**: Add tmux plugin installation to install.sh (tpm + plugins)
- **ENH-03**: Add hostname-based conditional config for multi-machine support
- **ENH-04**: Add shell startup benchmark function (profile startup time on demand)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Switching plugin manager (from Zap) | Zap is correct, validated by research |
| Switching prompt (from Starship) | Starship is correct, 54ms init |
| Rewriting tmux config | gpakosz base framework, .tmux.conf.local is fine |
| Cross-platform support | macOS-only, no need for Linux/WSL |
| New functionality | This is cleanup/fix, not features |
| oh-my-zsh compatibility | Fully migrated to Zap, no reason to maintain compat |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PERF-01 | Phase 1: Critical Startup Fixes | Not started |
| PERF-02 | Phase 1: Critical Startup Fixes | Not started |
| PERF-03 | Phase 1: Critical Startup Fixes | Not started |
| PERF-04 | Phase 1: Critical Startup Fixes | Not started |
| PERF-05 | Phase 1: Critical Startup Fixes | Not started |
| PERF-06 | Phase 1: Critical Startup Fixes | Not started |
| PERF-07 | Phase 1: Critical Startup Fixes | Not started |
| KEYS-01 | Phase 3: Keybinding & Hook Correctness | Not started |
| KEYS-02 | Phase 3: Keybinding & Hook Correctness | Not started |
| KEYS-03 | Phase 3: Keybinding & Hook Correctness | Not started |
| KEYS-04 | Phase 3: Keybinding & Hook Correctness | Not started |
| KEYS-05 | Phase 3: Keybinding & Hook Correctness | Not started |
| HOOK-01 | Phase 3: Keybinding & Hook Correctness | Not started |
| HOOK-02 | Phase 3: Keybinding & Hook Correctness | Not started |
| HOOK-03 | Phase 3: Keybinding & Hook Correctness | Not started |
| HOOK-04 | Phase 3: Keybinding & Hook Correctness | Not started |
| HOOK-05 | Phase 3: Keybinding & Hook Correctness | Not started |
| FIX-01 | Phase 4: Bug Fixes | Not started |
| FIX-02 | Phase 4: Bug Fixes | Not started |
| FIX-03 | Phase 4: Bug Fixes | Not started |
| FIX-04 | Phase 4: Bug Fixes | Not started |
| FIX-05 | Phase 4: Bug Fixes | Not started |
| FIX-06 | Phase 4: Bug Fixes | Not started |
| FIX-07 | Phase 4: Bug Fixes | Not started |
| FIX-08 | Phase 2: Architecture Restructuring | Not started |
| FIX-09 | Phase 2: Architecture Restructuring | Not started |
| FIX-10 | Phase 4: Bug Fixes | Not started |
| FIX-11 | Phase 4: Bug Fixes | Not started |
| DEAD-01 | Phase 5: Dead Code Removal | Not started |
| DEAD-02 | Phase 5: Dead Code Removal | Not started |
| DEAD-03 | Phase 5: Dead Code Removal | Not started |
| DEAD-04 | Phase 5: Dead Code Removal | Not started |
| DEAD-05 | Phase 5: Dead Code Removal | Not started |
| DEAD-06 | Phase 5: Dead Code Removal | Not started |
| DEAD-07 | Phase 5: Dead Code Removal | Not started |
| DEAD-08 | Phase 5: Dead Code Removal | Not started |
| DEAD-09 | Phase 5: Dead Code Removal | Not started |
| ARCH-01 | Phase 2: Architecture Restructuring | Not started |
| ARCH-02 | Phase 2: Architecture Restructuring | Not started |
| ARCH-03 | Phase 2: Architecture Restructuring | Not started |
| ARCH-04 | Phase 2: Architecture Restructuring | Not started |
| ARCH-05 | Phase 2: Architecture Restructuring | Not started |
| ARCH-06 | Phase 2: Architecture Restructuring | Not started |
| ARCH-07 | Phase 2: Architecture Restructuring | Not started |
| EFF-01 | Phase 2: Architecture Restructuring | Not started |
| EFF-02 | Phase 2: Architecture Restructuring | Not started |
| EFF-03 | Phase 2: Architecture Restructuring | Not started |
| EXT-01 | Phase 8: External Patterns & Public Dotfiles Research | Not started |
| EXT-02 | Phase 8: External Patterns & Public Dotfiles Research | Not started |
| EXT-03 | Phase 8: External Patterns & Public Dotfiles Research | Not started |
| PUB-01 | Phase 9: Public Remote Reconciliation & Multi-Machine Sync | Not started |
| PUB-02 | Phase 9: Public Remote Reconciliation & Multi-Machine Sync | Not started |
| PUB-03 | Phase 9: Public Remote Reconciliation & Multi-Machine Sync | Not started |
| PUB-04 | Phase 9: Public Remote Reconciliation & Multi-Machine Sync | Not started |
| INST-01 | Phase 6: Deployment & Install | Not started |
| INST-02 | Phase 6: Deployment & Install | Not started |
| INST-03 | Phase 6: Deployment & Install | Not started |
| INST-04 | Phase 6: Deployment & Install | Not started |
| INST-05 | Phase 6: Deployment & Install | Not started |
| PRES-01 | Phase 7: Functionality Preservation | Not started |
| PRES-02 | Phase 7: Functionality Preservation | Not started |
| PRES-03 | Phase 7: Functionality Preservation | Not started |
| PRES-04 | Phase 7: Functionality Preservation | Not started |
| PRES-05 | Phase 7: Functionality Preservation | Not started |
| PRES-06 | Phase 7: Functionality Preservation | Not started |
| PRES-07 | Phase 7: Functionality Preservation | Not started |
| PRES-08 | Phase 7: Functionality Preservation | Not started |
| PRES-09 | Phase 7: Functionality Preservation | Not started |
| PRES-10 | Phase 7: Functionality Preservation | Not started |
| PRES-11 | Phase 7: Functionality Preservation | Not started |
| PRES-12 | Phase 7: Functionality Preservation | Not started |

**Coverage:**
- v1 requirements: 71 total (across 11 categories)
- Mapped to phases: 71
- Unmapped: 0
- Coverage: 100%

---
*Requirements defined: 2026-04-21*
*Last updated: 2026-04-21 — EFF/EXT/PUB added; Phases 8–9*
