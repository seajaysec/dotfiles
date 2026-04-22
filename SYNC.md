# Multi-machine sync playbook (Phase 9 / `PUB-*`)

## What never goes to the public remote

- `~/secrets.sh` (and any file containing API keys, tokens, or employer-internal paths)
- Machine-only `~/.zprofile` tails (e.g. Obsidian `PATH` overrides) — keep in `02-DISCUSSION-LOG.md` or local notes, not the repo
- `~/.zshrc.local` — per-host; do not commit

## Branch workflow

1. Work on `main` (or a feature branch) locally until `zsh -n` + your UAT pass.
2. `git fetch origin && git status` — review divergence (`git log --oneline origin/main..HEAD`).
3. If remote has commits you lack: `git merge origin/main` or `git rebase origin/main`; resolve conflicts; re-run shell smoke.
4. `git push origin main` only after README + `SYNC.md` reflect current install story.

## Fresh machine

1. Clone this repo — **default** layout is **`$HOME/dotfiles`**. The shell exports **`DOTFILES`** from `.zshenv` (`export DOTFILES="${DOTFILES:-$HOME/dotfiles}"`). If you clone elsewhere, set **`DOTFILES`** in **`~/.zshenv`** *before* interactive `.zshrc` runs (e.g. `export DOTFILES="$HOME/src/dotfiles"`).
2. **Link only (safe repeat):** `./install.sh --link-only` — symlinks `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, and under **`$DOTFILES`**: `.zsh.aliases`, `.zsh.functions`, `config/starship/starship.toml`, plus **`~/.tmux.conf`** when present in the repo. Backs up replaced files under **`~/.dotfiles-backup/<timestamp>/`**.
3. **Full bootstrap** (brew + nvm + bun + rust + fzf installer): `./install.sh` — use **once** per machine or when you intentionally want package installs.
4. Create `~/secrets.sh` and optional `~/.zshrc.local` on that machine only.

## Upstream integration

See **`.planning/research/REMOTE-SYNC-STATUS.md`** (regenerate after a clean `git status` before a release push).
