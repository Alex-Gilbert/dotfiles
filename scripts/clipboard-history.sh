#!/bin/sh
# Cancel leaves the clipboard untouched; decode before replacing its contents.
selection=$(cliphist list | wofi --dmenu -p Clipboard) || exit 0
[ -n "$selection" ] || exit 0
clip=$(mktemp) || exit 1
trap 'rm -f "$clip"' EXIT HUP INT TERM
printf '%s\n' "$selection" | cliphist decode > "$clip" || exit 1
wl-copy < "$clip"
