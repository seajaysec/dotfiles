# Architecture Research

> Researched: 2026-04-21

## File Organization Patterns

Three dominant approaches exist in the wild, each with clear trade-offs.

### 1. Topic-Based (holman/dotfiles — 31k+ stars)

Organizes by tool/topic, each in its own directory. A bootstrap script auto-sources `*.zsh` files across all topics:

```
dotfiles/
├── git/
│   ├── aliases.zsh
│   ├── completion.zsh
│   └── gitconfig.symlink
├── ruby/
│   ├── path.zsh
│   └── rbenv.zsh
├── zsh/
│   ├── zshrc.symlink
│   └── config.zsh
├── node/
│   └── path.zsh
└── script/
    └── bootstrap
```

Convention-driven: `path.zsh` files load first, `completion.zsh` files load last, `*.symlink` files get linked to `$HOME`. The `.zshrc` itself is just a sourcing loop.

**Pros:** Easy to add/remove entire tool ecosystems. Good for repos shared across teams.
**Cons:** Overkill for a single-user dotfiles repo. Indirection makes debugging harder — you have to trace which topic directory a setting comes from.

### 2. Numbered Modules (zsh.d pattern)

Splits `.zshrc` into numbered files in a `~/.zsh.d/` or `~/.config/zsh/` directory:

```
~/.config/zsh/
├── 00-env.zsh
├── 10-options.zsh
├── 20-path.zsh
├── 30-plugins.zsh
├── 40-completions.zsh
├── 50-aliases.zsh
├── 60-functions.zsh
├── 70-keybindings.zsh
├── 80-tools.zsh
└── 90-prompt.zsh
```

The `.zshrc` is a simple loader:

```zsh
for f in ~/.config/zsh/*.zsh(N); do
  source "$f"
done
```

**Pros:** Load order is explicit and visible. Each file is small and focused. Numeric prefixes make dependencies obvious.
**Cons:** Requires discipline to keep the right things in the right files. Can proliferate into too many tiny files.

### 3. Flat Split (thoughtbot/dotfiles, mathiasbynens/dotfiles)

Keeps a small number of well-named files sourced explicitly from `.zshrc`:

```
~/
├── .zshrc              # Main config, explicit source calls
├── .zsh.aliases        # All aliases
├── .zsh.functions      # All functions
├── .path               # PATH construction
├── .extra              # Machine-local overrides (gitignored)
└── completions.zsh     # Completion config
```

The `.zshrc` explicitly sources each file in order:

```zsh
source ~/.path
source ~/.zsh.aliases
source ~/.zsh.functions
source ~/.extra  # gitignored
```

**Pros:** Simple, no magic, easy to understand. Explicit sourcing order. Good for single-user repos.
**Cons:** Files can grow large. Adding a new "category" means editing `.zshrc` to add a source line.

### Verdict for This Project

The **flat split** pattern is the closest to the current structure (`.zshrc` + `.zsh.aliases` + `.zsh.functions` + `completions.zsh`) and is the right fit. The current structure just needs:
- Correct sourcing order within `.zshrc`
- Proper `.zshenv`/`.zprofile`/`.zshrc` separation
- A keybindings file extracted from `.zshrc`
- Merging `completions.zsh` back into `.zshrc` (it's just compinit + zstyle — doesn't justify a separate file)

No need to adopt holman-style topic dirs or numbered modules for a single-user macOS dotfiles repo with ~5 files.

---

## Sourcing Order

The recommended order within `.zshrc` for an interactive shell config:

```
1. Shell Options       — setopt/unsetopt (affects everything below)
2. History             — HISTFILE, HISTSIZE, SAVEHIST, history opts
3. Plugins             — Zap/zinit/antibody loads (they set fpath, aliases, widgets)
4. Completion System   — fpath additions, compinit, zstyle rules
5. Aliases             — source ~/.zsh.aliases
6. Functions           — source ~/.zsh.functions
7. Vi-Mode + Keybinds  — bindkey -v FIRST, then all custom bindings
8. Tool Integrations   — eval "$(starship init zsh)", eval "$(zoxide init zsh)", fzf
9. Prompt / Final      — any last-mile hooks, .zshrc.local override
```

### Rationale for Each Position

| Position | Category | Why |
|----------|----------|-----|
| 1 | Shell options | `setopt` changes affect parsing, globbing, and behavior of everything sourced after |
| 2 | History | Must be set before plugins that use history (history-substring-search) |
| 3 | Plugins | Plugins add to `fpath`, define widgets, set aliases — must happen before compinit picks them up |
| 4 | Completions | `compinit` must run AFTER all `fpath` additions (plugins, custom dirs). `zstyle` rules go here too |
| 5 | Aliases | After plugins so they can override plugin-provided aliases if needed |
| 6 | Functions | After aliases so functions can reference aliases; after plugins so they don't get shadowed |
| 7 | Keybindings | `bindkey -v` wipes all existing bindings → must come BEFORE any custom bindings but AFTER plugins that register widgets |
| 8 | Tool integrations | `eval` calls (starship, zoxide, fzf) register hooks, widgets, and completions — after keybindings so they can set their own |
| 9 | Local overrides | `.zshrc.local` last so it can override anything above |

### Critical Ordering Bugs This Fixes

The current `.zshrc` has `bindkey -v` at line 230, AFTER custom emacs-style bindings set earlier — wiping them all. The fix is: `bindkey -v` first, then layer `bindkey -M viins` bindings on top.

---

## Startup File Separation (.zshenv / .zprofile / .zshrc)

### Execution Order

```
.zshenv  →  .zprofile  →  .zshrc  →  .zlogin  →  .zlogout
 always      login only    interactive   login only   logout
```

On macOS, every Terminal.app/iTerm2 tab is a login shell, so `.zprofile` runs every time a new tab opens.

### What Goes Where

#### .zshenv — Minimal, Always Runs

```zsh
# .zshenv — sourced for EVERY zsh invocation (interactive, scripts, subshells)
# Keep this TINY. Heavy work here slows every script and subshell.

export EDITOR="nvim"
export VISUAL="$EDITOR"
export LANG="en_US.UTF-8"

# ZDOTDIR if using XDG-style config location
# export ZDOTDIR="$HOME/.config/zsh"
```

**Rules:**
- NO `eval` statements (they run on every subshell, every script)
- NO PATH construction (do that in `.zprofile`)
- NO tool init (pyenv, cargo, etc.)
- Only truly universal env vars that non-interactive tools might need (`EDITOR`, `LANG`)
- If a variable is only used interactively, it goes in `.zshrc`

**Why so strict:** `.zshenv` runs for `zsh -c "some command"`, for scripts with `#!/bin/zsh`, for subshells inside Makefiles — everywhere. Anything heavy here is a tax on every zsh invocation.

#### .zprofile — Login Shell, Runs Once Per Session

```zsh
# .zprofile — sourced once for login shells
# PATH construction, brew shellenv, heavy tool init

eval "$(/opt/homebrew/bin/brew shellenv)"

typeset -U path
path=(
  $HOME/.local/bin
  $HOME/go/bin
  $HOME/.cargo/bin
  $HOME/.bun/bin
  $path
)

export GOPATH="$HOME/go"
export HOMEBREW_NO_ANALYTICS=1
```

**Rules:**
- PATH construction goes here (builds once, inherited by subshells)
- `brew shellenv` goes here (sets HOMEBREW_PREFIX, MANPATH, etc.)
- `typeset -U path` deduplicates PATH entries
- Tool environment setup that only needs to run once

**Why:** On macOS every new terminal tab is a login shell, so `.zprofile` runs per-tab. But subshells within that tab inherit the environment without re-running `.zprofile`. This is the right place for PATH.

#### .zshrc — Interactive Shell, Everything Else

```zsh
# .zshrc — sourced for every interactive shell
# Options, plugins, completions, aliases, functions, keybindings, prompt

setopt AUTO_CD EXTENDED_GLOB ...
# ... everything else
```

**Rules:**
- Everything interactive: options, history, plugins, completions, aliases, functions, keybindings, prompt
- Tool integrations that register interactive features (`eval "$(starship init zsh)"`, `eval "$(zoxide init zsh)"`)
- NO PATH construction (already done in `.zprofile`)

### What This Fixes in the Current Config

| Current Problem | Fix |
|----------------|-----|
| cargo env in both `.zshenv` and `.zshrc` | Move to `.zprofile` only |
| bun completions in both `.zshenv` and `.zshrc` | PATH in `.zprofile`, completions in `.zshrc` |
| `/opt/homebrew/bin` in both `.zprofile` and `.zshrc` | `.zprofile` only, with `typeset -U path` |
| PATH rebuilt 5+ times | Single construction in `.zprofile` |

---

## Completion System Architecture

### The Golden Rule

**All `fpath` additions MUST happen BEFORE `compinit` runs.** When `compinit` initializes, it scans `fpath` once and caches what it finds. Anything added after is invisible.

### Recommended Pattern: Daily-Cached compinit

```zsh
# Add custom completion directories to fpath FIRST
fpath=(
  $HOME/.zsh/completions
  ${HOMEBREW_PREFIX}/share/zsh/site-functions
  $fpath
)

# Daily-cached compinit — full check once/day, fast path otherwise
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
```

**How it works:**
- The glob qualifier `(#qN.mh+24)` matches if `.zcompdump` is older than 24 hours
- If old: run full `compinit` (scans fpath, rebuilds cache) — ~30ms
- If fresh: run `compinit -C` (skip scan, use cache) — ~18ms
- Net effect: ~12ms savings on most startups, full rebuild daily

### Where Completions Go in a Split Config

In the flat-split model, completion setup should live directly in `.zshrc` rather than in a separate `completions.zsh`:

```zsh
# In .zshrc, after plugins (which may add to fpath):

# 1. fpath additions
fpath=($HOME/.zsh/completions $fpath)

# 2. compinit
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# 3. zstyle rules (after compinit)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
```

### What This Fixes

| Current Problem | Fix |
|----------------|-----|
| Docker completions added to fpath AFTER compinit | Move all fpath additions before compinit |
| `$ZSH_CACHE_DIR` reference (oh-my-zsh variable) | Remove; use `$HOME/.zcompdump` or XDG path |
| Double compinit (completions.zsh + .zshrc) | Single compinit in .zshrc |
| Separate completions.zsh file | Merge into .zshrc (it's <20 lines of config) |

---

## Tool Integration Patterns

### Pattern 1: Direct eval (Simple, Fine for Fast Tools)

For tools that init quickly (<20ms), direct eval is fine:

```zsh
eval "$(starship init zsh)"    # ~54ms — acceptable
eval "$(zoxide init zsh)"      # ~11ms — fast
source <(fzf --zsh)            # ~21ms — fast
```

### Pattern 2: Lazy Loading (For Slow Tools)

For tools with expensive init (pyenv, nvm, rbenv), use function wrappers:

```zsh
# Lazy-load pyenv — only init on first use
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init -)"
  eval "$(command pyenv virtualenv-init -)"
  pyenv "$@"
}
```

This project already has a pyenv lazy-load wrapper — keep it.

### Pattern 3: evalcache (Cache eval Output)

The `mroth/evalcache` plugin caches `eval` output to a file since most tool init output is static:

```zsh
# Instead of:
eval "$(brew shellenv)"

# Use:
_evalcache brew shellenv
```

Saves ~50-100ms per cached eval. Good for tools that don't change output between runs.

### Pattern 4: Conditional Loading

Only load tools that are actually installed:

```zsh
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[fzf] )) && source <(fzf --zsh)
```

`$+commands[x]` checks the command hash table — instant, no fork.

### Recommended Integration Order in .zshrc

```zsh
# After keybindings, before .zshrc.local:

# Fast evals — inline
eval "$(zoxide init zsh --cmd cd)"
source <(fzf --zsh)

# Starship last (registers precmd hooks)
eval "$(starship init zsh)"
```

Starship must be last because it registers `precmd` and `zle-keymap-select` hooks. Anything that defines `precmd()` or `zle-keymap-select` after starship will shadow its hooks.

### What This Fixes

| Current Problem | Fix |
|----------------|-----|
| `precmd()` overwriting starship's hooks | Don't define `precmd()` — starship manages it via `precmd_functions` |
| `zle-keymap-select` overwriting starship | Don't define `zle-keymap-select` — starship provides cursor shape feedback |
| Cursor agent eval taking 1.47s | Remove from `.zshrc` entirely |
| Double cargo env load | Single load in `.zprofile` |

---

## Keybinding Architecture with Vi-Mode

### The Core Problem

`bindkey -v` activates vi mode by **replacing the current keymap** with the `viins` keymap. Any bindings set before `bindkey -v` in the default (emacs) keymap are wiped.

### Correct Architecture

```zsh
# Step 1: Activate vi mode FIRST
bindkey -v

# Step 2: Set KEYTIMEOUT for snappy mode switching
export KEYTIMEOUT=1

# Step 3: Layer emacs-convenience bindings into viins keymap
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

# Step 4: Arrow key history search (both keymaps)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -M viins '^[[A' up-line-or-beginning-search
bindkey -M viins '^[[B' down-line-or-beginning-search
bindkey -M vicmd '^[[A' up-line-or-beginning-search
bindkey -M vicmd '^[[B' down-line-or-beginning-search

# Step 5: Word movement (Option+Left/Right on macOS)
bindkey -M viins '^[b' backward-word
bindkey -M viins '^[f' forward-word

# Step 6: Home/End
bindkey -M viins '^[[H' beginning-of-line
bindkey -M viins '^[[F' end-of-line

# Step 7: Menu select bindings (requires compinit to have run)
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
```

### Using terminfo for Portability

```zsh
# Safer than hardcoded escape sequences
if [[ -n "${terminfo[khome]}" ]]; then
  bindkey -M viins "${terminfo[khome]}" beginning-of-line
fi
if [[ -n "${terminfo[kend]}" ]]; then
  bindkey -M viins "${terminfo[kend]}" end-of-line
fi
```

### Cursor Shape Feedback

Starship handles cursor shape changes between vi insert and command modes via its own `zle-keymap-select` widget. The current config defines a custom `zle-keymap-select` that shadows starship's. **Remove the custom widget and let starship handle it.**

If starship didn't handle this, the manual approach would be:

```zsh
function zle-keymap-select {
  case $KEYMAP in
    vicmd) echo -ne '\e[2 q' ;;      # Block cursor
    viins|main) echo -ne '\e[6 q' ;; # Beam cursor
  esac
}
zle -N zle-keymap-select
```

But since starship already does this, the custom function should be deleted.

---

## Secrets Management

### Pattern 1: .local Files (Simple, Sufficient for Single-User)

The most common pattern across popular dotfiles repos:

```zsh
# At the end of .zshrc:
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

```gitignore
# .gitignore
*.local
!.tmux.conf.local  # Exception for committed local overrides
```

The `.zshrc.local` file lives on the machine but never enters version control. Used for:
- API keys and tokens (`export GITHUB_TOKEN=...`)
- Machine-specific PATH additions
- Work vs personal email for git
- Employer-specific tooling

**mathiasbynens/dotfiles** uses `~/.extra` for this. **thoughtbot/dotfiles** uses `*.local` suffix convention.

### Pattern 2: Encrypted Secrets (For Public Repos)

For repos that need to be truly public:
- **chezmoi + age**: Encrypt sensitive files, decrypt on deploy
- **SOPS**: Encrypt specific YAML/JSON keys while keeping structure visible
- **1Password CLI**: Retrieve secrets at runtime with `op read "op://vault/item/field"`

### Pattern 3: git-secrets Pre-Commit Hook

Prevent accidental commits of secrets:

```bash
git secrets --install
git secrets --add 'ghp_[A-Za-z0-9_]{36}'   # GitHub tokens
git secrets --add 'sk-[A-Za-z0-9]{48}'      # OpenAI keys
git secrets --add 'AKIA[0-9A-Z]{16}'        # AWS access keys
```

### Recommendation for This Project

The `.local` file pattern is the right fit:
- This is a personal repo, not a public framework
- The current `source ~/secrets.sh` (empty file) should become `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local`
- No need for chezmoi/age/SOPS complexity for a single-user dotfiles repo
- Add `*.local` to `.gitignore` (except `.tmux.conf.local` which is already committed and isn't secrets)

---

## Recommendations

Specific recommendations for this dotfiles overhaul, derived from the research above.

### 1. Keep the Flat Split Structure

The current `.zshrc` + `.zsh.aliases` + `.zsh.functions` structure is correct. Don't adopt holman-style topic dirs. Changes needed:
- Merge `completions.zsh` into `.zshrc` (it's <20 lines of actual config)
- Extract keybindings into `.zsh.keybindings` (they're a distinct, order-sensitive concern)
- Remove `.p10k.zsh`, `.fzf.zsh` (dead files)

Target structure:

```
dotfiles/
├── .zshenv              # Minimal: EDITOR, LANG only
├── .zprofile            # PATH, brew shellenv, tool paths
├── .zshrc               # Options, history, plugins, completions, tool evals, local override
├── .zsh.aliases         # All aliases
├── .zsh.functions       # All functions
├── .zsh.keybindings     # Vi-mode + all custom bindings
├── .tmux.conf           # gpakosz base (don't touch)
├── .tmux.conf.local     # Dracula overrides
├── .gitignore_global    # Global gitignore
├── config/
│   └── starship/starship.toml
├── install.sh           # Symlink-based deployment
└── ...
```

### 2. Fix the Sourcing Order in .zshrc

Restructure `.zshrc` to follow this order:

```zsh
# 1. Shell options (setopt)
# 2. History configuration
# 3. Plugins (Zap loads)
# 4. fpath + compinit + zstyle
# 5. source ~/.zsh.aliases
# 6. source ~/.zsh.functions
# 7. source ~/.zsh.keybindings  (bindkey -v is INSIDE this file)
# 8. Tool integrations (zoxide, fzf, starship — starship LAST)
# 9. [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

### 3. Establish Clean Startup File Separation

- `.zshenv`: Only `EDITOR`, `VISUAL`, `LANG`. Nothing else.
- `.zprofile`: `brew shellenv`, PATH construction with `typeset -U path`, `GOPATH`, `HOMEBREW_NO_ANALYTICS`.
- `.zshrc`: Everything interactive.

This eliminates all double-loading (cargo, bun, homebrew PATH).

### 4. Single compinit, fpath Before It

- Move ALL `fpath` additions (Docker, Homebrew site-functions, custom) to before `compinit`
- Use the daily-cache glob pattern for fast startup
- Remove the separate `completions.zsh` file
- Remove the `$ZSH_CACHE_DIR` reference (oh-my-zsh artifact)

### 5. Vi-Mode First, Bindings After

- Extract all keybindings to `.zsh.keybindings`
- First line: `bindkey -v`
- Then layer `-M viins` and `-M vicmd` bindings
- Delete custom `zle-keymap-select` (starship handles cursor shape)
- Delete custom `precmd` (starship handles prompt refresh)

### 6. Tool Integrations: Use Conditional Loading

```zsh
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
(( $+commands[fzf] )) && source <(fzf --zsh)
(( $+commands[starship] )) && eval "$(starship init zsh)"  # LAST
```

Keep the existing pyenv lazy-load wrapper. Remove Cursor agent shell-integration from `.zshrc` entirely.

### 7. Secrets via .zshrc.local

Replace `source ~/secrets.sh` with `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local` at the end of `.zshrc`. Add `*.local` to `.gitignore` with an exception for `.tmux.conf.local`.

### 8. Deploy via Symlinks

Replace `cp` in `install.sh` with `ln -sf` for `.zshrc`, `.zsh.aliases`, `.zsh.functions`, `.zsh.keybindings`. This prevents repo/deployed divergence permanently.
