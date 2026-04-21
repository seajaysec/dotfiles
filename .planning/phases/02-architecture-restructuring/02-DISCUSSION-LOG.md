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
- **Follow-up:** Restored `zmodload zsh/complist` before `compinit` — merge had dropped it with `completions.zsh`; without it, `bindkey -M menuselect` fails (no such keymap).

## 02-03 — Plugin order, Docker fpath, Starship, `.zshrc.local` (2026-04-21)

- **FIX-08:** `plug "zdharma-continuum/fast-syntax-highlighting"` is the last `plug` line.
- **FIX-09:** Guarded `fpath+=` for `$(brew --prefix docker-completion)/share/zsh/site-functions` **before** `compinit` — present on this machine (`brew --prefix docker-completion` resolves).
- **ARCH-06:** `eval "$(starship init zsh)"` moved to after check script sources and **before** PERF-05 PATH dedupe (after fzf / iTerm / bun / cargo / zoxide).
- **ARCH-07:** `[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"` at end of `.zshrc` after dedupe. `~/secrets.sh` unchanged for now — optional migration to `.zshrc.local` later.

## 02-04 — Aliases / functions efficiency (2026-04-21)

## Aliases inventory

- **Scale:** 153 lines total.
- **Counts (approx.):** `grep` **6**, `rg` **2**, `awk` **1**, `sed`/`gsed` **1**.
- **Pipeline-heavy:** `publicip` (host → `grepip` → tail), `lsock*` family, `uniqip` / clipboard chains, `srt` / `clipsort`.
- **Parse-time backticks / fork risk:** `audiofix` uses nested `` `...` `` with `ps|grep|awk` — **deferred to Phase 4 `FIX-02` / `FIX-03`** (alias→function + no parse-time command substitution) to avoid changing kill semantics in Phase 2.

## Functions inventory

- **Scale:** 568 lines; largest clusters include networking helpers (`dualping`, `localip`), clipboard utilities, and `nmap`/HTTP helpers.
- **Counts (approx.):** `grep` **11**, `rg` **5**, `awk` **9**; external tools (`ifconfig`|`docker`|`ping`) **~10** references in hot paths.
- **Overlap:** `localip` still uses `grep|awk` chains — **defer** broader refactor (split / `networkQuality`) to a later phase; Phase 2 only touched `dualping` VPN detection (grep|awk → single `awk` per interface).

### Efficiency edits (EFF-02)

- `lsockT` / `lsockU`: use **`/usr/bin/grep -F`** (not `rg`) so these aliases still work on hosts where Homebrew `rg` is not on `PATH` (SSH, minimal envs); filter is a tiny pipe so `rg` vs `grep` cost is irrelevant.
- `clipsort`: `grep -v '^$'` → `rg -v '^$'`.
- `dualping`: VPN detection uses one `awk` per interface instead of `grep -q` + `grep|awk` triple.

`zsh -n` on `.zsh.aliases` and `.zsh.functions`; `zsh -fc 'source …/.zsh.functions'` smoke OK.
