# Merge the dotfiles-managed bits into ~/.claude/settings.json without touching
# anything else (permissions, other hooks, plugins). Run with --arg home "$HOME".
def hook($cmd): {"type": "command", "command": $cmd};
def has_cmd($needle): [.. | objects | .command? // empty | strings | select(contains($needle))] | length > 0;

($home + "/.claude/hooks/python-uv-guard.sh") as $guard
| ($home + "/.claude/hooks/session-start-python.sh") as $start
| .env = ((.env // {}) + {"SHELL": "/bin/bash", "CLAUDE_ENV_FILE": "~/.claude/shell-init.sh"})
| .hooks = (.hooks // {})
# PreToolUse: add the uv guard once.
| if (.hooks.PreToolUse // []) | has_cmd("python-uv-guard") then .
  else .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{"matcher": "Bash", "hooks": [hook($guard)]}]) end
# SessionStart: drop the old inline virtualenv script, add ours once.
| .hooks.SessionStart = [ (.hooks.SessionStart // [])[]
    | select(((.hooks // []) | has_cmd("virtualenv")) | not) ]
| if .hooks.SessionStart | has_cmd("session-start-python") then .
  else .hooks.SessionStart += [{"matcher": "startup", "hooks": [hook($start)]}] end
