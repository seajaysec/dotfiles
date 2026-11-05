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
- re-applies `config/iterm2/apply-iterm-defaults.sh` (the central iTerm prefs) every time: right away if iTerm is closed, otherwise on your next ⌘Q (iTerm relaunches itself, tabs restore). Local iTerm prefs are reconciled to the repo on each sync.

- installs the shared AI-tool layer (`config/ai/`) for Claude Code, Cursor and Codex, CLI and app: shared rules, the `python-env` skill, and the uv command guard

Re-run full `./install.sh` only when the package list changed.

### First sync on a machine that still has the old Python setup

The installer warns if it sees pyenv / pipx / `~/.virtualenvs`. Then:

```sh
py-legacy-sweep --check   # see what it would do
py-legacy-sweep           # do it, asking before each step
```

It converts project venvs to `./.venv` (uv), moves pipx and pyenv command-line
tools to `uv tool` (same versions; private packages rebuilt from the installed
files), lists leftover scripts and untrusted `.venv` folders, then zips
`~/.virtualenvs`, `~/.pyenv` and `~/.local/pipx` into
`~/temp/python-legacy-<date>/` with a `restore.sh`, and removes the originals.

### One-time steps per machine (the tools don't allow scripting these)

- **Codex:** hooks must be trusted once. CLI: run `codex`, then `/hooks`, and trust the uv guard. App: Settings → Hooks.
- **Cursor:** global rules live in the app, not a file. Settings → Rules → User Rules, add:
  `Follow the shared rules in ~/dotfiles/config/ai/rules/global.md (read it at the start of a task).`
- **Claude Desktop chat / claude.ai** (account-wide, once): `sync-skills-to-claude --only python-env --overwrite`

### claude-setup vs dotfiles

`~/gits/claude-setup` is the public, generic installer. On your own machines
dotfiles owns the AI layer. Don't run claude-setup's `install.sh` there: it
replaces `~/.claude/settings.json` and `CLAUDE.md` wholesale.

Note: upstream installers (rustup, LM Studio, etc.) like to append to `~/.zshrc` / `~/.bashrc`. Those are symlinks into this repo, so check `git status` after installing new tools.
