# iTerm2 + Session Restoration

Persistence and "pick up where I left off" — without `tmux -CC`. Background and the why-not for `-CC` are in [`docs/superpowers/notes/2026-05-21-tmux-native-iterm-progress.md`](../../docs/superpowers/notes/2026-05-21-tmux-native-iterm-progress.md).

## How it works

iTerm runs each session inside a long-lived `iTermServer-*` daemon (see [iTerm Session Restoration docs](https://iterm2.com/documentation-restoration.html)). Your zsh, vim, `ping`, dev servers, etc. live inside the daemon. When iTerm quits or crashes, the daemons stay alive. When iTerm relaunches it reattaches to the existing daemons and you see exactly what you left.

```
iTerm UI  <--reattach-->  iTermServer (your zsh + running processes)
   ^                            ^
   | Cmd+Q kills the UI         | Daemon keeps running across Cmd+Q,
   | (with our settings)        | crash, and iTerm upgrades.
```

Native iTerm tabs (`⌘T`), splits (`⌘D`, `⇧⌘D`), scrollback, copy (`⌘C`), find (`⌘F`) — all of it just works because there is no protocol layer.

## Setup on a new machine

1. `./install.sh --link-only` (symlinks shell + tmux files, removes any stale dotfiles-era iTerm Dynamic Profile symlinks).
2. **Quit iTerm completely (⌘Q).**
3. `./config/iterm2/apply-iterm-defaults.sh`
4. Reopen iTerm.

The apply script sets:
- `runJobsInServers = true` (Session Restoration on)
- `killJobsInServersOnQuit = false` (⌘Q **preserves** processes)
- `OpenArrangementAtStartup / OpenBookmark / AlwaysOpenWindowAtStartup = false` (use macOS window restoration on startup)
- `NSQuitAlwaysKeepsWindows = true` (the global macOS pref — equivalent to System Settings → Desktop & Dock → uncheck "Close windows when quitting an application")
- Cleans up tmux `-CC` era keys (`OpenTmuxWindowsIn`, `AutoHideTmuxClientSession`, `NoSync*Tmux*`, etc.) and removes the dotfiles-owned dynamic-profile bookmark rows.

Verify after relaunch:

```bash
pgrep -fl iTermServer
defaults read com.googlecode.iterm2 killJobsInServersOnQuit   # 0
defaults read -g NSQuitAlwaysKeepsWindows                      # 1
```

### Fallback: if processes still die on Cmd+Q after running the script

macOS caches user defaults in `cfprefsd`; rarely iTerm reads a stale value before the cache flush propagates. The script kills `cfprefsd` on exit to avoid this, but if you still see processes die on the first ⌘Q, do it via the GUI once: **Settings → Advanced → Sessions section → "User-initiated quit (⌘Q) of iTerm2 will kill all running jobs."** must be **OFF**. iTerm writes the same key from the toggle and the in-memory state syncs immediately.

## Day-to-day behavior

| You do | What happens |
|--------|--------------|
| `⌘T` | New iTerm tab. Real shell. |
| `⌘D` / `⇧⌘D` | Split current pane (vertical / horizontal). |
| `⌘Q` | iTerm UI quits. iTermServer daemons keep running with your processes. |
| Relaunch iTerm | All previous windows / tabs / splits restored, processes still running. |
| Force-quit / crash / upgrade | Restored. |
| Reboot or log out | Daemons die with the user session; processes are lost. Use `tm` (below) for cross-reboot persistence. |

## Optional: plain tmux on top

If you need a process to survive a reboot, or you want tmux's own pane layouts inside a single iTerm tab, use the `tm` alias from [`.zsh.aliases`](../../.zsh.aliases):

```bash
tm   # attach to (or create) tmux session $tmux_session (default 'main')
```

Inside tmux, use the normal tmux keys:
- `Ctrl-a c` — new tmux window
- `Ctrl-a "` / `Ctrl-a %` — split (horizontal / vertical)
- `Ctrl-a [` — copy mode
- `Ctrl-a d` — detach (tmux server keeps your processes alive across reboots)

Session name lives in `tmux_session` (set in [`.zshenv`](../../.zshenv), override per-host via `~/.zshrc.local`).

Tmux is **not** auto-started. [`.tmux.conf`](../../.tmux.conf) and [`.tmux.conf.local`](../../.tmux.conf.local) are still symlinked so `tm` works when you want it.

## Why not `tmux -CC` anymore

Short version: `tmux -CC` over local tmux + `⌘Q` hits a known race in the control protocol ([tmux/tmux#2246](https://github.com/tmux/tmux/issues/2246) — `%exit` vs. in-flight iTerm queries). Symptoms include raw `%output` lines in new tabs, "session ended very soon after starting" warnings on reattach, and `tmux list-clients` filling up with stuck `wait-exit` orphans. iTerm Session Restoration sidesteps the entire protocol.

Long version in [`docs/superpowers/notes/2026-05-21-tmux-native-iterm-progress.md`](../../docs/superpowers/notes/2026-05-21-tmux-native-iterm-progress.md).
