# Architecture

> Last mapped: 2026-04-21

## Overview

This is a macOS-centric dotfiles repository that configures a complete terminal development environment. The system is organized around three pillars: **zsh shell configuration** (prompt, plugins, aliases, functions), **tmux terminal multiplexer** (with gpakosz/.tmux framework and local overrides), and **supporting tooling** (Homebrew management, SwiftBar menu bar scripts, Starship prompt). Configuration is deployed via a copy-based install script rather than symlinks, with the repo living at `~/dotfiles/` and sourced files referencing that path directly.

## Entry Points

### Shell Startup Chain

When a new interactive zsh session starts, the loading order is:

1. **`~/.zshrc`** (copied from `.zshrc`) — the primary entry point
2. Within `.zshrc`, sourcing proceeds in this order:
   - Core environment variables and `$PATH` construction (lines 1–70)
   - Pyenv shim setup and wrapper function (lines 72–85)
   - Language-specific settings: Go, Mono, Bun (lines 87–113)
   - History configuration (lines 115–134)
   - **Zap plugin manager** loads and activates 5 plugins (lines 138–145)
   - `~/dotfiles/completions.zsh` — tab completion configuration
   - `compinit` with daily cache optimization (lines 148–161)
   - **`~/secrets.sh`** — private env vars (API keys, tokens), not tracked
   - **`~/dotfiles/.zsh.aliases`** — all shell aliases
   - **`~/dotfiles/.zsh.functions`** — all custom functions
   - Key bindings (lines 173–183)
   - Async external tool loading: fzf, iTerm2 integration, bun completions, cargo env, zoxide (lines 186–193)
   - Starship prompt initialization (line 209)
   - Vi mode configuration with cursor shape switching (lines 212–230)
   - Optional project-specific source: `check_function.zsh` (lines 232–236)

### Tmux Startup Chain

1. **`~/.tmux.conf`** (copied from `.tmux.conf`) — gpakosz/.tmux base framework
2. **`~/.tmux.conf.local`** (copied from `.tmux.conf.local`) — sourced at the end of `.tmux.conf` via `source -q ~/.tmux.conf.local`
3. TPM (Tmux Plugin Manager) initializes all plugins at the very bottom

## Modular Design

### Separation of Concerns

The zsh configuration is split across four distinct files, each with a clear responsibility:

| File | Responsibility | Lines |
|---|---|---|
| `.zshrc` | Environment, PATH, plugins, options, integrations | 235 |
| `.zsh.aliases` | Short command mappings (80 aliases) | 80 |
| `.zsh.functions` | Complex reusable shell functions (25+ functions) | 569 |
| `completions.zsh` | Tab completion system configuration | 27 |

### Alias Categories (`.zsh.aliases`)

Aliases are grouped by domain with comment headers:
- **System Commands Enhancement** — safer defaults (`cp -iv`, `mv -iv`)
- **File Navigation & Listing** — eza-based modern replacements
- **Network Tools** — DNS, curl presets, IP lookup
- **Network Monitoring & Security** — lsof, nmap wrappers
- **System Maintenance** — DNS flush, audio/bluetooth fixes
- **Development & Git** — 2 standalone + full git alias section
- **Docker Management** — container lifecycle
- **Python & Virtual Environment** — venv activation, pipreqs workflow
- **Text Processing & Clipboard** — CVE extraction, clipboard sorting
- **Terminal & Session Management** — tmux attach/create
- **File Search & Navigation** — find, fzf wrappers

### Function Categories (`.zsh.functions`)

Functions are organized by domain with comment-block headers:
- **File System Operations** — `fatsort_volume`, `mcd`, `alph_sort`, `lscsv`
- **Network & IP Operations** — `dualping`, `localip`, `pb2csv`, `iplist`
- **Pattern Matching** — `grepeml`, `grepip` (IPv4/IPv6/all)
- **Security & Certificates** — `csrf`, `sessionid`, `whocerts`, `cve40438`
- **System Maintenance** — `bcbc` (brew diagnostics), `pskill`
- **Development Tools** — `ipy` (venv-aware iPython), `finish-branch`
- **Clipboard Operations** — `impaste` (clipboard image to file)
- **Media Conversion** — `m2d` (markdown to docx), `mp4togif`
- **Git Operations** — `gistx`, `subdir`, `git_current_branch`, `git_main_branch`, `remove_dups`
- **Build Environment** — `ssdeep_env` (ARM64 compile flags)

### Tmux Layering

The tmux configuration uses a **base + override** pattern from the gpakosz/.tmux framework:
- `.tmux.conf` — base config (1484 lines, including embedded shell script for theming). **Not meant to be edited directly.**
- `.tmux.conf.local` — user overrides: Dracula-inspired color theme, plugin declarations, custom settings. This is the file to edit.

## Installation Flow

`install.sh` performs a sequential bootstrap of a fresh macOS machine:

1. **Prerequisites check** — Xcode CLI tools, Homebrew
2. **Package installation** — 22 Homebrew packages (eza, ripgrep, fzf, tmux, bat, zoxide, starship, etc.)
3. **Directory setup** — `/opt/gists`, `~/dotfiles/config/starship`
4. **Plugin infrastructure** — creates `~/.local/share/zsh/plugins/`
5. **Runtime installers** — NVM, Bun, Rust (via curl-pipe-sh)
6. **File deployment** — **copies** config files to their target locations:
   - `.zshrc` → `~/.zshrc`
   - `completions.zsh` → `~/dotfiles/completions.zsh`
   - `config/starship/starship.toml` → `~/dotfiles/config/starship/starship.toml`
   - `.zsh.functions` → `~/dotfiles/.zsh.functions`
   - `.zsh.aliases` → `~/dotfiles/.zsh.aliases`
7. **Secrets stub** — `touch ~/secrets.sh`
8. **fzf setup** — runs fzf's install script
9. **Shell switch** — adds Homebrew zsh to `/etc/shells`, sets as default via `chsh`

### Deployment Model: Copy, Not Symlink

The install script uses `cp` not `ln -s`. This means `.zshrc` at `~/.zshrc` is a copy, while `.zsh.aliases` and `.zsh.functions` are sourced directly from `~/dotfiles/`. The `.zshrc` references hardcoded `~/dotfiles/` paths, so changes to aliases and functions in the repo take effect immediately, but changes to `.zshrc` itself require re-copying.

## Configuration Layering

### Tmux: Base → Local Override

```
.tmux.conf (gpakosz base — do not edit)
  └── source -q ~/.tmux.conf.local (user customizations)
        ├── Theme: Dracula-inspired color palette
        ├── Behavior: mouse on, status-position top, 1M history
        ├── Plugins via TPM:
        │     tmux-resurrect, tmux-continuum, tmux-logging,
        │     tmux-copycat, tmux-yank, tmux-sessionist,
        │     tmux-open, tmux-pop, tmux-better-mouse-mode,
        │     extrakto, tmux-menus, tmux-autoreload
        └── Plugin settings (continuum-restore, yank-selection, logging-path)
```

### Shell: Secrets Isolation

`~/secrets.sh` is sourced by `.zshrc` but never tracked in git. This file holds API keys, tokens, and environment-specific variables.

### Prompt: Starship with Custom Theme

The prompt is powered by Starship (`eval "$(starship init zsh)"`) with a custom config at `~/dotfiles/config/starship/starship.toml`. The theme uses a gruvbox-dark palette with powerline-style segments showing: sudo status, username, directory, git branch/status, Python virtualenv, package version, command duration, and exit code (with a table-flip emoji on error).

A legacy `.p10k.zsh` (Powerlevel10k config from 2021) is still in the repo but no longer sourced — Starship has replaced it.

### Plugin Management: Zap

Zsh plugins are managed via [Zap](https://github.com/zap-zsh/zap), a minimal plugin manager. Five plugins are loaded:

| Plugin | Purpose |
|---|---|
| `fast-syntax-highlighting` | Real-time command syntax coloring |
| `zsh-autosuggestions` | Fish-like history suggestions |
| `zsh-history-substring-search` | Arrow-key history substring matching |
| `zsh-you-should-use` | Alias reminders when typing full commands |
| `zsh-autoswitch-virtualenv` | Auto-activate Python venvs on `cd` |

### Homebrew: brewup.sh Auto-Maintenance

`brewup.sh` is a self-contained maintenance script that:
1. Handles Apple Silicon PATH differences
2. Pulls latest dotfiles from git
3. Runs `brew update && brew upgrade && brew cleanup`
4. Dumps current packages to `Brewfile.{HOSTNAME}`
5. Commits and pushes the updated Brewfile

This creates a machine-specific package manifest (e.g., `Brewfile.C02FR3U9MD6T`) that tracks installed packages per host.

## Key Design Decisions

- **Performance-first `compinit`**: Completion cache is rebuilt only once per day (checked via file modification time vs current day-of-year)
- **Optimized pyenv**: Avoids `eval "$(pyenv init -)"` subshell overhead; instead manually sets PATH and defines a wrapper function
- **Vi mode everywhere**: Both zsh (`bindkey -v`) and tmux use vi-style keybindings with cursor shape feedback
- **Modern CLI replacements**: `eza` for ls, `bat` for cat/pager, `ripgrep` for grep, `zoxide` for cd, `fd` for find, `delta` for git diff
- **Security-oriented functions**: IP extraction, CIDR expansion, CVE scanning, SSL certificate inspection — the toolset reflects a security/networking focus
