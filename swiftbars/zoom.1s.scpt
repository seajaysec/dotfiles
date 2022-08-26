#!/usr/bin/osascript

# <bitbar.title>Mute/Video/Screen State for Zoom</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>seajaysec</bitbar.author>
# <bitbar.author.github>seajaysec</bitbar.author.github>
# <bitbar.desc>Mute/Video/Screen State for Zoom</bitbar.desc>
# <bitbar.dependencies>Applescript</bitbar.dependencies>

# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>false</swiftbar.hideSwiftBar>

property muteBtnTitle : "Mute audio"
property videoBtnTitle : "Stop Video"
property shareBtnTitle : "Start Share"

if application "zoom.us" is running then
	tell application "System Events"
		tell application process "zoom.us"
			if exists (menu bar item "Meeting" of menu bar 1) then
				
				if exists (menu item MuteBtnTitle of menu 1 of menu bar item "Meeting" of menu bar 1) then
					set muteState to "🟢 🎤"
				else
					set muteState to "🔴 🎤"
				end if
				
				if exists (menu item videoBtnTitle of menu 1 of menu bar item "Meeting" of menu bar 1) then
					set videoState to "🟢 📹"
					set pad1 to "     "
				else
					set videoState to "🔴 📹"
					set pad1 to "     "
				end if
				
				if exists (menu item shareBtnTitle of menu 1 of menu bar item "Meeting" of menu bar 1) then
					set shareState to ""
					set pad2 to ""
				else
					set shareState to "🟢 🖥️"
					set pad2 to "   "
				end if
				
				
			else
				set muteState to ""
				set videoState to ""
				set shareState to ""
				set pad1 to ""
				set pad2 to ""
				
			end if
		end tell
	end tell
else
	set muteState to ""
	set videoState to ""
	set shareState to ""
	set pad1 to ""
	set pad2 to ""
end if

return shareState & pad2 & videoState & pad1 & muteState & "| size=18
---
Mute/Video/Screen State for Zoom"
