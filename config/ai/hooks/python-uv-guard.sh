#!/bin/bash
# Shared command guard for every AI coding tool: keeps agents on uv by blocking
# the pre-uv habits (pip install, venv, virtualenv, pipx, pyenv, pip freeze >,
# ~/.virtualenvs) and telling the agent what to run instead.
#
# One script, three callers (installed by dotfiles install.sh):
#   Claude Code  PreToolUse  (CLI + app)    stdin .tool_input.command
#   Codex        PreToolUse  (CLI + app)    stdin .tool_input.command (string or array)
#   Cursor       beforeShellExecution (IDE + cursor-agent)   stdin .command
# Claude and Codex share the hookSpecificOutput deny format. Cursor gets its own
# format, and only calls us for commands its hooks.json matcher already flagged,
# so when we don't deny we answer "ask" (Cursor's allow semantics are
# undocumented; "ask" leaves the decision with the user).
#
# The user (not the agent) can bypass one command: prefix it with ALLOW_LEGACY_PY=1.
in="$(cat)"
event="$(printf '%s' "$in" | jq -r '.hook_event_name // empty')"
# Command is usually a string; Codex may send ["bash","-lc","<script>"], in
# which case the script is what matters.
cmd="$(printf '%s' "$in" | jq -r '
  (.tool_input.command // .command // empty)
  | if type == "array" then
      (if length >= 3 and (.[0] | test("(^|/)(ba|z)?sh$")) and (.[1] | test("^-l?c$"))
       then .[2:] | join(" ") else join(" ") end)
    else . end')"

cursor=0
[ "$event" = "beforeShellExecution" ] && cursor=1

pass() {
  if [ "$cursor" = 1 ]; then printf '%s\n' '{"permission":"ask"}'; fi
  exit 0
}

[ -z "$cmd" ] && pass
case "$cmd" in *ALLOW_LEGACY_PY=1*) pass ;; esac

# Start of a command: line start or after ; & | ( or $( , optional sudo/env vars.
# (Backticks deliberately not included: they're mostly markdown in heredocs.)
S='(^|[;&|(]|\$\()[[:space:]]*(sudo[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
reason=""
if   printf '%s' "$cmd" | grep -Eq "${S}(pip3?|python3?(\.[0-9]+)?[[:space:]]+-m[[:space:]]+pip)[[:space:]]+install"; then
  reason="Use uv, not pip: 'uv pip install <pkg>' installs into ./.venv; in a uv project use 'uv add <pkg>'. To record requirements, follow the python-env skill (pipr)."
elif printf '%s' "$cmd" | grep -Eq "${S}(pip3?|python3?[[:space:]]+-m[[:space:]]+pip)[[:space:]]+freeze[^|]*>"; then
  reason="Don't pip freeze into requirements.txt. Use the pipr flow in the python-env skill (pipreqs + uv pip compile)."
elif printf '%s' "$cmd" | grep -Eq "${S}(python3?(\.[0-9]+)?[[:space:]]+-m[[:space:]]+(venv|virtualenv)|virtualenv)([[:space:]]|$)"; then
  reason="Create envs with uv: 'uv venv --seed .venv' (project-local ./.venv). See the python-env skill."
elif printf '%s' "$cmd" | grep -Eq "${S}pipx([[:space:]]|$)"; then
  reason="pipx is retired here: use 'uv tool install <pkg>' (or 'uvx <tool>' to run once)."
elif printf '%s' "$cmd" | grep -Eq "${S}pyenv[[:space:]]+(install|global|local|shell|virtualenv)"; then
  reason="pyenv is retired here: use 'uv python install <ver>' and a .python-version file."
elif printf '%s' "$cmd" | grep -Eq '\.virtualenvs/[^[:space:]]+/bin/(activate|pip|python)'; then
  reason="~/.virtualenvs is the retired layout. Projects use ./.venv (uv). Old pointer file? Run 'venv-migrate .'."
fi

[ -z "$reason" ] && pass
if [ "$cursor" = 1 ]; then
  jq -n --arg r "$reason" '{permission: "deny", user_message: ("Blocked (uv only): " + $r), agent_message: $r}'
else
  jq -n --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
fi
