#!/bin/bash
# bspwm-style autotiling for AeroSpace
# On focus change, check window dimensions and set split direction:
#   wider than tall -> split horizontal (next window opens to the right)
#   taller than wide -> split vertical (next window opens below)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

WINDOW_ID=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)
[ -z "$WINDOW_ID" ] && exit 0

read -r WIDTH HEIGHT < <("$SCRIPT_DIR/get-window-bounds" "$WINDOW_ID" 2>/dev/null)
[ -z "$WIDTH" ] || [ -z "$HEIGHT" ] && exit 0
[ "$WIDTH" -eq 0 ] || [ "$HEIGHT" -eq 0 ] && exit 0

if [ "$WIDTH" -gt "$HEIGHT" ]; then
    aerospace split horizontal 2>/dev/null
else
    aerospace split vertical 2>/dev/null
fi
