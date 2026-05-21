#!/usr/bin/env bash
# Apply iTerm2 Session Restoration settings reproducibly.
#
# Why: iTerm's native Session Restoration runs each session inside a long-lived
# iTermServer daemon. iTerm reattaches to the daemon on relaunch — exact state
# restored, real processes still running. No tmux -CC, no control protocol race,
# no orphan client list (see tmux/tmux#2246 for the race we're escaping).
# Docs: https://iterm2.com/documentation-restoration.html
#
# IMPORTANT: iTerm rewrites its prefs from memory ON QUIT, clobbering external
# `defaults write` made while it's running. So: quit iTerm, run this, relaunch.
set -euo pipefail

DOMAIN=com.googlecode.iterm2
ORIGINAL_DEFAULT_GUID="74FD8F10-9C21-4853-AF71-8801DCF39FD7"

if pgrep -xq iTerm2 2>/dev/null || pgrep -xq iTerm 2>/dev/null; then
  echo "Quit iTerm first (Cmd+Q). It flushes prefs on quit and would overwrite these writes." >&2
  exit 1
fi

flush_prefs_cache() {
  # cfprefsd caches user defaults in memory. Without a flush, the next app to
  # read these keys may get stale values — observed: killJobsInServersOnQuit
  # was written to disk but iTerm's first launch still killed processes on
  # Cmd+Q. Killing cfprefsd forces it to re-read from disk on next request.
  killall cfprefsd 2>/dev/null || true
}
trap flush_prefs_cache EXIT

# -- Session Restoration ------------------------------------------------------
# runJobsInServers: jobs run inside iTermServer-* daemons that survive iTerm.
# killJobsInServersOnQuit=false: Cmd+Q preserves daemons (and processes).
# multiserver + useRestorableStateController: defaults YES, set explicitly to
# guard against past experimental toggles.
defaults write "$DOMAIN" runJobsInServers -bool true
defaults write "$DOMAIN" killJobsInServersOnQuit -bool false
defaults write "$DOMAIN" multiserver -bool true
defaults write "$DOMAIN" useRestorableStateController -bool true
defaults write "$DOMAIN" bootstrapDaemon -bool true
defaults write "$DOMAIN" showSessionRestoredBanner -bool false

# -- Startup mode: "Use system window restoration settings" -------------------
# All three startup flags off => iTerm defers to macOS window restoration,
# which is what Session Restoration needs.
defaults write "$DOMAIN" OpenArrangementAtStartup -bool false
defaults write "$DOMAIN" OpenBookmark -bool false
defaults write "$DOMAIN" AlwaysOpenWindowAtStartup -bool false

# -- macOS system pref --------------------------------------------------------
# Required for Session Restoration per iTerm docs. UI equivalent:
# System Settings > Desktop & Dock > UNCHECK "Close windows when quitting an app"
defaults write -g NSQuitAlwaysKeepsWindows -bool true

# -- Clean up tmux -CC era prefs (no-ops without -CC, but noise) --------------
defaults write "$DOMAIN" "Default Bookmark Guid" -string "$ORIGINAL_DEFAULT_GUID"
defaults write "$DOMAIN" LoadPrefsFromCustomFolder -bool false
defaults delete "$DOMAIN" PrefsCustomFolder                       2>/dev/null || true
defaults delete "$DOMAIN" OpenTmuxWindowsIn                       2>/dev/null || true
defaults delete "$DOMAIN" AutoHideTmuxClientSession               2>/dev/null || true
defaults delete "$DOMAIN" TmuxUnpauseAutomatically                2>/dev/null || true
defaults delete "$DOMAIN" NoSyncNewTabFromTmuxOpensTmux           2>/dev/null || true
defaults delete "$DOMAIN" NoSyncNewTabFromTmuxOpensTmux_selection 2>/dev/null || true
defaults delete "$DOMAIN" NoSyncNewWindowOpensTmux                2>/dev/null || true
defaults delete "$DOMAIN" NoSyncNewWindowOpensTmux_selection      2>/dev/null || true
defaults delete "$DOMAIN" NoSyncNewWindowOrTabFromTmuxOpensTmux   2>/dev/null || true

# -- Strip stale dynamic-profile bookmark rows --------------------------------
# When dotfiles-tmux-cc / dotfiles-plain-shell dynamic profiles are gone, iTerm
# will drop their rows on next launch — but stripping now avoids "two profiles
# share GUID" alerts during the transition. Also strip pollution keys that the
# -CC era leaked into the Default profile.
python3 <<'PY'
import plistlib
from pathlib import Path

p = Path.home() / "Library/Preferences/com.googlecode.iterm2.plist"
data = plistlib.loads(p.read_bytes())
bookmarks = data.get("New Bookmarks", [])

# Profile keys that broke -CC integration and have no business on plain shells.
strip_keys = {
    "Disable Window Resizing",
    "Custom Window Title",
    "Use Custom Window Title",
}
# Dotfiles-owned dynamic-profile GUIDs — bookmark rows get removed.
remove_guids = {"dotfiles-tmux-cc", "dotfiles-plain-shell"}

cleaned = []
seen = set()
for b in bookmarks:
    guid = b.get("Guid")
    if guid in remove_guids:
        continue
    if guid in seen:
        continue
    for k in strip_keys:
        b.pop(k, None)
    seen.add(guid)
    cleaned.append(b)
data["New Bookmarks"] = cleaned
plistlib.dump(data, p.open("wb"))
print("  Cleaned bookmarks (removed dotfiles-* dynamic-profile rows + pollution keys).")
PY

echo "Applied. Relaunch iTerm — sessions now restore via iTermServer daemons."
echo
echo "Verify (current values on disk):"
printf '  Default Bookmark Guid           = %s\n' "$(defaults read "$DOMAIN" 'Default Bookmark Guid' 2>/dev/null || echo '?')"
printf '  runJobsInServers                = %s\n' "$(defaults read "$DOMAIN" runJobsInServers 2>/dev/null || echo '?')"
printf '  killJobsInServersOnQuit         = %s (want 0)\n' "$(defaults read "$DOMAIN" killJobsInServersOnQuit 2>/dev/null || echo '?')"
printf '  AlwaysOpenWindowAtStartup       = %s (want 0)\n' "$(defaults read "$DOMAIN" AlwaysOpenWindowAtStartup 2>/dev/null || echo '?')"
printf '  OpenArrangementAtStartup        = %s (want 0)\n' "$(defaults read "$DOMAIN" OpenArrangementAtStartup 2>/dev/null || echo '?')"
printf '  NSQuitAlwaysKeepsWindows (-g)   = %s (want 1)\n' "$(defaults read -g NSQuitAlwaysKeepsWindows 2>/dev/null || echo '?')"
