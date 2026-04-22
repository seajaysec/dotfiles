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

1. Clone this repo to `~/dotfiles` (or set `REPO_ROOT` and adjust paths in `~/.zshrc` if nonstandard).
2. Run `./install.sh` (symlinks `~/.zshrc`, `~/.zshenv`, `~/.zprofile` into the repo; backs up prior files under `~/.dotfiles-backup/<timestamp>/`).
3. Create `~/secrets.sh` and optional `~/.zshrc.local` on that machine only.

## Upstream integration (this session)

- `git fetch origin` executed **2026-04-21**; local `main` was **ahead** of `origin/main` (no remote-only commits to merge).
