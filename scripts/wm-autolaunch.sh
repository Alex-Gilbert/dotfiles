#!/usr/bin/env bash
# wm-autolaunch.sh — start niri on whichever GPU has a connected monitor.
#
# Desktop reality: cable-as-switch. One DP cable, plugged into either the
# mobo DP port (iGPU, llama-swap gets all the VRAM) or the nvidia card.
# Only the plugged GPU reads "connected", so connector status is the whole
# mode switch — log in on tty1 either way. Without niri: sway on the iGPU,
# startx/i3 on nvidia.
#
# Wire it up from a bare tty login (see SETUP-DESKTOP-DUAL-WM.md):
#   [ "$(tty)" = /dev/tty1 ] && exec ~/dotfiles/scripts/wm-autolaunch.sh
set -euo pipefail

# don't fire inside an existing graphical session
if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
    exit 0
fi

igpu_card=""    # /dev/dri/cardN of a non-nvidia card with a connected monitor
igpu_render=""  # its /dev/dri/renderDN
nvidia_connected=0
nvidia_render=""  # /dev/dri/renderDN of the nvidia card with a connected monitor

for conn in /sys/class/drm/card*-*/status; do
    [ -e "$conn" ] || continue
    [ "$(cat "$conn")" = "connected" ] || continue

    card=$(basename "$(dirname "$conn")")   # e.g. card1-DP-1
    card=${card%%-*}                        # -> card1
    driver=$(basename "$(readlink "/sys/class/drm/$card/device/driver")")

    if [ "$driver" = "nvidia" ]; then
        nvidia_connected=1
        nvidia_render="/dev/dri/$(basename /sys/class/drm/"$card"/device/drm/renderD*)"
    else
        igpu_card="/dev/dri/$card"          # amdgpu / i915 / xe
        igpu_render="/dev/dri/$(basename /sys/class/drm/"$card"/device/drm/renderD*)"
    fi
done

# tty login hands sway/startx no XDG_DATA_DIRS; kitty then sets it to only its
# shell-integration dir, fish never adds the /usr/share default, and Vulkan
# (icd.d), .desktop files and icons all go missing.
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

# niri ignores WLR_DRM_DEVICES; its config includes this file instead. Always
# rewritten: a stale iGPU file would make niri ignore the only card with a display.
write_niri_gpu() {  # write_niri_gpu RENDER_NODE [ignore-nvidia]
    mkdir -p ~/.local/state/niri
    {
        echo "debug {"
        echo "    render-drm-device \"$1\""
        if [ "${2:-}" = ignore-nvidia ]; then
            for render in /sys/class/drm/renderD*; do
                if [ "$(basename "$(readlink "$render/device/driver")")" = nvidia ]; then
                    echo "    ignore-drm-device \"/dev/dri/$(basename "$render")\""
                fi
            done
        fi
        echo "}"
    } > ~/.local/state/niri/gpu.kdl
}

# niri-session -l: we're already past the login shell. Without -l it re-execs
# fish as a login shell, whose tty1 hook runs this script again, forever.
if [ -n "$igpu_card" ]; then
    if command -v niri-session >/dev/null; then
        # render on the iGPU and never open (or wake) the nvidia card
        write_niri_gpu "$igpu_render" ignore-nvidia
        exec niri-session -l
    fi
    # pin wlroots to the iGPU so it never touches (or wakes) the nvidia card
    export WLR_DRM_DEVICES="$igpu_card"
    exec sway
elif [ "$nvidia_connected" = 1 ]; then
    if command -v niri-session >/dev/null; then
        write_niri_gpu "$nvidia_render"
        exec niri-session -l
    fi
    exec startx
else
    echo "wm-autolaunch: no connected display found, staying in shell" >&2
    exit 0
fi
