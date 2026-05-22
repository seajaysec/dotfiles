# iTerm2 — Session Restoration + power-user setup

Persistence and "pick up where I left off" via iTerm's native [Session Restoration](https://iterm2.com/documentation-restoration.html) (no `tmux -CC`), plus a power-user layer (status bar, APS, snippets, triggers, keybindings) configured reproducibly by [`apply-iterm-defaults.sh`](apply-iterm-defaults.sh).

History and the why-not for `-CC` is in [`docs/superpowers/notes/2026-05-21-tmux-native-iterm-progress.md`](../../docs/superpowers/notes/2026-05-21-tmux-native-iterm-progress.md).

## Setup on a new machine

1. `./install.sh --link-only` — symlinks shell files, renders APS profiles for `$HOME`, removes stale `-CC` era files.
2. **Quit iTerm completely (⌘Q).**
3. `./config/iterm2/apply-iterm-defaults.sh`
4. Reopen iTerm.
5. In the GUI (one-time): Settings → Profiles → Default → Session → check **"Status bar enabled"** if it isn't already. (The layout is already written; this just turns the bar on.)

Verify after relaunch:

```bash
pgrep -fl iTermServer                                                    # at least one
defaults read com.googlecode.iterm2 killJobsInServersOnQuit              # 0
defaults read -g NSQuitAlwaysKeepsWindows                                # 1
defaults read com.googlecode.iterm2 IRMemory                             # 32
```

### Fallback: if processes still die on Cmd+Q after running the script

macOS caches user defaults in `cfprefsd`; rarely iTerm reads a stale value before the cache flush propagates. The script kills `cfprefsd` on exit, but if you still see processes die on the first ⌘Q, toggle it via the GUI once: **Settings → Advanced → Sessions → "User-initiated quit (⌘Q) of iTerm2 will kill all running jobs."** must be **OFF**.

## How Session Restoration works

```
iTerm UI  <--reattach-->  iTermServer (your zsh + running processes)
   ^                            ^
   | Cmd+Q kills the UI         | Daemon keeps running across Cmd+Q,
   | (with our settings)        | crash, and iTerm upgrades.
```

Native iTerm tabs (`⌘T`), splits (`⌘D`, `⇧⌘D`), scrollback, copy (`⌘C`), find (`⌘F`) — no protocol layer.

## Day-to-day behavior

| You do | What happens |
|--------|--------------|
| `⌘T` | New iTerm tab. Real shell. |
| `⌘D` / `⇧⌘D` | Split current pane (vertical / horizontal). |
| `⌘Q` | iTerm UI quits. iTermServer daemons keep running with your processes. |
| Relaunch iTerm | All previous windows / tabs / splits restored, processes still running. |
| Force-quit / crash / upgrade | Restored. |
| Reboot or log out | Daemons die with the user session; processes are lost. Use `tm` (below) for cross-reboot persistence. |

## Status bar (replaces Starship)

Set on the Default profile by the apply script. Layout (left → right):

```
username | cwd | 🐍 venv + Python version | git | composer
```

Canonical layout: [`status-bar-layout.json`](status-bar-layout.json) (copied from your hand-edited setup). Status bar string: `🐍 \(user.python_venv) \(user.python_version)`.

- `python_venv` / `python_version` are published by `iterm2_print_user_vars` in [`.zshrc`](../../.zshrc) (reads `$VIRTUAL_ENV`).
- Starship is wrapped in a `DOTFILES_PROMPT=starship` guard in [`.zshrc`](../../.zshrc) — default is `iterm`, so Starship is skipped.
- To re-enable Starship on a specific host: `export DOTFILES_PROMPT=starship` in `~/.zshrc.local`.

## Automatic Profile Switching (per project directory)

Project profiles in [`DynamicProfiles/aps-projects.json`](DynamicProfiles/aps-projects.json) (edit there — **do not** create APS profiles in the GUI or tag them “Dynamic”; that creates broken bookmark rows and can crash the profile editor):

| Bound path | Profile | Tab color |
|---|---|---|
| `$HOME` | Project: home | gray |
| `$HOME/gits*` | Project: gits | purple |
| `$HOME/dotfiles*` | Project: dotfiles | teal |
| `$HOME/gits/avars*` | Project: avars | pink |
| `$HOME/gits/xanatos-lab*` | Project: xanatos-lab | green |
| `$HOME/gits/xanatos` (+ subdirs, not lab) | Project: xanatos | cyan |
| `$HOME/gits/vkb-python*` | Project: vkb-python | yellow-green |
| `$HOME/work*` | Project: work | orange |

Source template: [`DynamicProfiles/aps-projects.json.in`](DynamicProfiles/aps-projects.json.in) (`__HOME__` → your home at install). Render: `./config/iterm2/render-aps-projects.sh` or `./install.sh --link-only`. **Do not** edit `aps-projects.json` in Application Support by hand — it is regenerated.

More specific paths (e.g. `vkb-python`) win over parent paths (`gits`) via APS scoring. Run `apply-iterm-defaults.sh` (iTerm quit) after install to prune orphan GUI bookmarks.

APS switches the live session's profile in place (Tab color, font, anything you override) when the cwd matches. Leaves dir → reverts to Default. Requires Shell Integration (already sourced from [`.zshrc:221`](../../.zshrc)).

## Snippets

Seeded from [`snippets.json`](snippets.json). Reach via **Edit → Snippets**, the Snippets toolbelt, the Snippets status bar component, or per-snippet shortcuts you assign:

- `whocerts <domain>`, `mkvenv 3.x`, `pipr`, `dualping <target>`, `pbpaste | grepip`, `nmapr --top-ports 100`, `gwip`, `gcx`, `getJSON`, `dockstop && dockrm`.

All identifiable by the `dotfiles-snippet-` GUID prefix — apply script preserves your own snippets, replaces only the dotfiles ones.

## Triggers

Three live on the Default profile (idempotent via the `dotfiles:` name prefix):

| Name | Regex | Action |
|---|---|---|
| dotfiles: error/fail highlight | `(?i)\b(error\|fail(ed\|ure)?\|FATAL\|panic\|traceback)\b` | Highlight white-on-red |
| dotfiles: build done bell | `\bBUILD (SUCCESS\|SUCCEEDED\|PASSED\|FAILED)\b` | Ring bell |
| dotfiles: prod host bounce | `@(prod\|production\|live)[A-Za-z0-9._-]*` | Bounce dock icon |

Edit / disable any of them: Settings → Profiles → Default → Advanced → Edit Triggers.

## Keybindings

Set in `GlobalKeyMap` by the apply script, identifiable by `dotfiles:` label prefix:

| Combo | Action | Notes |
|---|---|---|
| ⌘E | Open Composer | Replaces the awkward default ⌘⇧. |
| ⌘⌥E | Toggle Auto Composer | Always-on prompt editor mode |
| ⌘⇧N | Add Annotation at Cursor | Sticky note pinned to buffer location |
| ⌘⌥V | Paste, stripping newlines | One-shot; no Advanced Paste dialog |
| ⌘⌥B | Start Instant Replay | iTerm default; buffer now 32 MB per session |

### Useful built-ins worth knowing (not changed)

- **⌘;** — autocomplete from current scrollback (great for grabbing URLs / IPs / hashes already on screen without retyping).
- **⌘⇧;** — recent commands (across sessions, via Shell Integration).
- **⌘⇧↑ / ⌘⇧↓** — jump between command prompts (Shell Integration marks).
- **⌘⇧A** — Select Output of Last Command (then ⌘C to copy it).
- **⌘⇧H** — Paste History.

## Optional: plain tmux on top

Cross-reboot persistence still needs tmux. Use the `tm` alias from [`.zsh.aliases`](../../.zsh.aliases):

```bash
tm    # attach to (or create) tmux session $tmux_session (default 'main')
```

Inside tmux: `Ctrl-a c` (new window), `Ctrl-a " / %` (splits), `Ctrl-a [` (copy mode), `Ctrl-a d` (detach). Tmux is **not** auto-started.

## No-go calls (and why)

- **Hotkey window** — fundamentally a separate iTerm window; tabs can be dragged out into normal windows but the hotkey behavior is window-attached, not session-attached. If you want one anyway, Settings → Keys → Create a Dedicated Hotkey Window.
- **Minimap** — iTerm doesn't have one. Closest things: Instant Replay (`⌘⌥B`, time-travel through buffer) and Shell Integration's `⌘⇧↑/↓` prompt-jumping.
- **Tab badges** — distracting; we use APS tab color instead.
- **Whole-plist iCloud sync** — explicitly avoided. `NoSync*` keys (snippets, key bindings dialog selections, etc.) are designed to stay per-machine; dotfiles ships only what we want shared.
- **iTerm AI Chat** — requires API keys (no OAuth/consumer login). Use `claude` (Claude Code) or Cursor's `cursor-agent` CLI inside a tab instead.

## What your existing stack already does better

| Need | Use this | Why |
|---|---|---|
| Directory recall | `z` / zoxide | Global, frecency-ranked. Beats iTerm's per-session Recent Directories. |
| Fuzzy history / files | `fzf` (`Ctrl-R`, `Ctrl-T`) | Richer matcher than `⌘⇧;`. |
| Grab a token off the screen | `⌘;` | Reads from current scrollback — fzf can't see that. |
| Cross-session command recall | `⌘⇧;` | Shell Integration; lighter than fzf for "what did I run yesterday". |

## Repo layout

- [`apply-iterm-defaults.sh`](apply-iterm-defaults.sh) — single source of truth for prefs. Sections labeled `B1` through `B5`.
- [`snippets.json`](snippets.json) — dotfiles snippets (loaded into `NoSyncSnippets`).
- [`DynamicProfiles/aps-projects.json.in`](DynamicProfiles/aps-projects.json.in) — APS template (`__HOME__` paths).
- [`render-aps-projects.sh`](render-aps-projects.sh) — render machine-local `aps-projects.json`.
- [`status-bar-layout.json`](status-bar-layout.json) — canonical status bar (hand-edited).
- [`README.md`](README.md) — this file.

Re-running the apply script is safe and idempotent (status bar, snippets, triggers, keybindings, IRMemory all checked).
