#!/bin/sh
# Pick from clipmenu via rofi, then auto-paste into whichever window had focus.
#
# Detects the focused window's class BEFORE rofi steals focus so we can pick
# the right paste keystroke: terminals want Ctrl+Shift+V, everything else
# wants Ctrl+V.

target=$(xdotool getactivewindow)
class=$(xdotool getwindowclassname "$target" 2>/dev/null)

CM_LAUNCHER=rofi clipmenu "$@" || exit 0

case "$class" in
    kitty|Alacritty|URxvt|XTerm|Terminator|st|st-256color|wezterm|foot)
        key="ctrl+shift+v"
        ;;
    *)
        key="ctrl+v"
        ;;
esac

# Wait for focus to actually return to the original window before sending keys.
# xdotool's key sending uses XTestFake (treated as real input) and requires
# focus on the target — --sync blocks until activation completes.
xdotool windowactivate --sync "$target" 2>/dev/null
xdotool key --clearmodifiers "$key"
