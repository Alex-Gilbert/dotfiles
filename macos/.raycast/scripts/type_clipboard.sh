#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Type Clipboard
# @raycast.mode silent
# @raycast.icon ⌨️
# @raycast.description Types the clipboard character by character, like a human. For screen recordings.

sleep 0.3  # let Raycast close and focus return to the target window
osascript <<'AS'
set t to (do shell script "pbpaste")
tell application "System Events"
  repeat with c in characters of t
    keystroke c
    delay 0.03 + (random number from 0 to 0.05)
  end repeat
end tell
AS
