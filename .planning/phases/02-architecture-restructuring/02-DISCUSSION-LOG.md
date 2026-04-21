# Phase 2 — discussion log

*Append entries as Phase 2 executes.*

## 02-01 — Deploy zshenv / zprofile (2026-04-21)

- **Tracked:** `~/dotfiles/.zshenv` and `~/dotfiles/.zprofile` committed per ARCH-01/ARCH-02.
- **Home `~/.zshenv`:** Overwritten to match `~/dotfiles/.zshenv` (previous home file was a one-line pointer; replaced with canonical minimal env).
- **Home `~/.zprofile`:** Starts with `~/dotfiles/.zprofile` content, then `## Local overrides (not tracked in dotfiles)` with Obsidian `PATH` append preserved from prior machine config (`/Applications/Obsidian.app/Contents/MacOS`). This is intentional: not committed to the repo.
- **Intel Homebrew:** `.zprofile` includes `/usr/local/bin/brew` fallback after Apple Silicon guard.

## 02-02 — Merge completions into `.zshrc` (2026-04-21)

- Removed `source ~/dotfiles/completions.zsh`; inlined `fpath+=~/.zfunc`, `_comp_options`, completion cache under `"${HOME}/.cache/zsh"` (no `$ZSH_CACHE_DIR`).
- Deleted `~/dotfiles/completions.zsh`. `install.sh` / `README.md` no longer copy it.
- `zsh -n ~/dotfiles/.zshrc` passes.

## 02-03 — Plugin order, Docker fpath, Starship, `.zshrc.local` (2026-04-21)

- **FIX-08:** `plug "zdharma-continuum/fast-syntax-highlighting"` is the last `plug` line.
- **FIX-09:** Guarded `fpath+=` for `$(brew --prefix docker-completion)/share/zsh/site-functions` **before** `compinit` — present on this machine (`brew --prefix docker-completion` resolves).
- **ARCH-06:** `eval "$(starship init zsh)"` moved to after check script sources and **before** PERF-05 PATH dedupe (after fzf / iTerm / bun / cargo / zoxide).
- **ARCH-07:** `[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"` at end of `.zshrc` after dedupe. `~/secrets.sh` unchanged for now — optional migration to `.zshrc.local` later.
