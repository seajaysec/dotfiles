# Research Summary

> Synthesized: 2026-04-21

## Stack Consensus

All four research documents agree on these choices:

- **Keep Zap** as plugin manager — lightweight, fast, no overhead beyond the plugins themselves
- **Keep Starship** as prompt — 54ms init is acceptable, handles vi-mode cursor/indicators natively
- **Keep the flat split** file structure (`.zshrc` + `.zsh.aliases` + `.zsh.functions`) — the right model for a single-user macOS repo. No topic dirs, no numbered modules
- **Direct eval** for tool init (starship/zoxide/fzf) — 86ms combined is within budget. evalcache is a second-pass optimization if needed
- **Symlinks over copies** for deployment — `ln -sf` in `install.sh`, not `cp`. No need for Stow or chezmoi
- **Daily-cached compinit** with `compinit -C` — saves ~140ms on most startups
- **Lazy-load pyenv** via wrapper function — the existing pattern is correct
- **`typeset -U PATH path`** for deduplication — set once in `.zshenv`, never worry again

## Critical Fixes (Must Do)

Ordered by impact (performance first, then correctness):

1. **Remove Cursor agent shell-integration** — 1.47s + `exec` shell replacement. Primary hang cause. Handle via Cursor's native mechanism, not `.zshrc`
2. **Fix `bindkey -v` ordering** — currently at line 230, after all emacs bindings (lines 17–183), wiping them all. Move to BEFORE all `bindkey` calls, then layer `-M viins` bindings on top
3. **Fix `precmd()`/`preexec()` overwriting Starship hooks** — bare `precmd()` definition shadows `precmd_functions` array. Use `add-zsh-hook` with uniquely-named functions, or delete entirely and let Starship own it
4. **Fix `zle-keymap-select` conflict with Starship** — custom widget (line 227) overwrites Starship's. Define before Starship init with unique name so Starship wraps it, or remove and let Starship handle cursor shape
5. **Fix `ARCHFLAGS="-arch x86_64"`** — wrong for Apple Silicon. Use `"-arch arm64"` or `"-arch $(uname -m)"`
6. **Fix `fast-syntax-highlighting` load order** — currently loaded FIRST (line 141), must be LAST. It wraps ZLE widgets and needs all other plugins loaded before it
7. **Fix `fff` alias** — aliases don't accept `$1`. Convert to function
8. **Fix `audiofix` alias** — backtick evaluation at definition time captures stale PID. Convert to function with `$(pgrep coreaudiod)`
9. **Fix `clipsort` alias** — nested double-quote quoting is broken. Use single quotes for outer wrapper
10. **Fix `rmenv` alias** — unnecessary `sudo` on user-owned dirs, no safety check. Convert to function with confirmation

## Architecture Pattern

### File Separation (3-tier)

| File | Audience | Contents |
|------|----------|----------|
| `.zshenv` | Every zsh invocation | `typeset -U PATH path`, XDG dirs, `EDITOR`, `VISUAL` — 5 lines max |
| `.zprofile` | Login shells only | `brew shellenv`, single `path=(...)` array construction (cargo, go, bun, pyenv shims, .local/bin) |
| `.zshrc` | Interactive shells only | Everything else: options, history, plugins, completions, aliases, functions, keybindings, tool init, prompt, local overrides |

### Sourcing Order within `.zshrc`

```
1. Shell options (setopt)
2. History configuration
3. Zap init + plugins (syntax highlighting LAST)
4. fpath additions + compinit (daily cache) + zstyle
5. source ~/.zsh.aliases
6. source ~/.zsh.functions
7. bindkey -v, then emacs convenience bindings in viins
8. Tool integrations (zoxide, fzf, then starship LAST)
9. pyenv lazy wrapper
10. [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

### Target File Structure

```
dotfiles/
├── .zshenv
├── .zprofile
├── .zshrc
├── .zsh.aliases
├── .zsh.functions
├── .tmux.conf           # gpakosz base (don't touch)
├── .tmux.conf.local     # Dracula overrides
├── .gitignore_global
├── install.sh           # symlink-based deployment
└── starship.toml
```

## Performance Target

**Target: < 200ms** (revised down from PROJECT.md's < 500ms)

| Savings Source | Estimated | Confidence |
|----------------|-----------|------------|
| Remove Cursor agent eval | ~1,470ms | High — measured |
| Fix compinit to `-C` (cached) | ~140ms | High — documented |
| Eliminate double-loads (cargo, bun, brew PATH) | ~100ms | Medium — estimated |
| Remove MANPATH pipeline | ~20ms | Medium — 4-process pipeline |
| Fix plugin load order | marginal | High — correctness fix |
| **Total savings** | **~1,730ms** | |

Remaining budget after fixes: starship (54ms) + zoxide (11ms) + fzf (21ms) + compinit-C (18ms) + Zap overhead (~10ms) = **~114ms**. Well under 200ms.

## Key Insights

1. **The biggest win is removal, not optimization.** The Cursor agent eval alone accounts for ~85% of startup time. Removing it and fixing double-loads gets more than any caching strategy could.

2. **`bindkey -v` is a keymap replacement, not a toggle.** It doesn't add vi bindings — it switches to a different keymap, discarding whatever was in the previous one. This is why all emacs bindings disappear.

3. **Starship owns prompt hooks.** It registers `precmd`, `preexec`, and `zle-keymap-select` widgets. Defining bare `precmd()` functions shadows the entire `precmd_functions` array mechanism. The fix is to either use `add-zsh-hook` or let Starship handle everything (cursor shape, vi indicators).

4. **`KEYTIMEOUT=1` is too aggressive.** 10ms breaks multi-key vi sequences (`cs`, `ds`) and terminal escape sequences (arrows, Home/End) over SSH and in tmux. `KEYTIMEOUT=10` (100ms) is the safe minimum.

5. **macOS `path_helper` reorders PATH.** `/etc/zprofile` runs between `.zshenv` and `.zprofile`, prepending system paths. Don't rely on PATH set in `.zshenv` having priority — set critical paths in `.zprofile` (which runs after `path_helper`).

6. **The repo/deployed divergence is a deployment bug, not a config bug.** The `cp`-based install creates independent copies. Symlinks make the repo the single source of truth permanently.

7. **`export PATH=` is almost never needed.** Zsh auto-syncs the `path` array and `PATH` scalar. Using `path+=(...)` is sufficient; explicit `export PATH=` forces unnecessary rebuilds.

## Risks & Warnings

- **KEYTIMEOUT change may affect muscle memory.** Going from 1 (10ms) to 10 (100ms) adds perceptible delay on Escape in vi-mode. Test thoroughly before committing.
- **Removing Cursor agent integration may break Cursor features.** Verify which Cursor IDE features depend on shell integration and whether they have alternative activation paths.
- **`zoxide init zsh --cmd cd`** replaces the `cd` builtin. Scripts that depend on exact `cd` behavior (return codes, symlink resolution) may behave differently. The project already uses this and it's working — just be aware.
- **Stale `.zcompdump` files (4 on disk)** should be cleaned up before restructuring, or the daily-cache pattern may use an old dump with wrong fpath entries.
- **Plugin network dependency on first run.** Zap will `git clone` plugins if they're missing. Pre-install in `install.sh` to avoid startup hangs on fresh machines.
- **`SHARE_HISTORY` and `INC_APPEND_HISTORY` are mutually exclusive.** The current config sets both. `SHARE_HISTORY` implies `INC_APPEND_HISTORY` — remove the explicit `INC_APPEND_HISTORY`.

## Research Confidence

| Area | Confidence | Rationale |
|------|------------|-----------|
| File separation (.zshenv/.zprofile/.zshrc) | **High** | Universal zsh documentation, consistent across all sources |
| Keybinding fix (bindkey -v ordering) | **High** | Root cause identified in code, confirmed by zsh keymap semantics |
| Startup performance (< 200ms target) | **High** | Based on measured timings, not estimates. Savings are subtractive |
| Plugin load order | **High** | Documented in fast-syntax-highlighting README and zsh-users guidance |
| Starship hook conflicts | **High** | Confirmed via starship GitHub issues (#1804, #2717, #3418) |
| KEYTIMEOUT value | **Medium** | 10 is documented safe minimum, but 1 may work fine on local-only setups. Needs testing |
| evalcache deferral | **Medium** | 86ms combined eval is fine now, but could revisit if more tools are added |
| Deployment (symlinks) | **High** | Industry standard; the divergence bug proves the current cp approach fails |
| Alias bugs (fff, audiofix, clipsort) | **High** | Mechanistic — aliases definitionally can't accept `$1`, backticks definitionally evaluate at parse time |
