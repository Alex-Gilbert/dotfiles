#!/usr/bin/env bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Borders: Keep Alive
# @raycast.mode silent
#
# Optional parameters:
# @raycast.icon 🧱
# @raycast.packageName Borders
# @raycast.refreshTime 15s
# @raycast.author you
# @raycast.description Ensure JankyBorders is running; (re)launch with your preferred options or ~/.config/borders/bordersrc.

# ---- Config ----
# If you maintain ~/.config/borders/bordersrc you can leave OPTIONS empty.
# Otherwise, set your defaults here (picked to look nice with Kanagawa-ish themes).
OPTIONS=("style=round" "width=6.0" "hidpi=off" "active_color=0xffe2e2e3" "inactive_color=0xff414550")

# Path lookup (Homebrew installs borders into PATH; if not, add a fallback)
BORDERS_BIN="$(command -v borders || echo /opt/homebrew/bin/borders)"

# ---- Logic ----
# If a borders instance exists, do nothing. If not, launch it.
if pgrep -qx borders; then
  exit 0
fi

# Prefer config file if present; otherwise use inline OPTIONS.
if [ -f "$HOME/.config/borders/bordersrc" ]; then
  # Start without args so it sources ~/.config/borders/bordersrc
  nohup "$BORDERS_BIN" >/dev/null 2>&1 &
else
  nohup "$BORDERS_BIN" "${OPTIONS[@]}" >/dev/null 2>&1 &
fi

exit 0
