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
  `defaults write` script (`config/iterm2/apply-tmux-defaults.sh`) — **written**.
  It sets the default-profile GUID and the bury flag (both certain), plus
  `OpenTmuxWindowsIn -int 2` for "tabs in existing window" (best value; the script
  prints all three back for verification, and the enum is documented inline). It
  refuses to run while iTerm is open (iTerm clobbers external writes on quit).
  Still **needs to be run** once (with iTerm quit) — see Pending.
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
3. **Run `config/iterm2/apply-tmux-defaults.sh`** (`e9f8e3a` on `origin/main`). Quit
   iTerm, run it, relaunch — replaces manual GUI in step 1. Confirm
   `OpenTmuxWindowsIn` = tabs in existing window (enum in script comments).
4. **This machine only (if needed):** if `LoadPrefsFromCustomFolder` was enabled
   during the plist experiment, add to the apply script (or run once):
   `LoadPrefsFromCustomFolder=false` and delete `PrefsCustomFolder`. Optional
   follow-up to push: `session-name` + `render-tmux-profile.sh` (one-line session
   edit) — see untracked `config/iterm2/README.md` on laptop.
5. **Gesture check (Task 3):** confirm `⌘T` / `⌘D` / `⌘⇧D` produce native
   tabs/splits backed by real tmux objects (`tmux list-windows` / `list-panes`).
6. **End-to-end persistence test (Task 8):** start a long process, ⌘Q, reopen,
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

---

## Pivot away from `-CC` (2026-05-21)

After repeated reattach failures (raw `%output` dumps, "session ended very soon
after starting" warnings, stuck `wait-exit` orphans in `tmux list-clients`),
we abandoned `tmux -CC` for the local-tmux + ⌘Q workflow. New direction:
**iTerm's native Session Restoration** — see [`config/iterm2/README.md`](../../../config/iterm2/README.md).

### Why `-CC` couldn't be made reliable for this workflow

- The `-CC` control protocol has a known race on detach
  ([tmux/tmux#2246](https://github.com/tmux/tmux/issues/2246)): after `%exit`,
  iTerm may still have in-flight queries that arrive after tmux has changed
  state. iTerm mitigates with `wait-exit` but the iTerm Best Practices wiki is
  explicit: *"iTerm2 cannot reliably detect when control mode has been
  cleanly exited."*
- Examples that work in the wild (Eugene Oleinik's blog, the iTerm wiki) are
  all `-CC` **over SSH**. SSH connection death cleans up the client naturally
  via TCP timeout / sshd reaping. Local iTerm + ⌘Q has no such cleanup; iTerm
  is killed before the protocol handshake completes, leaving orphan clients.
- Adding `-D` (`new-session -A -D`) to detach orphans on reattach traded the
  "raw output" failure for a "session ended very soon after starting" error
  because the `client-detached` event iTerm raised on the orphan was
  interpreted as the new client also leaving.
- `AutoHideTmuxClientSession` + `OpenTmuxWindowsIn=2` has a documented bug
  ([iterm2-discuss](https://iterm2-discuss.narkive.com/MmEpKW19/automatically-bury-the-tmux-client-session-loses-open-tmux-windows-as-tabs))
  where the gateway tab isn't reliably buried. The gateway's
  `tmuxMode == TMUX_GATEWAY` (not `TMUX_CLIENT`), so ⌘T from a still-visible
  gateway tab bypasses tmux integration entirely
  ([PTYSession.m `isTmuxClient`](https://github.com/gnachman/iTerm2/blob/master/sources/PTYSession.m)).

### What replaced it

iTerm's [Session Restoration](https://iterm2.com/documentation-restoration.html):
sessions run inside `iTermServer-*` daemons; iTerm reattaches to them on
relaunch. No control protocol, no race, no orphan clients. ⌘Q preserves
processes when `killJobsInServersOnQuit = false`. Tradeoff: processes don't
survive a reboot/logout (the daemons die with the user session). For
cross-reboot persistence, use plain tmux via the `tm` alias.

### Repo cleanup committed with the pivot

- Removed `config/iterm2/DynamicProfiles/{tmux,plain}.json`,
  `config/iterm2/session-name`, `config/iterm2/render-tmux-profile.sh`.
- Renamed `apply-tmux-defaults.sh` → `apply-iterm-defaults.sh` and rewrote
  body for Session Restoration.
- Rewrote `config/iterm2/README.md`.
- `install.sh` now removes stale dotfiles-owned dynamic-profile symlinks
  instead of creating them.
- `.zshenv`: dropped the read-from-`session-name` block; `tmux_session` keeps
  its `main` default, overridable via `~/.zshrc.local`.
- `.tmux.conf` and `.tmux.conf.local` are unchanged and still symlinked, so
  `tm` works whenever you want explicit tmux.
