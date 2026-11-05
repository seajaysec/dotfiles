# Shared global rules for every AI coding tool on this machine

<!-- Single source of truth. install.sh delivers it to Claude Code (imported
     from ~/.claude/CLAUDE.md), Cursor (generated rule) and Codex
     (~/.codex/AGENTS.md). Edit here, then: ./install.sh --link-only -->

## Shell

- The login shell is plain `/bin/bash` with a vanilla environment. Don't assume
  the user's zsh aliases or functions exist in your shell.

## Python: uv only

- Every project has its own `./.venv` directory managed by uv. Run code with
  `uv run <cmd>`; it finds `./.venv` from any subdirectory, no activation needed.
  Full workflow: the `python-env` skill.
- Never use `~/.virtualenvs`, pyenv, pipx, `python -m venv`, `virtualenv`, or
  bare `pip install` / `pip3 install`. Use `uv venv --seed .venv`,
  `uv pip install`, `uv add` (uv projects), `uv tool install` (global CLIs),
  `uv python install`. Commands that break this are blocked; don't work around
  the block (e.g. `ALLOW_LEGACY_PY=1`) unless the user explicitly asks.
- Recording requirements: keep what's stated AND add what the code imports
  (pipreqs via `uvx`, then `uv pip compile`), never `pip freeze`.
- One-off scripts: `uv run --with <pkg> python script.py`.
- A `.venv` **file** is an old pointer: convert with `venv-migrate .` first.
- Security: a `.venv` that came with a cloned or downloaded repo is untrusted
  code. Only envs on `~/.local/state/uv-autovenv/trusted` are auto-activated.
  If an env isn't trusted, don't run it: rebuild it, or ask the user to inspect
  it and run `venv-trust`. Never edit the trust list yourself.

## Office documents (Word / Excel / PowerPoint) on macOS

- Use pure-Python libs: `.docx` → `python-docx`, `.xlsx` → `openpyxl`,
  `.pptx` → `python-pptx`. Run with
  `uv run --with python-docx --with openpyxl --with python-pptx python script.py`.
  Do NOT build `pylibreoffice` / LibreOfficeKit bindings (Linux-only, fail on Apple Silicon).
- Conversion / PDF export: headless LibreOffice,
  `soffice --headless --convert-to pdf --outdir <dir> <file.docx>`.
