# Phase 3–9 quality audit (reopen log)

**Date:** 2026-04-22  
**Reason:** `/gsd-autonomous` was treated as “tick ROADMAP fast,” not “meet requirements with evidence.” Phases **3–9** were **reopened** on `ROADMAP.md`. This document is the **quality bar** until re-close.

## Principle

- **Evidence over status:** each requirement gets *command* or *doc section* proof before `REQUIREMENTS.md` checkboxes flip.
- **User interrupt budget:** decisions that need taste (prompt shape, deleting secrets) go to `REQUIREMENT-WAIVERS.md`, not DMs.

---

## Phase 3 — Keybinding & hook correctness

| ID | Check | Evidence / gap |
|----|--------|----------------|
| KEYS-01 | First `bindkey` in `.zshrc` is `-v` | `grep -n '^bindkey' .zshrc \| head -1` — **pass** after prior edit. |
| KEYS-02–04 | viins + menuselect | **Human** tab/menu smoke; agent cannot feel keymaps. |
| KEYS-05 | `KEYTIMEOUT=10` | `grep KEYTIMEOUT .zshrc` — **pass**. |
| HOOK-01–02 | No bare `precmd`/`preexec` | `grep '^precmd\\s*(' .zshrc` — should be empty; **add-zsh-hook** used — **pass** pending Starship interaction test. |
| HOOK-03 | Starship vs `zle-keymap-select` | **Gap:** custom widget still **redefines** `zle-keymap-select` after `starship init`; may still fight Starship on some versions — needs **documented** resolution (wrap, remove, or upstream pattern). |
| HOOK-05 | auto-ls | `add-zsh-hook chpwd auto-ls` — **pass** (roadmap prose still says `chpwd_functions`; **fix ROADMAP** success wording to match `add-zsh-hook`). |

---

## Phase 4 — Bug fixes

| ID | Check | Evidence / gap |
|----|--------|----------------|
| FIX-01 | `ARCHFLAGS` on arm64 | `uname -m` branch — **pass** on Apple Silicon. |
| FIX-02–04 | fff / audiofix / clipsort as functions | `whence -w` — **pass**. |
| FIX-05 | `rmenv` safe | **Gap:** was `sudo rm -rf` without confirm — **fix in this quality pass** (`read -q`). |
| FIX-06 | `HIST_STAMPS` once | `grep -c HIST_STAMPS .zshrc` — **pass** (single). |
| FIX-07 | no `INC_APPEND_HISTORY` with `SHARE_HISTORY` | **pass**. |
| FIX-11 | pyenv completions not hardcoded Cellar | **Gap:** was `/opt/homebrew/opt/pyenv/...` — **fix** to `$(brew --prefix pyenv)` guard. |

---

## Phase 5 — Dead code

| ID | Check | Evidence / gap |
|----|--------|----------------|
| DEAD-01–03,09 | no OMZ leakage | `grep -E 'ZSH_THEME|DISABLE_AUTO_UPDATE|__git_files' .zshrc` — **pass**. |
| DEAD-04 | remove `secrets.sh` | **WAIVED** — user requires secrets; see `REQUIREMENT-WAIVERS.md`. |
| DEAD-06–08 | p10k/fzf/Kali | **pass** in git history (files removed). |

---

## Phase 6 — Install / deploy

| ID | Check | Evidence / gap |
|----|--------|----------------|
| INST-01–03 | symlinks + backup | **Improved 2026-04-22:** `DOTFILES` default in `.zshenv`; `install.sh` uses `DOTFILES_TARGET` + symlinks for aliases/functions/starship/tmux; backups preserved. |
| INST-02 | idempotent | **Improved:** `./install.sh --link-only` for safe repeat; full bootstrap still heavy by design — document split (not yet env-gated for every heavy block). |

---

## Phase 7 — Preservation

| Item | Status |
|------|--------|
| PRES-* | **Open** — needs scripted inventory (alias count, `whence` sample) + human tmux/iTerm. |

---

## Phase 8 — External research

| ID | Check | Evidence / gap |
|----|--------|----------------|
| EXT-01–02 | five refs + tables | **Was shallow** — **expand** `EXTERNAL-PATTERNS.md` with additional repos + **actionable** perf notes (`zsh-defer`, `zsh-bench`, plugin load order). |
| EXT-03 | two items applied or deferred with pointer | **Re-verify** after edits; add ROADMAP backlog lines if needed. |

---

## Phase 9 — Remote / sync

| ID | Check | Evidence / gap |
|----|--------|----------------|
| PUB-01 | fetch + divergence doc | Add **`REMOTE-SYNC-STATUS.md`** with `git fetch` + `rev-list --left-right --count` output refreshed on each close attempt. |
| PUB-02–04 | README + gitignore | **Partial** — deepen `SYNC.md` + `.gitignore` audit for secret patterns. |
