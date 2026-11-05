#!/bin/bash
# ~/.claude/shell-init.sh
# -------------------------------------------------------------------
# Fast shell initialization for Claude Code and Cursor/VS Code
#
# Provides:
#   - PATH setup (local bins first, homebrew)
#   - Activates the nearest ./.venv (uv convention: one env per project)
#
# Performance: All operations are filesystem checks only - no subprocesses.
# -------------------------------------------------------------------

# --- PATH Setup (no subprocess calls) ---

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/bin:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.bun/bin:$PATH"
export UV_PYTHON_PREFERENCE=only-managed   # uv uses only its own Pythons

# Homebrew environment (inline, no subprocess)
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"


# --- zsh globbing softening (Claude-only; no-op under bash) ---
# If this file is ever sourced into zsh, make globbing behave like bash so
# unmatched globs pass through literally instead of erroring with exit 1.
# Does NOT touch the user's interactive zsh config (.zshrc), only Claude's shell.
if [ -n "${ZSH_VERSION:-}" ]; then
  setopt no_nomatch 2>/dev/null    # unmatched glob -> literal string, not an error
  setopt no_nullglob 2>/dev/null   # keep bash-like: don't silently drop unmatched globs
  unsetopt extended_glob 2>/dev/null || true  # avoid #/^/~ having special meaning
fi

# --- No-hang editor (Claude-only) ---
# Any git command that would open an editor (commit w/o -m, tag -a, rebase)
# runs `true` instead of vi, so it aborts cleanly rather than freezing Claude
# waiting on a full-screen editor. Does not affect the user's interactive shell.
export GIT_EDITOR=true

# --- Python: activate the nearest ./.venv (uv) --------------------------------
# Lets plain `python` / `pip` resolve to the project env in every command.
# `uv run` finds it on its own; this covers tools that don't go through uv.
# Stops below $HOME so there is never a home-wide env. Legacy ~/.virtualenvs
# pointer FILES are ignored on purpose (convert them with venv-migrate).
_claude_activate_venv() {
  local d="${CLAUDE_PROJECT_DIR:-$PWD}"
  local _trust="${XDG_STATE_HOME:-$HOME/.local/state}/uv-autovenv/trusted"
  while [ "$d" != "$HOME" ] && [ "$d" != "/" ]; do
    if [ -f "$d/.venv/bin/activate" ]; then
      # Only envs on the user's trust list (built by mkvenv/venv-migrate or
      # approved with venv-trust): a cloned repo can ship a malicious .venv.
      if [ -O "$d/.venv/bin/activate" ] && grep -qxF -- "$d/.venv" "$_trust" 2>/dev/null; then
        . "$d/.venv/bin/activate" 2>/dev/null || true
      fi
      return 0
    fi
    d="$(dirname "$d")"
  done
  return 1
}
_claude_activate_venv
