#!/usr/bin/env bash
# Apply iTerm2 app-level tmux-integration settings reproducibly.
# Pairs with config/iterm2/DynamicProfiles/tmux.json (the 'tmux' + 'Plain' profiles).
#
# WHY a script: these settings are APP-level prefs, not per-profile, so they
# cannot live in the dynamic-profile JSON. A script keeps them version-controlled
# and reproducible on a new machine instead of being click-only.
#
# IMPORTANT: iTerm rewrites its prefs from memory ON QUIT, clobbering external
# `defaults write` made while it is running. So: quit iTerm, run this, relaunch.
set -euo pipefail

DOMAIN=com.googlecode.iterm2

if pgrep -xq iTerm2 2>/dev/null || pgrep -xq iTerm 2>/dev/null; then
  echo "✋ Quit iTerm first — it flushes prefs on quit and would overwrite these writes." >&2
  echo "   Quit iTerm (⌘Q), re-run this script, then relaunch iTerm." >&2
  exit 1
fi

# 1) Make the repo 'tmux' dynamic profile the DEFAULT profile.
#    This GUID must match "Guid" in DynamicProfiles/tmux.json.
defaults write "$DOMAIN" "Default Bookmark Guid" -string "dotfiles-tmux-cc"

# 2) Automatically bury the tmux client (gateway) session after connecting, so
#    the non-interactive -CC control window is hidden instead of left visible.
defaults write "$DOMAIN" AutoHideTmuxClientSession -bool true

# 3) When attaching, open tmux windows as tabs in the existing window.
#    OpenTmuxWindowsIn enum:  0 = separate native windows
#                             1 = native tabs in a new window
#                             2 = tabs in the existing window
#    Best value for our workflow is 2; if windows open in an unexpected layout,
#    set this in Settings ▸ General ▸ tmux and re-read the value (see below).
defaults write "$DOMAIN" OpenTmuxWindowsIn -int 2

echo "✅ Applied. Relaunch iTerm2 — new windows should open directly into tmux 'main'."
echo
echo "Verify (current values on disk):"
printf '  Default Bookmark Guid     = %s\n' "$(defaults read "$DOMAIN" 'Default Bookmark Guid' 2>/dev/null || echo '?')"
printf '  AutoHideTmuxClientSession = %s\n' "$(defaults read "$DOMAIN" AutoHideTmuxClientSession 2>/dev/null || echo '?')"
printf '  OpenTmuxWindowsIn         = %s\n' "$(defaults read "$DOMAIN" OpenTmuxWindowsIn 2>/dev/null || echo '?')"
