# Multi-machine sync playbook

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

1. Clone to `$HOME/dotfiles` (or set `DOTFILES` in `~/.zshenv` before `.zshrc` runs).
2. `./install.sh` once: Homebrew + packages, iTerm2, Zap, iTerm shell integration, Bun, Rust, then everything below.
3. Create `~/secrets.sh` (and optional `~/.zshrc.local`) on that machine only.

## Syncing an existing machine

```sh
cd ~/dotfiles && git pull && ./install.sh --link-only
```

`--link-only` is idempotent and installs no packages. It:

- symlinks shell, tmux, nvim, editor and gitignore files (anything it replaces goes to `~/.dotfiles-backup/<timestamp>/`)
- makes `~/.gitconfig` include the tracked `.gitconfig` (machine-local bits stay in `~/.gitconfig`)
- sets the login shell to `/bin/bash` (one password prompt the first time)
- removes a stale `/usr/local/go` if Homebrew go exists (sudo prompt the first time)
- switches iTerm to the single zsh profile: right away if iTerm is closed, otherwise on your next ⌘Q (iTerm relaunches itself)

Re-run full `./install.sh` only when the package list changed.

Note: upstream installers (rustup, LM Studio, etc.) like to append to `~/.zshrc` / `~/.bashrc`. Those are symlinks into this repo, so check `git status` after installing new tools.
