# Features Research

> Researched: 2026-04-21

## Table Stakes

Every modern zsh dotfiles setup worth maintaining should have these. Missing any of them is a gap.

### Completion System
- `compinit` with daily cache (`~/.zcompdump`) — never call it twice
- All `fpath` modifications must happen **before** `compinit` runs
- Case-insensitive matching via `zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'`
- Menu-driven selection: `zstyle ':completion:*' menu select`
- Tool-generated completions (rustup, cargo, docker, etc.) placed in fpath before init

### Syntax Highlighting & Autosuggestions
- `fast-syntax-highlighting` or `zsh-syntax-highlighting` — real-time color feedback on command validity
- `zsh-autosuggestions` — fish-style inline suggestions from history
- These are universally expected by anyone who's used a modern shell for more than a week

### History (see dedicated section below)
- Large history (1M+ lines), dedup, extended format, cross-session sharing

### Modern CLI Replacements
- `eza` for `ls` (icons, git integration, tree view)
- `bat` for `cat`/`PAGER`/`MANPAGER` (syntax highlighting, git markers)
- `fd` for `find` (fast, respects .gitignore)
- `ripgrep` for `grep` (fast, respects .gitignore)
- `zoxide` for `cd` (frecency-based directory jumping)
- `delta` for git diff pager (side-by-side, syntax highlighting)

### Prompt
- Fast prompt engine — Starship or Powerlevel10k (not both)
- Must show: cwd, git branch/status, vi-mode indicator, command duration, exit code
- Must not block — prompt should render before slow git operations complete

### Plugin Manager (Lightweight)
- Zap, Zinit, or Antidote — not Oh-My-Zsh (see Anti-Features)
- Purpose: source a handful of plugins, nothing more
- Should not add measurable startup overhead beyond the plugins themselves

### PATH Construction
- Built exactly once, in the right file (`.zshenv` for non-interactive, `.zshrc` for interactive-only tools)
- No duplicate entries — use `typeset -U path` to enforce uniqueness
- Guard tool-specific PATH additions with existence checks: `(( $+commands[brew] ))` or `[[ -d /path ]]`

### File Separation
- `.zshenv` — minimal: PATH, EDITOR, LANG. Runs for every zsh invocation (scripts too)
- `.zprofile` — login-only: `eval "$(brew shellenv)"`, system-level setup
- `.zshrc` — interactive-only: plugins, aliases, functions, keybindings, completions, prompt

## Power User Expectations

What heavy terminal users (security pros, developers, sysadmins) expect beyond table stakes.

### Keybindings: Vi-Mode with Emacs Convenience
- `bindkey -v` set first, then emacs convenience bindings added to `viins` keymap
- Critical emacs bindings to preserve in insert mode:
  - `^A` beginning-of-line, `^E` end-of-line
  - `^R` history-incremental-search-backward (or fzf equivalent)
  - `^W` backward-kill-word, `^U` kill-whole-line, `^K` kill-line
  - `^P`/`^N` or arrow keys for history navigation
- `KEYTIMEOUT=10` (100ms) — not 1 (breaks multi-key sequences in normal mode)
- Visual mode indicator via cursor shape change (block for normal, beam for insert)
- Word movement: `Alt+Left`/`Alt+Right` for backward-word/forward-word
- `Home`/`End` for beginning/end of line (iTerm2 sends specific escape sequences)

### History Substring Search
- `zsh-history-substring-search` with up/down arrow bindings
- Must be bound **after** vi-mode is set (or bindings get wiped)

### fzf Integration
- `Ctrl+R` — fuzzy history search (replaces default reverse-i-search)
- `Ctrl+T` — fuzzy file finder
- `Alt+C` — fuzzy directory changer
- Preview window using `bat` for file preview
- Custom `FZF_DEFAULT_COMMAND` using `fd` or `ag`

### Safety Aliases
- `cp -iv`, `mv -iv` — interactive + verbose for destructive operations
- `rm -iv` or `rm -I` (GNU) — confirm before removal (or use `trash` instead of `rm`)
- `mkdir -p` — always create parents
- `ln -iv` — interactive symlinks

### Git Workflow
- Pretty log aliases: `git lg` with `--graph --oneline --decorate --color`
- Branch helpers: current branch (`git rev-parse --abbrev-ref HEAD`), main branch detection
- Cleanup aliases: `git gone` to prune merged branches
- Status shortcuts: `gst`, `gd`, `gds` (diff staged), `gco`, `gcb`
- Pull with rebase: `git pull --rebase --prune` as default
- Global `.gitignore` for OS files (`.DS_Store`, `Thumbs.db`, `.env`)

### Directory Navigation
- `auto-cd` — type a directory name to cd into it
- Auto-ls on directory change (via `chpwd` hook)
- `mcd` / `mkd` — mkdir + cd in one command

### Environment Management
- Lazy-loading for heavy tools (pyenv, nvm, rbenv) — wrapper functions that load on first use
- `REPORTTIME=10` — auto-report wall time for commands taking >10 seconds
- `source ~/.extra` or `source ~/.local.zsh` pattern for machine-specific config not committed to repo

## History Configuration

### Recommended Settings

```zsh
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000

setopt EXTENDED_HISTORY          # timestamp + duration in history file
setopt HIST_EXPIRE_DUPS_FIRST    # expire duplicates first when trimming
setopt HIST_IGNORE_DUPS          # don't record immediate duplicates
setopt HIST_IGNORE_ALL_DUPS      # remove older duplicate when new one added
setopt HIST_SAVE_NO_DUPS         # don't write duplicates to file
setopt HIST_FIND_NO_DUPS         # skip duplicates in search
setopt HIST_IGNORE_SPACE         # commands starting with space are private
setopt HIST_VERIFY               # show expansion before executing
setopt HIST_REDUCE_BLANKS        # trim superfluous whitespace
setopt SHARE_HISTORY             # share between sessions + auto-import
```

### Key Considerations
- `HISTSIZE` and `SAVEHIST` should be equal — mismatches cause silent truncation
- `SHARE_HISTORY` implies `INC_APPEND_HISTORY`; don't set both
- `SHARE_HISTORY` + `EXTENDED_HISTORY` can reset elapsed time to 0 on import — acceptable tradeoff for cross-session sharing
- `HIST_IGNORE_SPACE` is critical for security professionals — prefix sensitive commands with a space to keep them out of history
- Never `export HISTFILE` — can cause truncation in subshells
- `HIST_STAMPS` is an Oh-My-Zsh variable, not a zsh builtin — remove it

## Startup Performance Benchmarks

### What's Fast
- **< 50ms**: Excellent. Feels instant. Achievable with manual plugin sourcing, cached compinit, no heavy evals
- **50–100ms**: Good. No perceptible delay. Most well-configured setups land here
- **100–200ms**: Acceptable. Slight awareness of startup but not annoying

### What's Slow
- **200–500ms**: Noticeable. Users start to feel friction opening new tabs/panes
- **500ms–1s**: Unacceptable for power users. Indicates a problem (uncached compinit, heavy plugin manager, eager nvm/pyenv init)

### What's a Hang
- **> 1s**: Broken. Network calls at startup, `exec` replacement (Cursor agent), or multiple compinit passes
- **> 2s**: Emergency. Users will abandon the shell or start skipping .zshrc

### Profiling Tools
- `zprof` (builtin): `zmodload zsh/zprof` at top of `.zshrc`, `zprof` at bottom — shows function-level timing
- `zsh-bench` (romkatv): measures user-visible latency (input lag, command lag), more realistic than zprof
- Quick benchmark: `time zsh -i -c exit` — measures full interactive startup

### Common Bottlenecks (Ranked by Impact)
1. **Shell integration evals** (Cursor, VS Code) — 500ms–2s each
2. **Eager nvm/pyenv/rbenv init** — 200–800ms each
3. **Uncached compinit** — 100–300ms
4. **Oh-My-Zsh framework loading** — 100–400ms
5. **Homebrew shellenv in .zshrc** (should be in .zprofile) — 50–150ms
6. **Multiple source calls for the same file** — cumulative

### This Project's Target
PROJECT.md targets < 500ms. Given the current stack (Starship 54ms + Zoxide 11ms + fzf 21ms + Zap overhead), **< 200ms is realistic** after removing the Cursor agent eval (1.47s) and fixing double-loading issues.

## Install Script Best Practices

### Core Principles
1. **Idempotent** — safe to run repeatedly. Must produce the same result whether run once or ten times
2. **Symlinks, not copies** — `ln -sf` from repo to `$HOME`. Prevents repo/deployed divergence (the exact bug this project is fixing)
3. **Backup before overwrite** — move existing files to `~/.dotfiles.bak/` with timestamp before symlinking
4. **OS detection** — `uname -s` for Darwin/Linux, `uname -m` for arm64/x86_64. Guard macOS-only operations
5. **Existence checks** — don't assume Homebrew, don't assume any tool. Check `command -v` before using

### What a Good Install Script Does
```
1. Detect OS and architecture
2. Install Homebrew if missing (macOS)
3. Install packages from Brewfile (brew bundle)
4. Backup existing dotfiles
5. Create symlinks for all managed files
6. Set up shell (chsh if needed)
7. Install plugin manager (Zap) if missing
8. Generate completion caches
9. Print summary of what changed
```

### What It Should NOT Do
- Modify files outside `$HOME` without explicit permission
- `sudo` without warning
- Clone repos into unpredictable locations
- Run `compinit` or other shell init (that's the shell's job)
- Assume network access after initial clone

### Symlink Strategy
```
repo/.zshrc      → ~/.zshrc
repo/.zsh.aliases    → ~/.zsh.aliases (sourced from .zshrc)
repo/.zsh.functions  → ~/.zsh.functions (sourced from .zshrc)
repo/.tmux.conf.local → ~/.tmux.conf.local
repo/.gitignore_global → ~/.gitignore_global
```
For this project: `.zshrc` itself should be symlinked (currently copied, causing divergence). Aliases and functions are already sourced from the repo — that pattern is fine.

### Popular Patterns from Reference Repos
- **mathiasbynens/dotfiles**: Bootstrap script that `rsync`s files to `$HOME`. Uses `~/.extra` for machine-local overrides
- **holman/dotfiles**: Topic-based organization (`git/`, `ruby/`, `zsh/`). Files ending in `.symlink` get linked to `$HOME`
- **thoughtbot/dotfiles**: `rcm` tool for symlink management. Namespace under `~/.dotfiles/`

## Anti-Features

Things that look useful but cause real problems. Deliberately avoid these.

### Oh-My-Zsh as a Framework
- Adds 400ms+ startup overhead
- Loads 200+ aliases you didn't ask for (150+ git aliases alone)
- Runs compinit internally, conflicting with manual completion setup
- Creates illusion of configuration when it's mostly hidden defaults
- **Verdict**: Cherry-pick the 2-3 plugins you actually use and source them directly

### Over-Modularization
- Splitting into 20+ numbered files (`00-exports.zsh`, `01-path.zsh`, etc.) adds complexity without value for a single-user config
- Each `source` call has measurable cost (~1ms each, adds up)
- Makes it harder to understand load order and debug issues
- **Verdict**: 3-4 files max (`.zshrc` + `.zsh.aliases` + `.zsh.functions` + optional `.zsh.local`) is the sweet spot for a personal setup

### Replacing Core Commands Invisibly
- `alias rm='rm -i'` seems safe but breaks scripts and muscle memory when on other machines
- `alias grep='grep --color=auto'` is fine; `alias grep='rg'` is not (different flags, different behavior)
- **Verdict**: Use new names for new tools (`alias l='eza -la'`) rather than shadowing originals. Exception: `zoxide` as `cd` is widely accepted because it's a strict superset

### KEYTIMEOUT=1
- Commonly recommended for "instant" vi-mode escape
- Breaks multi-key sequences in normal mode (`cs`, `ds`, surround operations)
- Breaks Alt/Meta key sequences (which are escape-prefixed on most terminals)
- **Verdict**: Use `KEYTIMEOUT=10` (100ms) as minimum. 20 (200ms) is safer

### Eager Loading of Version Managers
- `eval "$(pyenv init -)"` at startup: 200-800ms
- `nvm.sh` sourced at startup: 300-800ms
- **Verdict**: Use lazy-load wrappers that init on first use, or use optimized approaches (pyenv PATH-only init, fnm instead of nvm)

### Cross-Platform Abstractions in a Single-OS Setup
- Adding Linux guards, Windows WSL support, etc. for a macOS-only setup adds dead code and cognitive overhead
- **Verdict**: If it's macOS-only, keep it macOS-only. Add cross-platform when the need actually arises

### Auto-Update Mechanisms
- Plugin managers that check for updates on every shell start add latency and network dependency
- `DISABLE_AUTO_UPDATE` was a common Oh-My-Zsh flag for exactly this reason
- **Verdict**: Update manually when you choose to (`brewup`, `zap update`, etc.)

### Secrets in Dotfiles
- Even in a private repo, credentials in shell config files are a liability
- `export API_KEY=...` in `.zshrc` will end up in shell history, process listings, and child environments
- **Verdict**: Use a dedicated secrets manager (1Password CLI, `pass`, `op`) or a `~/.secrets` file that is `.gitignore`d and sourced conditionally

### Shell Integration Evals That Replace the Shell
- VS Code and Cursor inject shell integration via `eval` that can `exec` a new shell process
- Adds 500ms–2s and creates hang risk if the binary is slow or missing
- **Verdict**: Handle via the editor's native mechanism, not in `.zshrc`. If unavoidable, guard with `[[ -n "$VSCODE_INJECTION" ]]` or similar

## Recommendations

Specific to this project based on PROJECT.md context and research findings.

### Keep (Already Correct)
- **Zap** as plugin manager — lightweight, fast, does its job
- **Starship** prompt — fast (54ms), cross-shell, well-configured
- **Modern CLI stack** (eza, bat, fd, rg, zoxide, delta) — complete and current
- **Daily-cached compinit** — correct optimization
- **pyenv lazy-load wrapper** — correct approach for heavy tool
- **HISTSIZE=10M + EXTENDED_HISTORY + dedup** — already best-practice
- **Vi-mode with cursor shape feedback** — correct UX pattern
- **Separate .zsh.aliases / .zsh.functions files** — good organization without over-modularization
- **REPORTTIME=10** — useful for a power user

### Fix (Diagnosed in PROJECT.md, Confirmed by Research)
- **Keybinding order**: `bindkey -v` must come before all other bindings. Set it first, then add emacs convenience bindings to `viins` keymap — this is the universally recommended hybrid approach
- **Hook functions**: Never define bare `precmd()` / `preexec()` — use `precmd_functions+=()` array to coexist with Starship
- **Cursor agent eval**: Remove from `.zshrc` entirely. 1.47s + exec replacement is the worst anti-pattern found in research
- **compinit ordering**: All fpath additions before compinit. Docker completions after compinit = they never load
- **PATH construction**: Build once with `typeset -U path`. Move brew shellenv to `.zprofile`
- **Double-loading**: Cargo and bun in both `.zshenv` and `.zshrc` — pick one location per tool
- **HIST_STAMPS**: Remove — it's an Oh-My-Zsh variable, not zsh builtin
- **Install script**: Switch from `cp` to `ln -sf` for `.zshrc` to prevent divergence

### Establish (New Patterns)
- **File separation**: `.zshenv` (PATH, EDITOR, LANG only) → `.zprofile` (brew shellenv, login-only) → `.zshrc` (everything interactive)
- **Guard pattern**: Wrap optional tool inits in `(( $+commands[tool] ))` checks
- **KEYTIMEOUT=10**: Not 1 — protect multi-key vi sequences
- **Local overrides file**: `~/.zsh.local` sourced at end of `.zshrc` for machine-specific config (not committed)
- **Startup benchmark target**: Revise from < 500ms to < 200ms — achievable given the stack after Cursor eval removal

### Don't Do
- Don't add cross-platform abstractions — macOS-only per project constraints
- Don't split into more files — current 3-file structure is the sweet spot
- Don't add auto-update checks to shell startup
- Don't shadow core commands with incompatible replacements (eza as `ls` is fine; rg as `grep` is not)
- Don't add new functionality — this is cleanup/fix, not feature work (per PROJECT.md scope)
