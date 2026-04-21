# Stack Research

> Researched: 2026-04-21

## Zsh Startup File Separation

Zsh loads configuration files in a strict order. On macOS, every new terminal window is a **login + interactive** shell, so all three files run:

1. **`.zshenv`** — every shell invocation (interactive, non-interactive, login, script)
2. **`.zprofile`** — login shells only
3. **`.zshrc`** — interactive shells only

### What Goes Where

**`.zshenv` (minimal, fast, universal)**

Runs for *everything*, including non-interactive scripts and subshells. Must be lightweight.

```zsh
# Deduplicate PATH (must be before any PATH additions)
typeset -U path

# XDG base directories
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_CACHE_HOME="${HOME}/.cache"

# Editor (needed by non-interactive tools like git)
export EDITOR="vim"
export VISUAL="vim"
```

Do NOT put here: eval statements, plugin loading, compinit, aliases, keybindings, anything slow.

**`.zprofile` (login-only, environment setup)**

Runs once per login session. This is where PATH construction and tool environment setup goes.

```zsh
# Homebrew (login-only, sets PATH + MANPATH + INFOPATH)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Language runtimes on PATH
path=(
  "${HOME}/.cargo/bin"
  "${HOME}/go/bin"
  "${HOME}/.bun/bin"
  "${HOME}/.local/bin"
  $path
)
export PATH
```

**`.zshrc` (interactive-only, everything else)**

All interactive configuration: options, plugins, completions, aliases, keybindings, prompt.

```zsh
# Shell options, history, plugins, compinit, aliases,
# keybindings, prompt init, tool init — all here
```

### Key Principle

The separation is about **audience**: `.zshenv` must not break scripts. `.zprofile` sets up the environment once. `.zshrc` is the interactive playground. When in doubt, put it in `.zshrc`.

---

## PATH Construction Best Practices

### Use `typeset -U path` for Deduplication

Zsh ties the scalar `$PATH` to the array `$path`. The `-U` flag ensures uniqueness:

```zsh
# In .zshenv — before any PATH additions anywhere
typeset -U path
```

This automatically strips duplicates regardless of whether paths are added via the array (`path+=()`) or the scalar (`PATH="...:$PATH"`). Set it once in `.zshenv` and never worry about it again.

### Use the Array Form for PATH Construction

In `.zprofile`, construct PATH using the array form for clarity:

```zsh
path=(
  "${HOME}/.local/bin"
  "${HOME}/.cargo/bin"
  "${HOME}/go/bin"
  "${HOME}/.bun/bin"
  $path
)
export PATH
```

Prepended entries take priority. The existing `$path` (from system `/etc/zprofile`, Homebrew, etc.) is appended at the end.

### Single Construction Point

PATH should be built in exactly **one place** (`.zprofile`), not scattered across files. Tools that add to PATH (Homebrew, Cargo, pyenv) should all be grouped together. The `typeset -U path` in `.zshenv` is the safety net — the single construction point in `.zprofile` is the discipline.

### Avoid Re-evaluation

Do NOT put `eval "$(/opt/homebrew/bin/brew shellenv)"` in `.zshrc` — it runs on every new shell. It belongs in `.zprofile` where it runs once per login session. On macOS terminal emulators that always create login shells, this means once per tab/window, which is correct.

---

## Tool Initialization (eval/source)

### The Problem

`eval "$(tool init zsh)"` spawns a subprocess and evaluates its output on every shell startup. For tools like starship, zoxide, and fzf, the output is essentially static — it only changes when the tool is upgraded.

### Benchmarks (from project diagnostics)

| Tool | Time |
|------|------|
| Starship init | 54ms |
| fzf init | 21ms |
| Zoxide init | 11ms |
| **Total** | **~86ms** |

These are acceptable individually, but they compound.

### Strategy 1: evalcache (recommended for this project)

The `mroth/evalcache` plugin caches eval output to static files:

```zsh
# Instead of: eval "$(starship init zsh)"
_evalcache starship init zsh

# Instead of: eval "$(zoxide init zsh)"
_evalcache zoxide init zsh

# Instead of: source <(fzf --zsh)
_evalcache fzf --zsh
```

First run writes to `~/.zsh-evalcache/`. Subsequent runs source the cached file. Cache is invalidated manually (`_evalcache_clear`) or when the tool binary changes path. Benchmarks show 58-88% improvement.

**Trade-off:** Requires clearing cache after tool upgrades. Can be automated in a `brewup` post-hook.

### Strategy 2: Direct eval (current approach, acceptable)

For this project, the individual init times (54ms + 21ms + 11ms = 86ms) are within the 500ms budget. Direct eval is simpler and always correct:

```zsh
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)
```

### Strategy 3: Static cache files (manual)

Generate init scripts once, source the static files:

```zsh
# Generate (run manually or in brewup):
starship init zsh > "${XDG_CACHE_HOME}/starship-init.zsh"
zoxide init zsh > "${XDG_CACHE_HOME}/zoxide-init.zsh"
fzf --zsh > "${XDG_CACHE_HOME}/fzf-init.zsh"

# Source in .zshrc:
source "${XDG_CACHE_HOME}/starship-init.zsh"
source "${XDG_CACHE_HOME}/zoxide-init.zsh"
source "${XDG_CACHE_HOME}/fzf-init.zsh"
```

Most control, most maintenance. Only worth it if chasing sub-100ms startup.

### zcompile for Sourced Files

Any `.zsh` file that is sourced repeatedly can be compiled to `.zwc` bytecode:

```zsh
zcompile "${XDG_CACHE_HOME}/starship-init.zsh"
```

Zsh automatically loads the `.zwc` if it exists and is newer. Marginal benefit (~5ms per file) — only worth it for large files like compdump.

### Recommendation

Start with direct eval (Strategy 2). The 86ms total is fine within the 500ms budget. If startup exceeds target after all other fixes, add evalcache as a second pass.

---

## Completion System (compinit)

### Daily Cache Pattern (recommended)

The standard optimization checks the compdump age and only regenerates once every 24 hours:

```zsh
autoload -Uz compinit

# Regenerate compdump if older than 24 hours, otherwise use cache
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
```

**Glob qualifier breakdown:**
- `#q` — interpret as glob qualifier (requires `extendedglob`)
- `N` — nullglob (no error if file missing)
- `.` — regular files only
- `mh+24` — modified more than 24 hours ago

**Performance impact:**
- `compinit` (full): ~158ms
- `compinit -C` (cached): ~18ms
- Savings: ~140ms on most startups

### zcompile the Compdump

After compinit, compile the dump file for faster loading:

```zsh
{
  if [[ -s "${ZDOTDIR:-$HOME}/.zcompdump" && \
        (! -s "${ZDOTDIR:-$HOME}/.zcompdump.zwc" || \
         "${ZDOTDIR:-$HOME}/.zcompdump" -nt "${ZDOTDIR:-$HOME}/.zcompdump.zwc") ]]; then
    zcompile "${ZDOTDIR:-$HOME}/.zcompdump"
  fi
} &!
```

The `&!` runs compilation in the background so it doesn't block startup. The conditional check avoids unnecessary recompilation.

### fpath Before compinit

All additions to `fpath` (plugin completions, Docker completions, custom completions) **must** happen before `compinit`. This is a critical ordering requirement:

```zsh
# 1. Add to fpath
fpath=(
  "${HOME}/.docker/completions"
  $fpath
)

# 2. Load plugins that add to fpath
plug "zsh-users/zsh-autosuggestions"
# ... other plugins ...

# 3. THEN run compinit
autoload -Uz compinit
compinit -C
```

### Stale Compdump Cleanup

Clean up old `.zcompdump*` files in the install script or periodically:

```zsh
# Remove stale compdump files (keep only current)
rm -f "${ZDOTDIR:-$HOME}"/.zcompdump*.zwc 2>/dev/null
```

---

## Vi-Mode + Emacs Bindings Coexistence

### The Ordering Rule

`bindkey -v` resets the `viins` and `vicmd` keymaps to their defaults, **wiping any bindings set before it**. The fix is simple: set vi-mode first, then layer emacs-style convenience bindings on top.

```zsh
# 1. Enable vi-mode FIRST (wipes keymaps to defaults)
bindkey -v

# 2. Reduce ESC delay (default 0.4s is painfully slow)
export KEYTIMEOUT=1

# 3. Layer emacs convenience bindings in viins (insert mode)
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^U' kill-whole-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^Y' yank
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^P' up-history
bindkey -M viins '^N' down-history

# 4. Arrow keys for history-substring-search (both keymaps)
bindkey -M viins '^[[A' history-substring-search-up
bindkey -M viins '^[[B' history-substring-search-down
bindkey -M vicmd '^[[A' history-substring-search-up
bindkey -M vicmd '^[[B' history-substring-search-down

# 5. Word movement (Option+Left/Right in iTerm2)
bindkey -M viins '^[b' backward-word
bindkey -M viins '^[f' forward-word

# 6. Home/End
bindkey -M viins '^[[H' beginning-of-line
bindkey -M viins '^[[F' end-of-line
bindkey -M vicmd '^[[H' beginning-of-line
bindkey -M vicmd '^[[F' end-of-line
```

### Cursor Shape Feedback

Change cursor shape based on vi mode — beam for insert, block for normal:

```zsh
function zle-keymap-select {
  case $KEYMAP in
    vicmd)      print -n '\e[2 q' ;;  # block cursor
    viins|main) print -n '\e[6 q' ;;  # beam cursor
  esac
}
zle -N zle-keymap-select

# Ensure insert mode + beam cursor on new prompts
function zle-line-init {
  zle -K viins
  print -n '\e[6 q'
}
zle -N zle-line-init
```

### Starship Compatibility

Starship registers its own `zle-keymap-select` widget for vi-mode indicator support. If you define a custom `zle-keymap-select`, you overwrite Starship's. Options:

1. **Let Starship handle it** — don't define `zle-keymap-select` at all. Starship's vi-mode module handles cursor shape.
2. **Chain with Starship** — call Starship's widget from yours (fragile, version-dependent).
3. **Use Starship's vi-mode module** — configure `[character]` in `starship.toml` with vi-mode indicators and skip custom cursor logic.

**Recommendation:** Use option 1. Remove custom `zle-keymap-select` and `precmd` definitions. Let Starship own the prompt hooks. Configure cursor shape via Starship's vi-mode module in `starship.toml`:

```toml
[character]
vimcmd_symbol = "[N](bold green)"
```

---

## Plugin Loading Order (Zap)

### Recommended Order

Zap loads plugins sequentially as declared. The correct order is:

```zsh
# 1. Initialize Zap
source "${HOME}/.local/share/zap/zap.zsh"

# 2. Plugins that add to fpath or define completions — load FIRST
plug "MichaelAqwortsWorkerwortsMe/zsh-autoswitch-virtualenv"

# 3. Utility plugins
plug "MichaelAquilina/zsh-you-should-use"

# 4. History/suggestion plugins (depend on having a working line editor)
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-history-substring-search"

# 5. compinit AFTER all fpath-modifying plugins
autoload -Uz compinit && compinit -C

# 6. Syntax highlighting LAST (must be after compinit and all other plugins)
plug "zdharma-continuum/fast-syntax-highlighting"
```

### Why This Order

- **Syntax highlighting must be last.** It hooks into ZLE to colorize the command line. If loaded before other plugins or compinit, it won't highlight completions or plugin-added commands correctly.
- **fast-syntax-highlighting** (zdharma-continuum) is preferred over `zsh-syntax-highlighting` (zsh-users) — better compatibility with other plugins and faster.
- **history-substring-search** should be loaded after **autosuggestions** to avoid region_highlight conflicts.
- **autoswitch-virtualenv** modifies the environment on `cd`, no ordering constraint but load early so it's ready.
- **you-should-use** monitors alias usage, no ordering constraint.

### Known Compatibility Note

There is a known conflict between `fast-syntax-highlighting` and `zsh-autosuggestions` where region_highlight updates can be missed. In practice this is cosmetic and rarely noticed. If it occurs, upgrading both plugins to latest versions resolves it.

---

## Pyenv Optimization

### The Problem

`eval "$(pyenv init -)"` adds ~30-100ms to startup. It spawns a subprocess, generates shell functions, and sets up shims.

### The Project's Current Approach

The project already has a lazy-load wrapper that avoids the subshell. This is the optimal pattern:

```zsh
# Set pyenv root and add shims to PATH (instant, no subprocess)
export PYENV_ROOT="${HOME}/.pyenv"
path=("${PYENV_ROOT}/shims" "${PYENV_ROOT}/bin" $path)

# Lazy-load: defer full init until first pyenv invocation
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init - zsh)"
  pyenv "$@"
}
```

### Why This Works

1. **Shims on PATH** — `"${PYENV_ROOT}/shims"` is added to PATH immediately. This means `python`, `pip`, etc. resolve to pyenv shims instantly without running `pyenv init`.
2. **No subshell at startup** — the `eval` only runs when you explicitly call `pyenv` (e.g., `pyenv install`, `pyenv shell`).
3. **Transparent** — after first invocation, the wrapper undefines itself and the real `pyenv` function takes over.

### Specify Shell for Faster Init

When init does run, specify the shell explicitly to skip auto-detection:

```zsh
eval "$(command pyenv init - zsh)"   # 30ms
# vs
eval "$(command pyenv init -)"       # 50ms
```

### Completions

Pyenv completions should NOT be hardcoded to a Cellar version path. Use dynamic resolution:

```zsh
# Don't do this:
# fpath=("/opt/homebrew/Cellar/pyenv/2.3.35/completions" $fpath)

# Do this (if needed at all — shims handle most cases):
fpath=("${PYENV_ROOT}/completions" $fpath)
```

---

## Dotfiles Deployment Strategy

### Three Options

| Method | Symlinks? | Dependencies | Complexity |
|--------|-----------|--------------|------------|
| GNU Stow | Yes (auto-managed) | `brew install stow` | Low |
| Direct symlinks | Yes (manual `ln -sf`) | None | Low |
| Bare git repo | No (files live in `$HOME`) | None | Medium |

### Recommendation: Direct Symlinks via install.sh

For this project, **direct symlinks in `install.sh`** is the right choice:

1. **Stow is overkill** — the repo has a flat structure (`.zshrc`, `.zsh.aliases`, etc.) at the root. Stow's package/directory convention adds complexity without benefit.
2. **Bare git repo requires workflow change** — the repo is already a standard git repo, not bare. Migrating adds risk for no gain.
3. **Direct symlinks are simple and correct** — one `ln -sf` per file, easy to understand, no dependencies.

```bash
#!/bin/bash
DOTFILES="${HOME}/dotfiles"

# Symlink dotfiles
ln -sf "${DOTFILES}/.zshrc" "${HOME}/.zshrc"
ln -sf "${DOTFILES}/.zshenv" "${HOME}/.zshenv"
ln -sf "${DOTFILES}/.zprofile" "${HOME}/.zprofile"
ln -sf "${DOTFILES}/.zsh.aliases" "${HOME}/.zsh.aliases"
ln -sf "${DOTFILES}/.zsh.functions" "${HOME}/.zsh.functions"
ln -sf "${DOTFILES}/.tmux.conf" "${HOME}/.tmux.conf"
ln -sf "${DOTFILES}/.tmux.conf.local" "${HOME}/.tmux.conf.local"
ln -sf "${DOTFILES}/.gitignore_global" "${HOME}/.gitignore_global"

# Config directories (if any)
ln -sf "${DOTFILES}/starship.toml" "${HOME}/.config/starship.toml"
```

### Local Overrides

For machine-specific configuration not tracked in git, use a `.zshrc.local` pattern:

```zsh
# At the end of .zshrc
[[ -f "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
```

This keeps the repo portable while allowing per-machine secrets, work-specific aliases, etc.

---

## Recommendations

Specific recommendations for this dotfiles overhaul, based on the research above and the project context in PROJECT.md:

### 1. File Separation

Create three tracked files with clear responsibilities:

| File | Contents |
|------|----------|
| `.zshenv` | `typeset -U path`, XDG dirs, `EDITOR` — 5 lines max |
| `.zprofile` | `brew shellenv`, PATH array (cargo, go, bun, pyenv shims, .local/bin) |
| `.zshrc` | Everything else: options, history, Zap, plugins, compinit, aliases, keybindings, tool init, prompt |

### 2. PATH Construction

- `typeset -U path` in `.zshenv` (once, covers all files)
- Single `path=(...)` array in `.zprofile` after `brew shellenv`
- Remove all other PATH additions from `.zshrc` (no more `export PATH=...`)
- Remove duplicate cargo/bun/homebrew PATH entries

### 3. Startup Order in .zshrc

```
1. Shell options (setopt)
2. History config
3. Zap init + plugins (syntax highlighting LAST)
4. fpath additions (Docker completions, etc.)
5. compinit (daily cache + background zcompile)
6. bindkey -v (vi-mode FIRST)
7. Emacs convenience bindings (in viins keymap)
8. Source aliases + functions files
9. Tool init (starship, zoxide, fzf — direct eval)
10. pyenv lazy wrapper
11. Cleanup / local overrides
```

### 4. Keybinding Fix

Move `bindkey -v` to BEFORE all other keybindings. Add emacs convenience bindings explicitly in `-M viins`. Remove custom `zle-keymap-select` and `precmd` — let Starship own prompt hooks.

### 5. Completion Fix

Move Docker fpath addition BEFORE compinit. Remove `completions.zsh` as a separate file — consolidate into `.zshrc`. Remove `$ZSH_CACHE_DIR` reference (oh-my-zsh variable).

### 6. Plugin Order

```
autosuggestions → history-substring-search → you-should-use → autoswitch-virtualenv → [compinit] → fast-syntax-highlighting
```

### 7. Deployment

Replace `cp` in `install.sh` with `ln -sf` for all files. Add `.zshenv` and `.zprofile` to the repo and to the symlink list. Add `.zshrc.local` sourcing for machine-specific config.

### 8. Don't Over-Optimize

The current eval times (starship 54ms, fzf 21ms, zoxide 11ms) are fine. The wins come from:
- Removing double-loads (~100ms)
- Fixing compinit to use `-C` (~140ms)
- Removing Cursor agent shell-integration (~1470ms)
- Removing dead code (marginal but clean)

Total expected savings: **~1.7s** → target under 200ms is achievable without evalcache.
