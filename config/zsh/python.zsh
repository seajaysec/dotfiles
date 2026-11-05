# Python via uv: one convention everywhere.
#
#   Every project keeps its own environment in ./.venv/ (a real directory,
#   gitignored globally). uv creates it; VS Code, Cursor, Claude Code, Codex,
#   pyright and ruff all find it on their own; the hook below activates it when
#   you cd in. Pythons come from uv only (UV_PYTHON_PREFERENCE=only-managed).
#
#   pyhelp prints the cheat sheet.

export UV_PYTHON_PREFERENCE=only-managed

# --- auto-activate the nearest ./.venv on cd ---------------------------------
# Walks up from $PWD, stops before $HOME (no home-wide venv). Only deactivates
# envs it activated itself, so a venv you sourced by hand stays put.
#
# Security: activating means sourcing .venv/bin/activate, i.e. running code from
# the project. A cloned repo (exploit PoCs!) can ship its own .venv, so only envs
# on the trust list are activated: ones mkvenv / pysync / pipr / venv-migrate
# created, or that you approved with `venv-trust`. Claude's shell-init reads the
# same list.
export UV_AUTOVENV_TRUST="${XDG_STATE_HOME:-$HOME/.local/state}/uv-autovenv/trusted"

_uv_trusted() {  # $1 = absolute .venv path
  [[ -O $1/bin/activate ]] && grep -qxF -- "$1" "$UV_AUTOVENV_TRUST" 2>/dev/null
}

_uv_trust_add() {
  mkdir -p "${UV_AUTOVENV_TRUST:h}"
  grep -qxF -- "$1" "$UV_AUTOVENV_TRUST" 2>/dev/null || print -r -- "$1" >> "$UV_AUTOVENV_TRUST"
}

# venv-trust: approve the nearest ./.venv for auto-activation (look first!).
venv-trust() {
  local v
  v=$(_uv_find_venv) || { print "No .venv found here."; return 1; }
  [[ -O $v/bin/activate ]] || { print "Not owned by you, refusing: $v"; return 1; }
  _uv_trust_add "$v" && print "Trusted: $v"
  _uv_autovenv
}

_uv_find_venv() {
  local d=${1:-$PWD}
  while [[ $d != $HOME && $d != / ]]; do
    [[ -f $d/.venv/bin/activate ]] && { print -r -- $d/.venv; return 0; }
    d=${d:h}
  done
  return 1
}

_uv_autovenv() {
  local venv
  venv=$(_uv_find_venv) || venv=
  if [[ -n $venv ]] && ! _uv_trusted $venv; then
    if [[ $_UV_WARNED != $venv ]]; then
      print -P "%F{yellow}Not auto-activating untrusted ${venv/#$HOME/~} (it may have come with the repo). Inspect it, then: venv-trust%f"
      typeset -g _UV_WARNED=$venv
    fi
    venv=
  fi
  if [[ -n $venv ]]; then
    [[ $VIRTUAL_ENV == $venv ]] && return
    [[ -n $VIRTUAL_ENV ]] && (( $+functions[deactivate] )) && deactivate
    source $venv/bin/activate
    typeset -g _UV_AUTO_VENV=$venv
  elif [[ -n $_UV_AUTO_VENV && $VIRTUAL_ENV == $_UV_AUTO_VENV ]]; then
    (( $+functions[deactivate] )) && deactivate
    unset _UV_AUTO_VENV
  fi
  if [[ -f .venv && ! -d .venv ]]; then
    print -P "%F{yellow}Old-style venv pointer here. Convert it: venv-migrate .%f"
  fi
}
add-zsh-hook chpwd _uv_autovenv
_uv_autovenv

# --- project commands ----------------------------------------------------------

# mkvenv [3.12]: create ./.venv (with pip inside, for tools that expect it),
# activate it, install whatever the project declares.
mkvenv() {
  emulate -L zsh
  if [[ -f .venv ]]; then
    print "Old-style venv pointer here. Use: venv-migrate ."; return 1
  elif [[ -d .venv ]]; then
    print ".venv already exists. Start over with: rmvenv && mkvenv"; return 1
  fi
  local -a py
  [[ -n $1 ]] && py=(--python ${1#--python=})
  uv venv --seed --prompt ${PWD:t} $py .venv || return
  _uv_trust_add ${PWD}/.venv
  source .venv/bin/activate
  typeset -g _UV_AUTO_VENV=$VIRTUAL_ENV
  pysync
}

# pysync: install what the project declares into ./.venv.
pysync() {
  emulate -L zsh
  if [[ -f uv.lock ]]; then
    uv sync && _uv_trust_add ${PWD}/.venv && _uv_autovenv
  elif [[ -f pyproject.toml || -f setup.py ]]; then
    uv pip install -e .
  elif [[ -f requirements.txt ]]; then
    uv pip install -r requirements.txt
  else
    print "Nothing declared yet. Add deps with: uv pip install <pkg>  (or pipr)"
  fi
}

# rmvenv: delete ./.venv.
rmvenv() {
  emulate -L zsh
  [[ -d .venv ]] || { print "No .venv here."; return 1; }
  [[ $VIRTUAL_ENV == ${PWD}/.venv ]] && (( $+functions[deactivate] )) && deactivate
  unset _UV_AUTO_VENV
  if [[ -f $UV_AUTOVENV_TRUST ]]; then
    grep -vxF -- "${PWD}/.venv" "$UV_AUTOVENV_TRUST" > "$UV_AUTOVENV_TRUST.tmp"
    mv "$UV_AUTOVENV_TRUST.tmp" "$UV_AUTOVENV_TRUST"
  fi
  rm -rf .venv && print "Removed .venv"
}

# pipr: make sure every requirement, stated OR implied by imports, is recorded
# and installed. Stated = existing requirements.txt / pyproject; implied =
# pipreqs scan of the code. Union of both, so nothing you listed by hand is lost.
#   uv projects (uv.lock or [project] in pyproject.toml): uv add  -> pyproject + lock
#   everything else:  requirements.txt, pinned with uv pip compile
pipr() {
  emulate -L zsh
  [[ -d .venv ]] || mkvenv || return
  local tmp=$(mktemp -d -t pipr)
  local implied=$tmp/implied.in merged=$tmp/merged.in
  uvx -q pipreqs . --force --mode no-pin --savepath $implied \
      --ignore .venv,node_modules,build,dist,.git >/dev/null 2>&1 \
    || { print "pipreqs could not scan this project"; rm -rf $tmp; return 1; }
  if [[ -f uv.lock ]] || grep -q '^\[project\]' pyproject.toml 2>/dev/null; then
    if [[ -s $implied ]]; then uv add -r $implied; else print "No imports found."; fi
  else
    cat $implied > $merged
    [[ -f requirements.txt ]] && cat requirements.txt >> $merged
    if uv pip compile -q $merged -o requirements.txt; then
      uv pip install -q -r requirements.txt && print "requirements.txt updated and installed."
    fi
  fi
  rm -rf $tmp
}

# ipy: IPython inside the current project (adds ipython on the fly if needed).
ipy() {
  if [[ -x $VIRTUAL_ENV/bin/ipython ]]; then
    $VIRTUAL_ENV/bin/ipython "$@"
  else
    uv run --with ipython ipython "$@"
  fi
}

alias de='deactivate'
alias venv-migrate="$HOME/.local/bin/venv-migrate"

# pyhelp: the handful of commands that keep things on the rails.
pyhelp() {
  cat <<'EOF'
Python with uv: each project has its own ./.venv (auto-activates on cd)

  In a project
    mkvenv [3.12]        create ./.venv + install declared deps
    pipr                 find imports, record + install everything needed
    pysync               reinstall what the project declares
    uv pip install X     add a package to ./.venv (then pipr to record it)
    uv add X             same, for uv projects (pyproject.toml + uv.lock)
    uv run cmd           run anything with the project env, no activation needed
    rmvenv               delete ./.venv
    ipy                  IPython in this project
    venv-trust           allow a .venv you didn't make with mkvenv to auto-activate
                         (cloned repos can ship one: look before trusting)

  Without a project
    uv run --with requests python script.py   one-off, nothing left behind
    uv add --script tool.py requests          deps stored inside the script
    uvx ruff check .                          run a tool once, not installed

  Global command-line tools (each isolated, never collide)
    uv tool install llm      uv tool list      uv tool upgrade --all
    uv tool install llm --with llm-anthropic   (tools with plugins)
    NOT for libraries you import: those go in the project's .venv

  Pythons
    uv python list           uv python install 3.13
    echo 3.13 > .python-version   pin a project (mkvenv/uv honor it)

  Old ~/.virtualenvs pointer file in a project?   venv-migrate .
EOF
}
