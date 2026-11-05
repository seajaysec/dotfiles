---
name: python-env
description: >
  Python environments for this user: uv only. Each project has its own ./.venv
  directory managed by uv. Covers creating envs, installing and recording
  dependencies (pipr-style: stated + imported requirements), one-off scripts,
  global CLI tools, and converting old ~/.virtualenvs pointer files.
trigger: >
  Use this skill when:
  - Working in a Python project that needs an environment or dependencies
  - About to run pip, python -m venv, virtualenv, pipx or pyenv (use uv instead)
  - You need to generate or update requirements.txt
  - The SessionStart hook reports no .venv, or an old-style pointer file
---

# Python environments (uv only)

## The convention

- **Each project has its own `./.venv/` directory**, created by uv. It is in the
  user's global gitignore. Editors, linters and `uv run` find it automatically.
- **Pythons come from uv** (`UV_PYTHON_PREFERENCE=only-managed`). `python3` on
  PATH is uv's 3.12. A project can pin a version with a `.python-version` file.
- **Never** use: `~/.virtualenvs`, pyenv, pipx, `python -m venv`, `virtualenv`,
  bare `pip install` / `pip3 install` / `python -m pip install`, or
  `pip freeze > requirements.txt`. A PreToolUse hook blocks these.

## Running code

Prefer `uv run`. It uses `./.venv` (searching parent directories) without
activation, and works in a fresh, non-persistent shell:

```bash
uv run python script.py
uv run pytest
```

Plain `python` also works in Claude Code because the shell init activates the
nearest `./.venv`, but `uv run` is explicit and always correct.

## Creating an environment

```bash
uv venv --seed --prompt "$(basename "$PWD")" .venv   # --seed puts pip inside, for tools that expect it
```

Then install what the project declares:

| Project has | Command |
|---|---|
| `uv.lock` | `uv sync` |
| `pyproject.toml` / `setup.py` (no uv.lock) | `uv pip install -e .` |
| `requirements.txt` | `uv pip install -r requirements.txt` |

Do not run `uv init` / `uv sync` in a third-party repo that has no `uv.lock`;
that adds files to someone else's project. Use the table above.

## Adding dependencies

- **uv project** (`uv.lock`, or `[project]` in `pyproject.toml`): `uv add <pkg>`
  (records it in pyproject.toml + uv.lock and installs it).
- **requirements.txt project**: `uv pip install <pkg>`, then record it. The user's
  `pipr` command does the full job; replicate it in bash:

```bash
tmp=$(mktemp -d)
uvx -q pipreqs . --force --mode no-pin --savepath "$tmp/implied.in" \
    --ignore .venv,node_modules,build,dist,.git
cat "$tmp/implied.in" > "$tmp/merged.in"
[ -f requirements.txt ] && cat requirements.txt >> "$tmp/merged.in"   # keep stated deps
uv pip compile -q "$tmp/merged.in" -o requirements.txt
uv pip install -q -r requirements.txt
rm -rf "$tmp"
```

That keeps everything that was stated **and** everything implied by imports, pinned.
For a uv project, use `uv add -r "$tmp/implied.in"` instead of the compile step.

## No project, or a one-off

- `uv run --with requests --with rich python script.py`: temporary env from cache.
- `uv add --script tool.py requests`: stores deps inside the script (PEP 723);
  later `uv run tool.py` just works.
- `uvx ruff check .`: run a tool once without installing it.
- Office files: `uv run --with python-docx --with openpyxl --with python-pptx python script.py`.

## Global command-line tools

`uv tool install <pkg>` installs a CLI into its own isolated env (replaces pipx).
Use it for programs run from anywhere (llm, httpx, wafw00f). Do **not** use it for
libraries you import, or for tools that must see the project's packages (pytest,
mypy, pyright: use `uv run`). Plugins: `uv tool install llm --with llm-anthropic`.

## Old-style projects

A `.venv` **file** (not directory) is a legacy zsh-autoswitch-virtualenv pointer
to `~/.virtualenvs/<name>`. Convert it, keeping the Python version and packages:

```bash
venv-migrate .
```

## Trust (security)

Auto-activation (zsh and Claude's shell init) only sources a `./.venv` that is on
the trust list `~/.local/state/uv-autovenv/trusted`. Envs built by `mkvenv`,
`pysync`, `pipr` or `venv-migrate` are added automatically. A `.venv` that came
with a cloned repo is NOT trusted: its `bin/activate` and `bin/python` are code
from that repo. If the SessionStart hook says UNTRUSTED, do not run it. Rebuild
it (`rm -rf .venv && uv venv --seed .venv`, reinstall) or ask the user to inspect
it and run `venv-trust`. Never add entries to the trust list yourself.

## Troubleshooting

- `No module named X`: you ran a Python outside the project env. Use `uv run`.
- Wrong Python version: `echo 3.13 > .python-version && rm -rf .venv && uv venv --seed`, then reinstall.
- Broken env: `rm -rf .venv`, recreate, reinstall. It is cheap: uv's cache makes it seconds.
