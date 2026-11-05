#!/bin/bash
# Deliver the shared AI-tool layer (config/ai/) to every tool on this machine:
#   Claude Code  (CLI + desktop app share ~/.claude)
#   Cursor       (IDE + cursor-agent CLI share ~/.cursor)
#   Codex        (CLI + IDE extension + app share ~/.codex)
#   Claude Desktop chat / claude.ai get the skill via sync-skills-to-claude (account-wide).
# Idempotent: links files, and merges only our own entries into each tool's JSON
# config (other settings, hooks and permissions are left alone). Called by
# install.sh (full and --link-only).
set -u
AI="$(cd "$(dirname "$0")" && pwd)"
GUARD="$AI/hooks/python-uv-guard.sh"
TS="$(date +%Y%m%d-%H%M%S)"
chmod +x "$GUARD" "$AI/claude/hooks/"*.sh 2>/dev/null

# Backups go OUTSIDE the tool folders: a copy left in a skills dir would load as
# a duplicate skill.
BK="$HOME/.dotfiles-backup/ai-$TS"
backup() { mkdir -p "$BK/$(dirname "${1#$HOME/}")"; mv "$1" "$BK/${1#$HOME/}"; }
backup_copy() { mkdir -p "$BK/$(dirname "${1#$HOME/}")"; cp "$1" "$BK/${1#$HOME/}"; }

link() {  # link <src> <dest>: replace dest with a symlink, backing up anything real
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then return 0; fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then backup "$dest"; fi
  ln -s "$src" "$dest"
}

json_merge() {  # json_merge <file> <jq-filter> [jq args...]: in place, valid JSON only
  local f="$1" filter="$2"; shift 2
  local tmp; tmp="$(mktemp)"
  [ -s "$f" ] || echo '{}' > "$f"
  if jq "$@" "$filter" "$f" > "$tmp" && jq -e . "$tmp" >/dev/null; then
    cmp -s "$tmp" "$f" || { backup_copy "$f"; mv "$tmp" "$f"; }
  else
    echo "   ai: could not update $f (left unchanged)" >&2
  fi
  rm -f "$tmp"
}

# --- Skill: one copy, shared through ~/.agents/skills ---------------------------
link "$AI/skills/python-env" "$HOME/.agents/skills/python-env"
for d in "$HOME/.claude/skills" "$HOME/.cursor/skills" "$HOME/.codex/skills"; do
  link "$AI/skills/python-env" "$d/python-env"
done

# --- Claude Code -----------------------------------------------------------------
link "$GUARD" "$HOME/.claude/hooks/python-uv-guard.sh"
link "$AI/claude/hooks/session-start-python.sh" "$HOME/.claude/hooks/session-start-python.sh"
link "$AI/claude/shell-init.sh" "$HOME/.claude/shell-init.sh"
json_merge "$HOME/.claude/settings.json" "$(cat "$AI/claude/merge-settings.jq")" --arg home "$HOME"
# CLAUDE.md imports the shared rules. Old autoswitch / office-tools sections are
# removed so they can't contradict them (backup kept).
CMD="$HOME/.claude/CLAUDE.md"
touch "$CMD"
IMPORT="@$AI/rules/global.md"
if ! grep -qxF "$IMPORT" "$CMD"; then
  backup_copy "$CMD"
  awk '
    /^## (Python Environment|Office Documents)/ { skip = 1; next }
    /^## / && skip { skip = 0 }
    !skip
  ' "$BK/.claude/CLAUDE.md" > "$CMD"
  printf '\n## Shared rules (all AI tools)\n\n%s\n' "$IMPORT" >> "$CMD"
fi

# --- Codex -----------------------------------------------------------------------
link "$AI/rules/global.md" "$HOME/.codex/AGENTS.md"
link "$AI/codex/python-uv.rules" "$HOME/.codex/rules/python-uv.rules"
json_merge "$HOME/.codex/hooks.json" '
  .hooks = (.hooks // {})
  | if ([.hooks.PreToolUse[]?.hooks[]?.command] | any(contains("python-uv-guard"))) then .
    else .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{
      matcher: "Bash",
      hooks: [{type: "command", command: $guard, statusMessage: "uv guard"}]
    }]) end' --arg guard "$GUARD"

# --- Cursor ----------------------------------------------------------------------
# Hooks run in the IDE agent and (on macOS) cursor-agent. The matcher pre-filters
# so the guard only runs for commands it should block.
CURSOR_MATCH='(^|[;&|(])\s*(sudo\s+)?(pip3?\s+(install|freeze)|python3?(\.\d+)?\s+-m\s+(pip\s+install|venv|virtualenv)|virtualenv(\s|$)|pipx(\s|$)|pyenv\s+(install|global|local|shell|virtualenv))|\.virtualenvs/\S+/bin/(activate|pip|python)'
json_merge "$HOME/.cursor/hooks.json" '
  .version = (.version // 1) | .hooks = (.hooks // {})
  | .hooks.beforeShellExecution = ([(.hooks.beforeShellExecution // [])[] | select((.command // "") | contains("python-uv-guard") | not)]
      + [{command: $guard, matcher: $match}])' --arg guard "$GUARD" --arg match "$CURSOR_MATCH"
# cursor-agent permission deny list (second layer for the CLI).
json_merge "$HOME/.cursor/cli-config.json" '
  .version = (.version // 1) | .permissions = (.permissions // {})
  | .permissions.allow = (.permissions.allow // [])
  | .permissions.deny = ((.permissions.deny // []) + $deny | unique)' --argjson deny '[
    "Shell(pip:install*)", "Shell(pip3:install*)",
    "Shell(python:-m pip install*)", "Shell(python3:-m pip install*)",
    "Shell(python:-m venv*)", "Shell(python3:-m venv*)",
    "Shell(virtualenv)", "Shell(pipx)", "Shell(pyenv:install*)"]'

echo "   ai: shared rules + python-env skill + uv guard -> Claude Code, Cursor, Codex"
