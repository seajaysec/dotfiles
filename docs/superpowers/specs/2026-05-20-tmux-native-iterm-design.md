# Design: tmux-native iTerm, synced from this repo

*Date: 2026-05-20*

## Goal

Make tmux the substrate for iTerm windows/tabs/panes so that **quitting iTerm
and reopening it restores every running process live** — without any
`.zshrc`-based auto-launch or context-detection logic. Native iTerm gestures
(`⌘T`, `⌘D`, `⇧⌘D`, `⌘W`, tab nav) drive tmux directly. Configuration lives in
this repo and deploys via `install.sh`.

## Why this approach (the `.zshrc` problem it avoids)

Past pain came from trying to launch/route tmux inside `.zshrc`, where the shell
must guess its context (interactive? agent? GUI parent? already in tmux?). That
branching is fragile because `.zshrc` is sourced through many code paths.

iTerm's **tmux integration (`-CC` control mode)** moves the launch decision out
of the shell entirely: *iTerm* decides to start tmux when a specific profile is
opened. `.zshrc` then runs unchanged inside the panes tmux spawns — exactly as
today, with **zero new detection branches**.

## Architecture

### 1. Dynamic Profile (the launcher)

A version-controlled Dynamic Profile lives at
`config/iterm2/DynamicProfiles/tmux.json` and is symlinked into
`~/Library/Application Support/iTerm2/DynamicProfiles/`. iTerm watches that
folder and hot-reloads on change.

```json
{
  "Profiles": [
    {
      "Name": "tmux",
      "Guid": "dotfiles-tmux-cc",
      "Custom Command": "Yes",
      "Command": "/opt/homebrew/bin/tmux -CC new-session -A -s main"
    }
  ]
}
```

- **Absolute path `/opt/homebrew/bin/tmux`**: a Custom Command does not run
  through a login shell, so `.zprofile`'s PATH is not set when the command
  itself launches. The absolute path is robust. (The panes tmux spawns *do* get
  the full login env, so `.zshrc`/`.zprofile` behave normally inside them.)
  - On an Intel Mac the path would be `/usr/local/bin/tmux`. The repo targets
    Apple Silicon; document the Intel path in a comment for portability.
- **`new-session -A -s main`**: `-A` = "attach if it exists, else create." The
  same command both creates the session the first time and reattaches after a
  quit. One deterministic command for both paths.

**Entry point**: `tmux` is a *dedicated, non-default* profile. The plain login
shell stays the default profile. Open tmux deliberately (⌘O → `tmux`, or bind it
to a hotkey/default bookmark later). This keeps a clean non-tmux shell one
keystroke away.

### 2. Session model: single `main`

One persistent session named `main`. Everything lives there; restore semantics
are trivial to reason about. (Per-project sessions were considered and rejected
for now — they add a chooser/attach workflow without clear payoff for this use.)

### 3. Persistence model: live-only

- **Quit iTerm (⌘Q) → tmux server keeps running → reopen, open `tmux` profile →
  everything is back, live.** Processes never died; the client merely detached.
- A full reboot or explicit `tmux kill-server` *does* end processes. This is
  accepted ("provided the processes haven't been killed through some other
  means").
- **Disable continuum auto-restore.** `.tmux.conf.local` currently sets
  `@continuum-restore 'on'` with a 1-minute save interval. With a live server,
  continuum's "relaunch saved layout on server start" only fires after a
  reboot/server-death — where it would spawn a *stale duplicate* layout
  alongside the fresh attach. Set `@continuum-restore 'off'`. Leave the
  resurrect/continuum plugins installed so the behavior can be re-enabled with a
  one-line change if reboot-resurrection is wanted later.
  - This is the **only** change to tmux config, and it is in `.tmux.conf.local`
    (the user-customization file), never the gpakosz `.tmux.conf` core.

### 4. Native shortcut mapping (the integration)

In a `-CC` window, iTerm translates native gestures into tmux commands:

| Gesture | tmux operation | Result |
|--------|----------------|--------|
| `⌘T` | `new-window` | new native tab, backed by a tmux window |
| `⌘D` | `split-window -h` | side-by-side pane (tmux-backed) |
| `⇧⌘D` | `split-window -v` | stacked pane (tmux-backed) |
| `⌘W` | kill pane/window | **genuinely ends** that pane/window |
| `⌘←/⌘→`, `⌘1/2/3` | select-window | tab navigation |

The tmux `⌃a` prefix bindings also remain available, so native muscle memory
works locally **and** prefix-key control works when SSH'd into the same session
from elsewhere or in text mode.

**Critical UX gotcha (must be documented loudly):**
`⌘W` / closing a window **kills** those tmux processes. To *keep them alive*,
**detach**: ⌘Q (quit iTerm) or **Shell ▸ tmux ▸ Detach**. The intended
"close the app and restore" workflow (⌘Q) is the safe one.

**Inherent tmux constraints (small, not iTerm's fault):**
- All windows in a tmux session share one size (uniform rows/cols).
- A tab cannot mix a tmux pane and a non-tmux pane.

### 5. Settings sync boundary

- **In the repo (version-controlled):** `config/iterm2/DynamicProfiles/tmux.json`
  — tiny, readable, diffable.
- **App-level tmux-integration toggles** (cannot live in a profile) are captured
  as a reproducible `defaults write com.googlecode.iterm2 …` snippet in the
  install docs. Target settings:
  - "When attaching, restore windows as…" → **Tabs in the existing window**
  - "Automatically bury the tmux client session after connecting" → **on**
  - The **exact `defaults` keys/values must be confirmed empirically** during
    implementation by toggling each option in the iTerm UI and reading it back
    with `defaults read com.googlecode.iterm2 | grep -i tmux`. Do not hardcode
    guessed keys.
- **Remove `iTerm2 State.itermexport`** (~20 MB binary) from the repo. It is
  machine-specific bloat, not "synced live," and works against the clean-repo
  goal. `iTermProfiles.json` may stay as a reference export or also be removed
  (decide during implementation; default: keep as reference).
- The whole-plist "Load settings from a custom folder" approach was **rejected**
  — it reintroduces large binary-plist churn on every UI tweak.

### 6. `install.sh` integration

Add one guarded `symlink_init` line in `link_dotfiles()`:

```bash
symlink_init "config/iterm2/DynamicProfiles/tmux.json" \
  "${HOME}/Library/Application Support/iTerm2/DynamicProfiles/tmux.json"
```

Idempotent and backup-aware via the existing `backup_if_needed`. No other shell
init changes.

### 7. Unchanged

- `ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES` (already set, `.zshrc:234`) —
  keeps iTerm shell integration working inside `-CC`.
- oh-my-tmux theme, keybindings, plugins, Starship, the gpakosz `.tmux.conf`
  core — all untouched.
- `set -g mouse on` stays; native iTerm mouse selection works in `-CC`. If
  selection ever misbehaves, this is the first knob.

## Files touched

| File | Change |
|------|--------|
| `config/iterm2/DynamicProfiles/tmux.json` | **new** — Dynamic Profile launcher |
| `.tmux.conf.local` | `@continuum-restore` `'on'` → `'off'` |
| `install.sh` | one `symlink_init` line for the Dynamic Profile |
| `iTerm2 State.itermexport` | **deleted** from repo |
| `README.md` / `SYNC.md` | document the tmux workflow, the ⌘Q-vs-⌘W gotcha, and the `defaults write` snippet |

## Verification

1. `./install.sh --link-only` → confirm symlink exists:
   `ls -l "$HOME/Library/Application Support/iTerm2/DynamicProfiles/tmux.json"`
   resolves into the repo.
2. iTerm shows a profile named `tmux` (Settings ▸ Profiles) without restart
   (hot-reload).
3. Open the `tmux` profile → lands in a `-CC` session named `main`; status bar
   reflects tmux.
4. `⌘T`, `⌘D`, `⇧⌘D` create tmux windows/panes; `tmux list-windows`/`list-panes`
   from another client confirms they are real tmux objects.
5. Start a long-running process (e.g. `ping -i5 1.1.1.1`), **⌘Q** iTerm, reopen,
   open `tmux` profile → process is still running, output continues.
6. Confirm `@continuum-restore 'off'` took effect: after a `tmux kill-server`
   and fresh attach, no stale duplicate windows appear.

## Rollback

- Remove the symlink and the `tmux.json` file; iTerm hot-reloads and the profile
  disappears.
- Re-flip `@continuum-restore 'on'` to restore prior behavior.
- The gpakosz core, `.zshrc`, and login flow are never modified, so there is no
  shell-startup regression surface.

## Non-goals

- Reboot-survival of live processes (accepted loss; continuum can be re-enabled
  if this changes).
- Per-project session orchestration.
- Cross-platform/Intel-primary support (Intel tmux path noted in a comment only).
- Whole-plist sync via custom folder.
