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

# -- B1: Status bar layout (Starship parity) ---------------------------------
# Sets a per-profile Status Bar Layout on the Default profile with:
#   user | host(+ssh) | python_venv | git | cwd | spring | composer
# Powered by Shell Integration (already sourced from .zshrc); python_venv is
# read from the user_var published by iterm2_print_user_vars in .zshrc.
# Enables the status bar via `Show Status Bar = True`.
python3 <<'PY'
import plistlib
from pathlib import Path

p = Path.home() / "Library/Preferences/com.googlecode.iterm2.plist"
data = plistlib.loads(p.read_bytes())

def knobs(extra=None):
    base = {
        "base: priority": 5,
        "base: compression resistance": 1,
    }
    if extra:
        base.update(extra)
    return base

# python_venv user_var component: iTermStatusBarVariableBaseComponent reads from
# session variable scope; "path" knob = "user.python_venv" (set by zsh hook).
venv_knobs = knobs({
    "path": "user.python_venv",
    "prefix": "  ",
    "minwidth": 0,
    "maxwidth": 60,
})

cwd_knobs = knobs({
    "path": "path",  # or "shortPath" for fish-style abbreviation
    "minwidth": 0,
    "maxwidth": 1.7976931348623157e+308,
})

host_knobs = knobs({
    "prefix": "  ",  # nf-fa-server glyph; remove if your font lacks Nerd icons
    "minwidth": 0,
    "maxwidth": 60,
})

user_knobs = knobs({
    "prefix": "  ",
    "minwidth": 0,
    "maxwidth": 60,
})

git_knobs = knobs({
    "minwidth": 0,
    "maxwidth": 200,
})

spacer_knobs = knobs({"iTermStatusBarFixedSpacerComponentWidthKnob": 8})

layout = {
    "components": [
        {"class": "iTermStatusBarUserComponent",             "configuration": {"knobs": user_knobs}},
        {"class": "iTermStatusBarFixedSpacerComponent",      "configuration": {"knobs": spacer_knobs}},
        {"class": "iTermStatusBarHostnameComponent",         "configuration": {"knobs": host_knobs}},
        {"class": "iTermStatusBarFixedSpacerComponent",      "configuration": {"knobs": spacer_knobs}},
        {"class": "iTermStatusBarVariableBaseComponent",     "configuration": {"knobs": venv_knobs}},
        {"class": "iTermStatusBarFixedSpacerComponent",      "configuration": {"knobs": spacer_knobs}},
        {"class": "iTermStatusBarGitComponent",              "configuration": {"knobs": git_knobs}},
        {"class": "iTermStatusBarFixedSpacerComponent",      "configuration": {"knobs": spacer_knobs}},
        {"class": "iTermStatusBarWorkingDirectoryComponent", "configuration": {"knobs": cwd_knobs}},
        {"class": "iTermStatusBarSpringComponent",           "configuration": {"knobs": knobs()}},
        {"class": "iTermStatusBarComposerComponent",         "configuration": {"knobs": knobs()}},
    ],
    "advanced configuration": {
        "remove empty components": True,  # hides venv segment when not in a venv
        "auto-rainbow style": 0,
        "font": ".AppleSystemUIFont 12",
        "algorithm": 0,  # 0 = stable, components fixed-width per knob
    },
}

ORIGINAL_DEFAULT_GUID = "74FD8F10-9C21-4853-AF71-8801DCF39FD7"
default = next(b for b in data["New Bookmarks"] if b.get("Guid") == ORIGINAL_DEFAULT_GUID)
default["Show Status Bar"] = True
default["StatusBarPosition"] = 1  # 0=top, 1=bottom
default["Status Bar Layout"] = layout

plistlib.dump(data, p.open("wb"))
print("  Wrote Status Bar Layout (user|host|venv|git|cwd ... composer) and enabled it.")
PY

# -- B3: Snippets seeded from aliases + history ------------------------------
# Loads config/iterm2/snippets.json into the NoSyncSnippets array. dotfiles-
# owned snippets are identified by guid prefix 'dotfiles-snippet-'; existing
# user snippets are preserved.
python3 - "$(cd "$(dirname "$0")/../.." && pwd)/config/iterm2/snippets.json" <<'PY'
import json, plistlib, sys
from pathlib import Path

snippets_path = Path(sys.argv[1])
if not snippets_path.exists():
    print(f"  No snippets file at {snippets_path}, skipping.")
    raise SystemExit(0)

p = Path.home() / "Library/Preferences/com.googlecode.iterm2.plist"
data = plistlib.loads(p.read_bytes())
existing = data.get("NoSyncSnippets", [])
kept = [s for s in existing if not (s.get("guid") or "").startswith("dotfiles-snippet-")]
dotfiles = json.loads(snippets_path.read_text())
data["NoSyncSnippets"] = kept + dotfiles
plistlib.dump(data, p.open("wb"))
print(f"  Installed {len(dotfiles)} dotfiles snippets ({len(kept)} user snippets preserved).")
PY

# -- B4: Triggers (three high-signal defaults) -------------------------------
# Triggers run regex on terminal output and react. All three are conservative
# and easy to disable in Settings > Profiles > Advanced > Edit Triggers.
python3 <<'PY'
import plistlib
from pathlib import Path

ORIGINAL_DEFAULT_GUID = "74FD8F10-9C21-4853-AF71-8801DCF39FD7"
p = Path.home() / "Library/Preferences/com.googlecode.iterm2.plist"
data = plistlib.loads(p.read_bytes())
default = next(b for b in data["New Bookmarks"] if b.get("Guid") == ORIGINAL_DEFAULT_GUID)

# Highlight enum: 2 = kWhiteOnRedHighlight (from iTerm HighlightTrigger.m).
WHITE_ON_RED = 2

dotfiles_triggers = [
    {
        # Errors/failures highlighted in white on red anywhere on screen.
        "name": "dotfiles: error/fail highlight",
        "regex": r"(?i)\b(error|fail(ed|ure)?|FATAL|panic|traceback)\b",
        "action": "HighlightTrigger",
        "parameter": WHITE_ON_RED,
        "partial": True,
    },
    {
        # Long-running build done? Ring the bell to alert the user.
        "name": "dotfiles: build done bell",
        "regex": r"\bBUILD (SUCCESS|SUCCEEDED|PASSED|FAILED)\b",
        "action": "BellTrigger",
        "parameter": "",
        "partial": False,
    },
    {
        # Heads-up when connecting to a prod-like host. BounceTrigger pulses
        # the dock icon (subtle); swap for AlertTrigger if you want a modal.
        "name": "dotfiles: prod host bounce",
        "regex": r"@(prod|production|live)[A-Za-z0-9._-]*",
        "action": "BounceTrigger",
        "parameter": "",
        "partial": True,
    },
]

existing = default.get("Triggers", []) or []
# Idempotent: strip prior dotfiles-* triggers before re-adding.
kept = [t for t in existing if not (t.get("name", "") or "").startswith("dotfiles:")]
default["Triggers"] = kept + dotfiles_triggers

plistlib.dump(data, p.open("wb"))
print(f"  Installed {len(dotfiles_triggers)} dotfiles triggers ({len(kept)} user triggers preserved).")
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
