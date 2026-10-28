#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Paneru
# @raycast.mode silent
# @raycast.icon 🐟
# @raycast.packageName Window Manager
# @raycast.description Run a Paneru command on the focused window.
# @raycast.argument1 { "type": "dropdown", "placeholder": "Command", "data": [{"title": "Balance columns", "value": "window balance"}, {"title": "Equalize stack", "value": "window equalize"}, {"title": "Center window", "value": "window center"}, {"title": "Tabbed stack", "value": "window tabbeddisplay"}, {"title": "Snap into view", "value": "window snap"}, {"title": "Move to next display", "value": "window nextdisplay"}, {"title": "Copy window rule", "value": "window copyrule"}, {"title": "Restart Paneru", "value": "restart"}] }

# shellcheck disable=SC2086 # the command is intentionally word-split into args
exec /opt/homebrew/bin/paneru send-cmd $1
