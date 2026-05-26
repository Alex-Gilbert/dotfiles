#!/bin/bash
# bspwm-style autotiling for AeroSpace
# Only acts when a NEW window appears (not on plain focus switches).
# Checks the new window's dimensions and sets split direction:
#   wider than tall -> split horizontal (next window opens to the right)
#   taller than wide -> split vertical (next window opens below)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KNOWN_WINDOWS="/tmp/aerospace-known-windows"

WINDOW_ID=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)
[ -z "$WINDOW_ID" ] && exit 0

# Skip if we've already seen this window (just a focus change)
if [ -f "$KNOWN_WINDOWS" ] && grep -qx "$WINDOW_ID" "$KNOWN_WINDOWS"; then
    exit 0
fi

# Refresh known windows list (also cleans up closed windows)
aerospace list-windows --all --format '%{window-id}' 2>/dev/null > "$KNOWN_WINDOWS"

read -r WIDTH HEIGHT < <("$SCRIPT_DIR/get-window-bounds" "$WINDOW_ID" 2>/dev/null)
[ -z "$WIDTH" ] || [ -z "$HEIGHT" ] && exit 0
[ "$WIDTH" -eq 0 ] || [ "$HEIGHT" -eq 0 ] && exit 0

if [ "$WIDTH" -gt "$HEIGHT" ]; then
    aerospace split horizontal 2>/dev/null
else
    aerospace split vertical 2>/dev/null
fi
