#!/bin/bash
# SessionStart: tell the agent what Python env this project has (uv convention).
echo "[shell-init] CLAUDE_ENV_FILE=$CLAUDE_ENV_FILE"
P="${CLAUDE_PROJECT_DIR:-$PWD}"

find_up() {  # nearest ancestor (below $HOME) containing $1
  local d="$P"
  while [ "$d" != "$HOME" ] && [ "$d" != "/" ]; do
    [ -e "$d/$1" ] && { echo "$d"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}

if d="$(find_up .venv)" && [ -f "$d/.venv" ]; then
  echo "[python] Old-style ~/.virtualenvs pointer at $d/.venv. Convert it first: venv-migrate \"$d\""
elif d="$(find_up .venv)" && [ -d "$d/.venv" ]; then
  # Never execute anything from the env here (a cloned repo can ship its own
  # .venv): read the version from pyvenv.cfg. Fail closed: no trust list, not
  # owned by you, or not listed => untrusted.
  _t="${XDG_STATE_HOME:-$HOME/.local/state}/uv-autovenv/trusted"
  _ver="$(sed -n 's/^version_info *= *//p; s/^version *= *//p' "$d/.venv/pyvenv.cfg" 2>/dev/null | head -1)"
  if [ -f "$_t" ] && [ -O "$d/.venv" ] && [ -O "$d/.venv/pyvenv.cfg" ] && grep -qxF -- "$d/.venv" "$_t"; then
    echo "[python] uv env: $d/.venv (Python ${_ver:-unknown}). Run code with: uv run <cmd>"
  else
    echo "[python] UNTRUSTED $d/.venv (not created by the user here; may have come with the repo). Don't run it. Ask the user to inspect and run venv-trust, or rebuild: rm -rf .venv && uv venv --seed .venv"
  fi
  [ -f "$d/uv.lock" ] && echo "[python] uv project (uv.lock): add deps with uv add <pkg>"
elif ls "$P"/*.py >/dev/null 2>&1 || [ -f "$P/requirements.txt" ] || [ -f "$P/pyproject.toml" ] || [ -f "$P/setup.py" ]; then
  echo "[python] Python project without ./.venv. Create one with uv (see the python-env skill): uv venv --seed .venv"
else
  echo "[python] No Python project here"
fi

if [ -L "$P/.obsidian-link" ]; then
  echo "[obsidian] Knowledge vault linked: $(readlink "$P/.obsidian-link")"
  if obsidian help >/dev/null 2>&1; then echo "[obsidian] CLI available"
  else echo "[obsidian] CLI not available — will use raw file operations or launch Obsidian"; fi
else
  echo "[obsidian] No knowledge vault linked for this project"
fi
