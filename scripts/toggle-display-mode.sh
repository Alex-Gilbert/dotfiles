#!/bin/bash

# Script to toggle between normal mode (3840x2160@239.99Hz) and recording mode (1920x1080@60Hz)
# for the primary display (DP-0)

# Get current resolution of DP-0
current_res=$(xrandr | grep "DP-0" | awk '{print $4}' | cut -d'+' -f1)

# Function to set recording mode (1080p@60Hz)
set_recording_mode() {
    xrandr --output DP-0 --primary --mode 1920x1080 --rate 60 --pos 0x0 --rotate normal --output HDMI-0 --mode 2560x1440 --pos 1920x0 --rotate left
    notify-send "Display" "Switched to recording mode (1920x1080@60Hz)"
}

# Function to set normal mode (4K@239.99Hz)
set_normal_mode() {
    xrandr --output DP-0 --primary --mode 3840x2160 --rate 239.99 --pos 0x0 --rotate normal --output HDMI-0 --mode 2560x1440 --pos 3840x0 --rotate left
    notify-send "Display" "Switched to normal mode (3840x2160@239.99Hz)"
}

# Check current resolution and toggle
if [[ "$current_res" == "3840x2160" ]]; then
    set_recording_mode
else
    set_normal_mode
fi
