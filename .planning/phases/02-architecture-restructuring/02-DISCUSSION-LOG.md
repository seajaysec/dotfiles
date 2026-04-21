# Phase 2 — discussion log

*Append entries as Phase 2 executes.*

## 02-01 — Deploy zshenv / zprofile (2026-04-21)

- **Tracked:** `~/dotfiles/.zshenv` and `~/dotfiles/.zprofile` committed per ARCH-01/ARCH-02.
- **Home `~/.zshenv`:** Overwritten to match `~/dotfiles/.zshenv` (previous home file was a one-line pointer; replaced with canonical minimal env).
- **Home `~/.zprofile`:** Starts with `~/dotfiles/.zprofile` content, then `## Local overrides (not tracked in dotfiles)` with Obsidian `PATH` append preserved from prior machine config (`/Applications/Obsidian.app/Contents/MacOS`). This is intentional: not committed to the repo.
- **Intel Homebrew:** `.zprofile` includes `/usr/local/bin/brew` fallback after Apple Silicon guard.

## 02-02 — (pending)

## FIX-09 — (pending Docker fpath / skip note)
