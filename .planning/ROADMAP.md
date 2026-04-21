# Roadmap: Dotfiles Overhaul

## Overview

This roadmap takes a cruft-laden, slow-starting zsh environment and transforms it into a fast, correct, maintainable shell configuration — without losing a single alias, function, or keybinding. The journey starts by eliminating the primary startup hang (1.47s Cursor agent eval), then restructures the file architecture (.zshenv/.zprofile/.zshrc separation), fixes keybinding and hook ordering bugs, resolves remaining code-level bugs, strips dead code, modernizes deployment to symlinks, and closes with a full functionality preservation audit. Phases 3–5 can run in parallel after the architecture is stable.

## Phases
- [x] **Phase 1: Critical Startup Fixes** - Eliminate hang, double-loads, and redundant PATH construction
- [ ] **Phase 2: Architecture Restructuring** - Establish .zshenv/.zprofile/.zshrc separation with correct sourcing order
- [ ] **Phase 3: Keybinding & Hook Correctness** - Fix vi-mode ordering and Starship hook conflicts
- [ ] **Phase 4: Bug Fixes** - Fix aliases, options, and completion path bugs
- [ ] **Phase 5: Dead Code Removal** - Strip oh-my-zsh vestiges, unused files, and stale git artifacts
- [ ] **Phase 6: Deployment & Install** - Replace cp-based install with symlink deployment
- [ ] **Phase 7: Functionality Preservation Verification** - Verify zero functionality loss across all integrations

## Phase Details

### Phase 1: Critical Startup Fixes
**Goal**: Eliminate the 1.47s Cursor agent hang and all double-loading / redundant startup work to hit < 200ms
**Depends on**: Nothing (first phase)
**Requirements**: PERF-01, PERF-02, PERF-03, PERF-04, PERF-05, PERF-06, PERF-07
**Success Criteria** (what must be TRUE):
  1. `time zsh -i -c exit` completes in under 200ms
  2. No `exec` replacement or Cursor agent eval in .zshrc
  3. `cargo env` and `bun completions` each sourced/loaded exactly once across all startup files
  4. No duplicate PATH entries after startup (`echo $PATH | tr ':' '\n' | sort | uniq -d` is empty)
  5. No MANPATH subshell pipeline at source time

Plans:
- [x] 01-01: Remove Cursor agent shell integration and verify no hang
- [x] 01-02: Deduplicate double-loaded resources (cargo env, bun completions, PATH)
- [x] 01-03: Remove MANPATH pipeline, clean up stale .zcompdump files, and benchmark

---

### Phase 2: Architecture Restructuring
**Goal**: Establish correct .zshenv / .zprofile / .zshrc file separation with proper sourcing order, merge completions, fix load ordering
**Depends on**: Phase 1
**Requirements**: ARCH-01, ARCH-02, ARCH-03, ARCH-04, ARCH-05, ARCH-06, ARCH-07, FIX-08, FIX-09
**Success Criteria** (what must be TRUE):
  1. .zshenv contains only `typeset -U`, EDITOR, VISUAL (≤ 5 lines of config)
  2. .zprofile contains brew shellenv and a single `path=(...)` array construction
  3. .zshrc follows the 10-step sourcing order from research (options → history → plugins → completions → aliases → functions → keybindings → tools → pyenv → local)
  4. `fast-syntax-highlighting` is the last Zap plugin loaded; Docker fpath added before `compinit`
  5. No separate `completions.zsh` file — all completion config in .zshrc with a single `compinit` call

Plans:
- [ ] 02-01: Create .zshenv and .zprofile with correct minimal contents
- [ ] 02-02: Restructure .zshrc sourcing order and merge completions.zsh
- [ ] 02-03: Fix plugin/completion load ordering and add ~/.zshrc.local support

---

### Phase 3: Keybinding & Hook Correctness
**Goal**: Fix vi-mode keybinding ordering so emacs convenience bindings survive, and resolve Starship hook conflicts
**Depends on**: Phase 2 (sourcing order must be established)
**Requirements**: KEYS-01, KEYS-02, KEYS-03, KEYS-04, KEYS-05, HOOK-01, HOOK-02, HOOK-03, HOOK-04, HOOK-05
**Success Criteria** (what must be TRUE):
  1. `bindkey -v` appears before all other `bindkey` calls in .zshrc
  2. Ctrl-A, Ctrl-E, arrow keys, and word movement all work in vi insert mode (`bindkey -M viins` confirms)
  3. Starship prompt renders correctly — `precmd_functions` and `preexec_functions` contain Starship entries (not shadowed)
  4. Vi-mode cursor changes shape (beam in insert, block in normal) without conflicting with Starship's `zle-keymap-select`
  5. Changing directory triggers auto-ls via `chpwd_functions` (not a bare `chpwd()` definition)

Plans:
- [ ] 03-01: Fix keybinding ordering — vi-mode first, then emacs convenience bindings in viins keymap
- [ ] 03-02: Fix Starship hook conflicts (precmd, preexec, zle-keymap-select) and chpwd auto-ls

---

### Phase 4: Bug Fixes
**Goal**: Fix all remaining code-level bugs in aliases, shell options, and completion paths
**Depends on**: Phase 2 (architecture must be stable)
**Requirements**: FIX-01, FIX-02, FIX-03, FIX-04, FIX-05, FIX-06, FIX-07, FIX-10, FIX-11
**Success Criteria** (what must be TRUE):
  1. `echo $ARCHFLAGS` outputs `-arch arm64` on Apple Silicon
  2. `fff`, `audiofix`, `rmenv` defined as functions (not aliases) — verified via `whence -w`
  3. `clipsort` quoting works correctly (no broken nested double quotes)
  4. `HIST_STAMPS` set exactly once; `INC_APPEND_HISTORY` not set (SHARE_HISTORY implies it)
  5. No references to `$ZSH_CACHE_DIR` or hardcoded pyenv Cellar version paths in any config file

Plans:
- [ ] 04-01: Fix environment variables, history options, and completion path references
- [ ] 04-02: Convert broken aliases to functions (fff, audiofix, clipsort, rmenv)

---

### Phase 5: Dead Code Removal
**Goal**: Remove all unused code, files, and stale git artifacts
**Depends on**: Phase 2 (architecture must be stable so removals don't break the new structure)
**Requirements**: DEAD-01, DEAD-02, DEAD-03, DEAD-04, DEAD-05, DEAD-06, DEAD-07, DEAD-08, DEAD-09
**Success Criteria** (what must be TRUE):
  1. No oh-my-zsh references in any config file (`ZSH`, `ZSH_THEME`, `DISABLE_AUTO_UPDATE`, `__git_files`)
  2. `.p10k.zsh` and `.fzf.zsh` deleted from repo (verified via `git ls-files`)
  3. `Kali/` directory removal committed to git history
  4. No `source ~/secrets.sh` or `MONO_GAC_PREFIX` in any sourced file

Plans:
- [ ] 05-01: Remove oh-my-zsh vestiges and dead code lines from config files
- [ ] 05-02: Delete unused files (.p10k.zsh, .fzf.zsh) and commit Kali/ removal

---

### Phase 6: Deployment & Install
**Goal**: Replace cp-based install.sh with symlink-based deployment, track all shell init files
**Depends on**: Phases 3, 4, 5 (config must be stable and clean before changing deployment)
**Requirements**: INST-01, INST-02, INST-03, INST-04, INST-05
**Success Criteria** (what must be TRUE):
  1. `install.sh` creates symlinks (`ln -sf`) for .zshrc, .zshenv, .zprofile (verified via `ls -la ~/{.zshrc,.zshenv,.zprofile}`)
  2. Running `install.sh` twice produces identical results with no errors
  3. Existing files backed up to `~/.dotfiles-backup/` before symlinking
  4. `.zshenv` and `.zprofile` tracked in git (`git ls-files` includes them)

Plans:
- [ ] 06-01: Rewrite install.sh with symlink deployment, backup, and idempotency

---

### Phase 7: Functionality Preservation Verification
**Goal**: Comprehensive audit confirming zero functionality loss across all aliases, functions, keybindings, and tool integrations
**Depends on**: Phase 6 (all changes complete)
**Requirements**: PRES-01, PRES-02, PRES-03, PRES-04, PRES-05, PRES-06, PRES-07, PRES-08, PRES-09, PRES-10, PRES-11, PRES-12
**Success Criteria** (what must be TRUE):
  1. Every alias in .zsh.aliases resolves correctly — `alias` output matches expected set
  2. Every function in .zsh.functions is defined — `whence -w` confirms all as `function`
  3. All runtime tools (pyenv, go, cargo, bun, node) found on PATH via `command -v`
  4. fzf preview, zoxide cd replacement, and iTerm2 shell integration all functional
  5. tmux, Starship, SwiftBar, and Brewfile configs byte-identical to pre-overhaul baseline

Plans:
- [ ] 07-01: Audit all aliases, functions, and git workflow preservation
- [ ] 07-02: Verify tool integrations, PATH correctness, and untouched configs

## Parallel Execution Note

Phases 3, 4, and 5 can execute in parallel after Phase 2 completes — they modify independent areas (keybindings/hooks, alias/option bugs, dead code). Phase 6 waits for all three to finish.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Critical Startup Fixes | 0/3 | Not started | - |
| 2. Architecture Restructuring | 0/3 | Not started | - |
| 3. Keybinding & Hook Correctness | 0/2 | Not started | - |
| 4. Bug Fixes | 0/2 | Not started | - |
| 5. Dead Code Removal | 0/2 | Not started | - |
| 6. Deployment & Install | 0/1 | Not started | - |
| 7. Functionality Preservation Verification | 0/2 | Not started | - |

---
*Roadmap created: 2026-04-21*
*Last updated: 2026-04-21*
