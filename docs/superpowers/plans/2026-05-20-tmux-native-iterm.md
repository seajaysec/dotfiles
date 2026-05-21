# tmux-native iTerm Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make tmux the substrate of iTerm windows via `-CC` control mode, launched by a version-controlled Dynamic Profile set as the default, so quitting and reopening iTerm restores running processes live — with no `.zshrc` involvement.

**Architecture:** A repo-tracked Dynamic Profile (`tmux` + a `Plain` escape hatch) is symlinked into iTerm's `DynamicProfiles` folder by `install.sh`. The `tmux` profile runs `tmux -CC new-session -A -s main` as a Custom Command; iTerm renders tmux windows/panes natively and translates `⌘T`/`⌘D`/`⇧⌘D` into tmux commands. App-level tmux settings (default profile, bury, restore-as) are applied by a small reproducible script whose exact `defaults` keys are captured empirically. `tmux-continuum` auto-restore is disabled so it can't fight live reattach.

**Tech Stack:** iTerm2 Dynamic Profiles (plist/JSON), tmux `-CC` control mode, zsh `install.sh` symlink deploy, macOS `defaults`, `plutil`.

**Spec:** `docs/superpowers/specs/2026-05-20-tmux-native-iterm-design.md`

---

## File Structure

| File | Responsibility |
|------|----------------|
| `config/iterm2/DynamicProfiles/tmux.json` | **New.** Defines the `tmux` (default) and `Plain` profiles. Single source of truth for the profiles. |
| `config/iterm2/apply-tmux-defaults.sh` | **New.** Reproducible `defaults write` for app-level tmux settings + default profile, with the empirically-captured keys. |
| `install.sh` | **Modify.** One `symlink_init` line to deploy the Dynamic Profile. |
| `.tmux.conf.local` | **Modify.** `@continuum-restore` `'on'` → `'off'`. |
| `iTerm2 State.itermexport` | **Delete.** 20 MB machine-specific binary, off the critical path. |
| `README.md`, `SYNC.md` | **Modify.** Document the workflow, the ⌘Q-vs-⌘W gotcha, and the defaults script. |

---

## Task 1: Create the Dynamic Profile (`tmux` + `Plain`)

**Files:**
- Create: `config/iterm2/DynamicProfiles/tmux.json`

- [ ] **Step 1: Write the profile file**

Create `config/iterm2/DynamicProfiles/tmux.json` with exactly:

```json
{
  "Profiles": [
    {
      "Name": "tmux",
      "Guid": "dotfiles-tmux-cc",
      "Custom Command": "Yes",
      "Command": "/opt/homebrew/bin/tmux -CC new-session -A -s main"
    },
    {
      "Name": "Plain",
      "Guid": "dotfiles-plain-shell",
      "Custom Command": "No"
    }
  ]
}
```

Note: `/opt/homebrew/bin/tmux` is the Apple Silicon path. On an Intel Mac this would be `/usr/local/bin/tmux` — out of scope here (repo targets Apple Silicon), but worth knowing if this repo is ever cloned to an Intel machine.

- [ ] **Step 2: Validate it parses as a property list**

Note: `plutil -lint` on current macOS only lints XML/binary plists and rejects
JSON. Validate by extracting a key instead — this exercises the same plist
parser iTerm uses:
Run: `plutil -extract Profiles.0.Guid raw config/iterm2/DynamicProfiles/tmux.json`
Expected: `dotfiles-tmux-cc`

- [ ] **Step 3: Confirm the launch command resolves on this machine**

Run: `ls -l /opt/homebrew/bin/tmux`
Expected: the file exists (it is the Homebrew tmux). If it does not, stop — the absolute path in the profile must match `command -v tmux` minus the symlink chain; re-derive with `readlink -f "$(command -v tmux)"` and update the JSON.

- [ ] **Step 4: Commit**

```bash
git add config/iterm2/DynamicProfiles/tmux.json
git commit -m "feat(iterm): add tmux -CC dynamic profile + Plain escape hatch"
```

---

## Task 2: Deploy the profile via install.sh

**Files:**
- Modify: `install.sh` (inside `link_dotfiles()`, after the `.gitignore_global` block, ~line 60)

- [ ] **Step 1: Verify the symlink does NOT yet exist (current failing state)**

Run: `ls -l "$HOME/Library/Application Support/iTerm2/DynamicProfiles/tmux.json" 2>&1`
Expected: `No such file or directory`

- [ ] **Step 2: Add the symlink line to `link_dotfiles()`**

In `install.sh`, find this block inside `link_dotfiles()`:

```bash
  if [[ -f "${REPO_ROOT}/.gitignore_global" ]]; then
    symlink_init ".gitignore_global" "${HOME}/.gitignore_global"
  fi
```

Immediately after it, add:

```bash
  # iTerm2 Dynamic Profile (tmux -CC default profile + Plain escape hatch).
  # iTerm watches this folder and hot-reloads; no iTerm restart needed.
  if [[ -f "${REPO_ROOT}/config/iterm2/DynamicProfiles/tmux.json" ]]; then
    symlink_init "config/iterm2/DynamicProfiles/tmux.json" \
      "${HOME}/Library/Application Support/iTerm2/DynamicProfiles/tmux.json"
  fi
```

- [ ] **Step 3: Run the linker**

Run: `./install.sh --link-only`
Expected: completes with `✨ Link-only complete (no packages installed).` and no errors.

- [ ] **Step 4: Verify the symlink now resolves into the repo**

Run: `readlink "$HOME/Library/Application Support/iTerm2/DynamicProfiles/tmux.json"`
Expected: prints the absolute path `…/dotfiles/config/iterm2/DynamicProfiles/tmux.json`.

- [ ] **Step 5: Verify idempotency (re-run is clean)**

Run: `./install.sh --link-only && readlink "$HOME/Library/Application Support/iTerm2/DynamicProfiles/tmux.json"`
Expected: same path, no errors, no new backup created for this file (it already points at the repo, so `backup_if_needed` short-circuits).

- [ ] **Step 6: Commit**

```bash
git add install.sh
git commit -m "feat(install): symlink iTerm tmux dynamic profile"
```

---

## Task 3: Confirm iTerm sees the profile and launches tmux (manual checkpoint)

**Files:** none (interactive verification).

- [ ] **Step 1: Confirm the `tmux` and `Plain` profiles appear**

Manual: In iTerm, open **Settings ▸ Profiles**. Confirm `tmux` and `Plain` are listed. No restart should be needed (iTerm hot-reloads the DynamicProfiles folder). If they are missing, check the symlink from Task 2 Step 4 and that `plutil -lint` passed.

- [ ] **Step 2: Launch the `tmux` profile manually**

Manual: **Settings ▸ Profiles ▸ tmux ▸** open a window with it (or ⌘O → `tmux`). Expect: the window enters tmux integration; you land in a session and the iTerm status bar reflects tmux. The launching window may show the brief `-CC` control banner.

- [ ] **Step 3: Confirm it is the `main` session, created by `-CC`**

Run (inside the new tmux window): `tmux display-message -p '#S'`
Expected: `main`

Run: `echo "$TMUX"`
Expected: a non-empty socket path (proves you are inside tmux).

- [ ] **Step 4: Confirm native gestures map to tmux**

Manual: Press `⌘T` (expect a new native tab), `⌘D` (expect a side-by-side split), `⇧⌘D` (expect a stacked split).
Run: `tmux list-windows` and `tmux list-panes`
Expected: the windows/panes you just created via native gestures appear as real tmux objects.

No commit (verification only).

---

## Task 4: Capture iTerm's tmux `defaults` keys empirically and write the apply script

The exact preference keys are not assumed — they are discovered by toggling each setting in the UI and diffing `defaults`. iTerm flushes preferences to disk on quit, so the diff must bracket a full quit.

**Files:**
- Create: `config/iterm2/apply-tmux-defaults.sh`

- [ ] **Step 1: Snapshot preferences BEFORE changing settings**

Manual then run: Quit iTerm completely (⌘Q). Then:
Run: `defaults read com.googlecode.iterm2 > /tmp/iterm-before.txt; echo done`
Expected: `done` (file written).

- [ ] **Step 2: Toggle the three settings in the UI**

Manual: Launch iTerm, then **Settings ▸ General ▸ tmux**:
1. Set **"When attaching, restore windows as…"** → **Tabs in the existing window**.
2. Enable **"Automatically bury the tmux client session after connecting"**.

Then **Settings ▸ Profiles ▸ tmux ▸ Other Actions ▸ Set as Default** (this marks the `tmux` profile as the default bookmark).

Then quit iTerm completely (⌘Q) so the changes flush to disk.

- [ ] **Step 3: Snapshot AFTER and diff**

Run: `defaults read com.googlecode.iterm2 > /tmp/iterm-after.txt; diff /tmp/iterm-before.txt /tmp/iterm-after.txt`
Expected: a small diff. Identify the three changed keys. They are expected to be (confirm against the actual diff — use whatever the diff shows, not these names if they differ):
- `"Default Bookmark Guid"` → `dotfiles-tmux-cc`
- a tmux-window-placement key (e.g. `OpenTmuxWindowsIn`) → an integer
- a bury key (e.g. `AutoHideTmuxClientSession`) → `1`

Record the real key names and values from the diff for the next step.

- [ ] **Step 4: Write the apply script using the captured keys**

Create `config/iterm2/apply-tmux-defaults.sh`. Replace the three `defaults write` lines with the **exact keys/values observed in Step 3** if they differ from the placeholders shown:

```bash
#!/usr/bin/env bash
# Apply iTerm2 app-level tmux integration settings reproducibly.
# Keys captured empirically (see docs/superpowers/plans/2026-05-20-tmux-native-iterm.md, Task 4).
# Run with iTerm QUIT — iTerm overwrites prefs in memory on quit, so writes made
# while it is running can be lost. Quit iTerm, run this, then relaunch.
set -euo pipefail

if pgrep -xq iTerm2; then
  echo "Quit iTerm2 first (it flushes prefs on quit and would overwrite these writes)." >&2
  exit 1
fi

# Make the repo 'tmux' dynamic profile the default profile.
defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "dotfiles-tmux-cc"

# Open tmux windows as tabs in the existing window.
defaults write com.googlecode.iterm2 OpenTmuxWindowsIn -int 2

# Automatically bury the tmux client (gateway) session after connecting.
defaults write com.googlecode.iterm2 AutoHideTmuxClientSession -bool true

echo "Applied. Relaunch iTerm2; new windows should open directly into tmux 'main'."
```

Make it executable:
Run: `chmod +x config/iterm2/apply-tmux-defaults.sh`

- [ ] **Step 5: Verify the script re-applies cleanly from a clean state**

Manual then run: Quit iTerm. Then:
Run: `./config/iterm2/apply-tmux-defaults.sh && defaults read com.googlecode.iterm2 "Default Bookmark Guid"`
Expected: prints `dotfiles-tmux-cc`. (If the script prints the "Quit iTerm2 first" message, iTerm is still running — quit it and retry.)

- [ ] **Step 6: Commit**

```bash
git add config/iterm2/apply-tmux-defaults.sh
git commit -m "feat(iterm): reproducible defaults for tmux default profile + bury"
```

---

## Task 5: Disable continuum auto-restore

**Files:**
- Modify: `.tmux.conf.local` (the `@continuum-restore` line, ~line 320)

- [ ] **Step 1: Confirm current value**

Run: `grep -n '@continuum-restore' .tmux.conf.local`
Expected: a line `set -g @continuum-restore 'on'`.

- [ ] **Step 2: Flip it to off**

Change that line from:

```tmux
set -g @continuum-restore 'on'
```

to:

```tmux
# Off: with tmux -CC the live server is the source of truth across iTerm
# restarts. continuum-restore only fires on fresh server start (after reboot/
# kill-server), where it would spawn a stale duplicate layout alongside the
# fresh attach. Flip back to 'on' to re-enable reboot-resurrection.
set -g @continuum-restore 'off'
```

- [ ] **Step 3: Reload tmux config and verify the option**

Run (inside a tmux session): `tmux source-file ~/.tmux.conf && tmux show-options -g @continuum-restore`
Expected: `@continuum-restore off`
(If you are not currently in tmux, this verifies on next attach instead.)

- [ ] **Step 4: Commit**

```bash
git add .tmux.conf.local
git commit -m "feat(tmux): disable continuum-restore for live -CC reattach"
```

---

## Task 6: Remove the tracked iTerm state export

**Files:**
- Delete: `iTerm2 State.itermexport`

- [ ] **Step 1: Confirm it is tracked and its size**

Run: `git ls-files -- "iTerm2 State.itermexport" && du -h "iTerm2 State.itermexport"`
Expected: the path prints and size is ~20M.

- [ ] **Step 2: Remove it from the repo**

Run: `git rm "iTerm2 State.itermexport"`
Expected: `rm 'iTerm2 State.itermexport'`

(Decision per spec: keep `iTermProfiles.json` as a reference export. Leave it tracked.)

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(iterm): drop 20MB machine-specific state export from repo"
```

---

## Task 7: Document the workflow

**Files:**
- Modify: `README.md`
- Modify: `SYNC.md`

- [ ] **Step 1: Add a tmux/iTerm section to README.md**

In `README.md`, after the `## Layout` section, add:

```markdown
## tmux-native iTerm

iTerm uses tmux as its window/pane substrate via `-CC` control mode. The `tmux`
profile (default) runs `tmux -CC new-session -A -s main`, so every new window
lands in the persistent `main` session.

- **Native gestures drive tmux:** `⌘T` = new tmux window, `⌘D` / `⇧⌘D` = splits.
- **Restore across app restarts:** **⌘Q (quit iTerm) detaches and keeps every
  process running.** Reopen iTerm → you're back in `main`, live.
- **⚠️ `⌘W` / closing a window KILLS those processes.** To keep them, *detach*:
  ⌘Q, or **Shell ▸ tmux ▸ Detach**. Never "close" to preserve work.
- **Plain shell:** open the `Plain` profile (⌘O → Plain) for a non-tmux shell.
- **`⌘N`** opens a *second* mirror of `main` (a second `-CC` client) — useful on
  a second display, but use `⌘T` for an ordinary new tab/window.

### Setup on a new machine

1. `./install.sh --link-only` — symlinks the Dynamic Profile into iTerm.
2. Quit iTerm, then run `./config/iterm2/apply-tmux-defaults.sh` to set `tmux`
   as the default profile and enable client burial.
3. Relaunch iTerm — new windows open directly into tmux `main`.
```

- [ ] **Step 2: Add the persistence note to SYNC.md**

In `SYNC.md`, under the "Fresh machine" list, after the `~/secrets.sh` step, add:

```markdown
5. iTerm tmux integration: after `install.sh --link-only`, quit iTerm and run
   `./config/iterm2/apply-tmux-defaults.sh` (sets the `tmux` profile as default,
   enables client burial). The Dynamic Profile itself is symlinked from the repo
   and hot-reloads — no plist sync, no `.zshrc` changes.
```

- [ ] **Step 3: Verify no dangling references**

Run: `git grep -nIi 'itermexport' -- README.md SYNC.md || echo "(no dangling references)"`
Expected: `(no dangling references)`

- [ ] **Step 4: Commit**

```bash
git add README.md SYNC.md
git commit -m "docs: document tmux-native iTerm workflow and setup"
```

---

## Task 8: End-to-end persistence verification (manual checkpoint)

**Files:** none (interactive verification of the whole system).

- [ ] **Step 1: Confirm a fresh window auto-enters tmux**

Manual: With Task 4 applied and iTerm relaunched, open a brand-new iTerm window (⌘N, no profile chosen).
Run: `tmux display-message -p '#S'`
Expected: `main` — proves the default profile is `tmux`. Confirm no leftover gateway window lingers (proves bury-on).

- [ ] **Step 2: Start a long-running process**

Run: `ping -i 5 1.1.1.1`
Leave it running. Note the line count climbing.

- [ ] **Step 3: Quit and reopen iTerm**

Manual: Press **⌘Q** to quit iTerm entirely. Reopen iTerm. A new window should auto-attach to `main`.

- [ ] **Step 4: Confirm the process survived**

Manual/Run: Locate the pane that had `ping` running (it should reappear as a native tab/pane). Confirm output is still accumulating — the process kept running across the quit.
Run (from any pane): `pgrep -fl 'ping -i 5 1.1.1.1'`
Expected: the process is listed (still alive). Stop it with `⌃C` when satisfied.

- [ ] **Step 5: Confirm the Plain escape hatch**

Manual: Open the `Plain` profile (⌘O → Plain).
Run: `echo "${TMUX:-no-tmux}"`
Expected: `no-tmux` (proves `Plain` is a non-tmux login shell).

- [ ] **Step 6: Confirm continuum did not resurrect a stale layout**

Run: `tmux kill-server` then reopen iTerm (auto-attaches/creates `main`).
Run: `tmux list-windows`
Expected: a single fresh window — no duplicate/stale layout restored (proves `@continuum-restore off` took effect).

No commit (verification only). If all pass, the feature is complete.

---

## Notes for the implementer

- **iTerm prefs are flushed on quit.** Any `defaults write` to `com.googlecode.iterm2` while iTerm is running can be silently overwritten when it quits. Always quit iTerm before running `apply-tmux-defaults.sh` (the script guards against this with a `pgrep` check).
- **Dynamic Profiles hot-reload** — editing `tmux.json` (through the symlink) takes effect without restarting iTerm. The `Guid` values must stay stable: `Default Bookmark Guid` references `dotfiles-tmux-cc`, so renaming the GUID breaks the default-profile wiring.
- **Nothing in this plan touches `.zshrc`, `.zprofile`, `.zshenv`, or the gpakosz `.tmux.conf` core.** The only shell-adjacent change is one line in `.tmux.conf.local`. There is no shell-startup regression surface.
- **Rollback:** delete the symlink + `tmux.json` (profile vanishes on hot-reload), reset `Default Bookmark Guid` to the prior value from `/tmp/iterm-before.txt`, and flip `@continuum-restore` back to `'on'`.
