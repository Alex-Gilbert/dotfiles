#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title WM: Toggle Paneru / AeroSpace
# @raycast.mode compact
# @raycast.icon 🪟
# @raycast.packageName Window Manager
# @raycast.description Stop whichever tiler is running and start the other.

PANERU=/opt/homebrew/bin/paneru

if pgrep -qx paneru; then
  "$PANERU" stop
  open -a AeroSpace
  echo "AeroSpace"
else
  osascript -e 'quit app "AeroSpace"' 2>/dev/null
  "$PANERU" start || { "$PANERU" install && "$PANERU" start; }
  echo "Paneru"
fi
