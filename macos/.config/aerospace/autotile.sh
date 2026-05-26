#!/bin/bash
# bspwm-style autotile for AeroSpace (set-once variant).
# On focus change, if we haven't yet set this window's split orientation,
# do so from its aspect ratio:
#   wider than tall  -> split horizontal (next window opens right)
#   taller than wide -> split vertical   (next window opens below)
# After a window's first focus, subsequent focus switches don't re-set —
# focus-cycling won't keep creating wrapper containers.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SEEN_FILE="/tmp/aerospace-autotile-seen"
LOG="/tmp/aerospace-autotile.log"
log() { echo "$(date +%H:%M:%S.%N | cut -c1-12) $*" >> "$LOG"; }

WINDOW_ID=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)
[ -z "$WINDOW_ID" ] && exit 0

if [ -f "$SEEN_FILE" ] && grep -qx "$WINDOW_ID" "$SEEN_FILE"; then
    exit 0
fi

# Prune seen IDs that no longer exist, then add the current one
ALL_NOW=$(aerospace list-windows --all --format '%{window-id}' 2>/dev/null)
{
    [ -f "$SEEN_FILE" ] && comm -12 <(sort -u "$SEEN_FILE") <(echo "$ALL_NOW" | sort -u)
    echo "$WINDOW_ID"
} > "$SEEN_FILE.tmp" && mv "$SEEN_FILE.tmp" "$SEEN_FILE"

read -r WIDTH HEIGHT < <("$SCRIPT_DIR/get-window-bounds" "$WINDOW_ID" 2>/dev/null)
[ -z "$WIDTH" ] || [ -z "$HEIGHT" ] && { log "$WINDOW_ID: bad bounds '$WIDTH' '$HEIGHT'"; exit 0; }
[ "$WIDTH" -eq 0 ] || [ "$HEIGHT" -eq 0 ] && { log "$WINDOW_ID: zero bounds"; exit 0; }

if [ "$WIDTH" -gt "$HEIGHT" ]; then
    out=$(aerospace split horizontal 2>&1)
    log "set $WINDOW_ID ${WIDTH}x${HEIGHT} -> split horizontal | $out"
else
    out=$(aerospace split vertical 2>&1)
    log "set $WINDOW_ID ${WIDTH}x${HEIGHT} -> split vertical | $out"
fi
