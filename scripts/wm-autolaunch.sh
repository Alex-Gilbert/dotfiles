#!/usr/bin/env bash
# wm-autolaunch.sh — pick WM by which GPU has a connected monitor.
#
# Desktop reality: cable-as-switch. One DP cable, plugged into either the
# mobo DP port (iGPU -> sway, llama-swap gets all the VRAM) or the nvidia
# card (-> startx/i3). Only the plugged GPU reads "connected", so connector
# status is the whole mode switch — log in on tty1 either way.
#
# Wire it up from a bare tty login (see SETUP-DESKTOP-DUAL-WM.md):
#   [ "$(tty)" = /dev/tty1 ] && exec ~/dotfiles/scripts/wm-autolaunch.sh
set -euo pipefail

# don't fire inside an existing graphical session
if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
    exit 0
fi

igpu_card=""    # /dev/dri/cardN of a non-nvidia card with a connected monitor
nvidia_connected=0

for conn in /sys/class/drm/card*-*/status; do
    [ -e "$conn" ] || continue
    [ "$(cat "$conn")" = "connected" ] || continue

    card=$(basename "$(dirname "$conn")")   # e.g. card1-DP-1
    card=${card%%-*}                        # -> card1
    driver=$(basename "$(readlink "/sys/class/drm/$card/device/driver")")

    if [ "$driver" = "nvidia" ]; then
        nvidia_connected=1
    else
        igpu_card="/dev/dri/$card"          # amdgpu / i915 / xe
    fi
done

if [ -n "$igpu_card" ]; then
    # pin wlroots to the iGPU so it never touches (or wakes) the nvidia card
    export WLR_DRM_DEVICES="$igpu_card"
    exec sway
elif [ "$nvidia_connected" = 1 ]; then
    exec startx
else
    echo "wm-autolaunch: no connected display found, staying in shell" >&2
    exit 0
fi
