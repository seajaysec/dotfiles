# tmux-native iTerm — progress, decisions, and rationale

*Status as of 2026-05-21. Implementation ~80% done; one manual GUI step + a
defaults-capture step + the apply script remain. Everything below that says
"verified" was checked against the live machine, not assumed.*

Related docs:
- Spec: `docs/superpowers/specs/2026-05-20-tmux-native-iterm-design.md`
- Plan: `docs/superpowers/plans/2026-05-20-tmux-native-iterm.md`

---

## The goal (in one sentence)

Make tmux the substrate of iTerm's windows/tabs/panes so that **quitting iTerm
and reopening restores every running process live**, with **no `.zshrc`
involvement** and native `⌘T`/`⌘D`/`⌘⇧D` gestures driving tmux.

## Why this shape — the decisions and the reasoning

### 1. iTerm tmux integration (`tmux -CC` control mode), not raw tmux
`-CC` makes tmux windows render as *native* iTerm windows/tabs/panes. Closing
iTerm leaves the tmux **server** running; reopening and re-attaching brings
everything back **live** (real processes, not a relaunched snapshot). This is the
mechanism that actually delivers "close the app and restore."

### 2. A version-controlled **Dynamic Profile** launches tmux — never `.zshrc`
This is the keystone decision and the direct answer to "putting things in
`.zshrc` is the worst way to do this." The launch lives in *iTerm's profile*, not
the shell:

- File: `config/iterm2/DynamicProfiles/tmux.json` (in the repo), symlinked into
  `~/Library/Application Support/iTerm2/DynamicProfiles/tmux.json` by
  `install.sh`. iTerm watches that folder and **hot-reloads** — no restart.
- The `tmux` profile sets `"Custom Command": "Yes"` and
  `"Command": "/opt/homebrew/bin/tmux -CC new-session -A -s main"`.
- **`.zshrc` runs unchanged inside the panes tmux spawns.** Zero new
  context-detection branches (no "am I an agent / a GUI child / already in
  tmux?" guessing). That fragility was the whole reason to avoid the shell path.

**Why the absolute path `/opt/homebrew/bin/tmux`:** a Custom Command does *not*
go through a login shell, so `.zprofile`'s PATH isn't set when the command
itself launches. Absolute path is robust. The spawned panes still get full login
env, so everything inside behaves normally. (Intel path would be
`/usr/local/bin/tmux`; out of scope, noted in a comment.)

**Why `new-session -A -s main`:** `-A` = attach-if-exists-else-create. The same
command both creates the session the first time and re-attaches afterward — one
deterministic action for "open" and "restore."

### 3. `tmux` is the **default** profile (+ a `Plain` escape hatch)
You asked for seamless: every new iTerm window lands straight in `main`. So the
`tmux` profile is set as iTerm's default (via the `Default Bookmark Guid`
preference pointing at GUID `dotfiles-tmux-cc`). A second profile, `Plain`
(`dotfiles-plain-shell`, no custom command), ships in the same file as a
guaranteed non-tmux shell one ⌘O away on any machine.

**Known quirk this introduces (`⌘N`):** with `tmux` as default, `⌘N` (new iTerm
*window*) launches a *second* `-CC` client attached to the same `main` session —
a second native mirror. Legitimate (handy on a second display), not a bug. Habit:
use `⌘T` for a new tab/window inside the session; use `Plain` for a fresh shell.

### 4. Single persistent session `main`
Simplest possible model; trivial restore semantics. Per-project sessions were
considered and rejected (needs a chooser/attach workflow without clear payoff
here).

### 5. Live-only persistence; **continuum auto-restore disabled**
`.tmux.conf.local` previously had `@continuum-restore 'on'` (resurrect+continuum,
1-min autosave). That's a *different* mechanism — it relaunches a saved layout
from disk, it does not keep live processes. With a live `-CC` server, continuum's
restore only fires on a *fresh* server start (after reboot/`kill-server`), where
it would spawn a **stale duplicate layout** alongside the fresh attach — exactly
the collision we don't want. So: `@continuum-restore 'off'`. Plugins stay
installed; flip one line back to `'on'` if you ever want reboot-resurrection.
This is the agreed accepted-loss: a reboot/server-kill ends processes.

### 6. Settings sync boundary: profile in repo, app-level toggles via a script
- Version-controlled: the tiny, diffable `tmux.json`.
- App-level tmux toggles (can't live in a profile) get a reproducible
  `defaults write` script (`config/iterm2/apply-tmux-defaults.sh`) — **not yet
  written**, see Pending. Its exact keys are captured empirically (toggle in UI,
  read back) rather than guessed.
- **Rejected:** the whole-plist "Load settings from a custom folder" approach —
  it reintroduces large binary-plist churn on every UI tweak (the same problem as
  the 20 MB state export).

### 7. Removed the 20 MB `iTerm2 State.itermexport` from the repo
Machine-specific binary bloat, off the critical path now. (Turned out it was
*already* untracked via a `*.itermexport` gitignore rule from a prior cleanup;
goal already met. `iTermProfiles.json` kept as a reference export.)

### 8. **`mouse off`** — the real bug found during testing
Originally `set -g mouse on`. Under `-CC`, a scroll/trackpad gesture makes *tmux*
grab the event and drop the pane into **copy-mode (view-mode)**, which silently
swallows keystrokes — a live shell you cannot type into. This was observed and
diagnosed on the live server (`pane_in_mode=1 mode=view-mode cmd=zsh`, shell pid
alive). iTerm handles the mouse natively in `-CC` (click-to-focus, drag-resize,
click-drag select, native scrollback) by translating gestures into tmux
commands, so turning tmux's own mouse off **loses no capability** — it's actually
better scrollback. Changed to `set -g mouse off`; applied live and persisted.
`.tmux.conf.local` carries a comment showing how to re-enable conditionally
(control-mode hook) if you ever want tmux mouse in *plain* (non-`-CC`) tmux.

### 9. (Housekeeping, separate) Removed the GSD `.planning/` machinery
Past its usefulness; deleted with references scrubbed from README/SYNC.

---

## What is DONE and verified

| Area | State | Evidence |
|------|-------|----------|
| `tmux.json` (`tmux` + `Plain`) | ✅ committed | parses via `plutil -extract`; iTerm shows both profiles (you confirmed) |
| `install.sh` symlink | ✅ committed | symlink resolves into repo; idempotent re-run clean |
| Live deploy | ✅ | `~/Library/.../DynamicProfiles/tmux.json` → repo; iTerm reads `Name: tmux` |
| `@continuum-restore 'off'` | ✅ committed | `grep` shows `off`, no `on` |
| 20 MB itermexport | ✅ | not tracked (gitignored) |
| README / SYNC docs | ✅ committed | tmux section + fresh-machine step added |
| **`mouse off` bugfix** | ✅ committed, live + persistent | live server `mouse off`; `~/.tmux.conf.local` symlink → repo line 288 |
| tmux launching works | ✅ (you confirmed) | "the rest was working without a reboot" after the mouse fix |

**Commits on `main` (pushed):**
`6c154fa` profile · `a5df14c` install symlink · `c496815` continuum off ·
`bb88cef` plan plutil fix · `fb93cbb` mouse-off bugfix · `3d7d5cf` doc update ·
plus earlier `774ae6f` GSD removal, `adb54e2`/`793ffcc` spec, `0b7019e` plan.

---

## What is PENDING (resume here)

1. **Set `tmux` as the default profile** (manual GUI — you were AFK before this):
   Settings ▸ Profiles ▸ `tmux` ▸ Other Actions ▸ **Set as Default**. Plus, in
   Settings ▸ General ▸ tmux: "When attaching, restore windows as…" → **Tabs in
   the existing window**, and enable **"Automatically bury the tmux client
   session after connecting"**. Then **⌘Q and reopen** so prefs flush.
2. **Capture the three `defaults` keys** after step 1 (snapshot already saved at
   `/tmp/iterm-before.txt`):
   - `Default Bookmark Guid` → should become `dotfiles-tmux-cc` (was
     `74FD8F10-9C21-4853-AF71-8801DCF39FD7`)
   - `OpenTmuxWindowsIn` → integer for "tabs in existing window" (currently unset)
   - `AutoHideTmuxClientSession` → bool (currently unset)
3. **Write `config/iterm2/apply-tmux-defaults.sh`** from the captured values
   (README + SYNC already reference this path, so it must exist to avoid a
   dangling reference). Must guard against running while iTerm is open (iTerm
   overwrites external `defaults write` on quit) — quit iTerm, run script,
   relaunch.
4. **Gesture check (Task 3):** confirm `⌘T` / `⌘D` / `⌘⇧D` produce native
   tabs/splits backed by real tmux objects (`tmux list-windows` / `list-panes`).
5. **End-to-end persistence test (Task 8):** start a long process, ⌘Q, reopen,
   confirm it's still running; confirm `Plain` is a non-tmux shell; confirm no
   stale continuum layout after `kill-server` + reopen.

---

## Gotchas to remember (operational)

- **⌘Q (quit) detaches and KEEPS processes. `⌘W` / closing a window KILLS them.**
  To preserve work, quit or use Shell ▸ tmux ▸ Detach — never "close."
- iTerm flushes prefs to disk **on quit**; external `defaults write` made while
  it's running gets clobbered. Always quit iTerm before scripting its prefs.
- Dynamic Profiles hot-reload; the `Guid` values are load-bearing
  (`Default Bookmark Guid` references `dotfiles-tmux-cc`) — don't rename them.
- Nothing here touches `.zshrc` / `.zprofile` / `.zshenv` or the gpakosz
  `.tmux.conf` core. The only tmux change is in `.tmux.conf.local`
  (continuum-restore off, mouse off). No shell-startup regression surface.

## If you want to back it all out

Delete the symlink + `tmux.json` (profile vanishes on hot-reload), reset
`Default Bookmark Guid` to `74FD8F10-9C21-4853-AF71-8801DCF39FD7` (from
`/tmp/iterm-before.txt`), and flip `@continuum-restore` back to `'on'` and
`mouse` back to `on` in `.tmux.conf.local`.
