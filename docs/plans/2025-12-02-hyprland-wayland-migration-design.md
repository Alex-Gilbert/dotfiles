# Hyprland Wayland Migration Design

**Date:** 2025-12-02
**Status:** Approved
**Migrating from:** i3 + i3blocks + X11
**Migrating to:** Hyprland + Waybar + Wayland

## Overview

Migration from i3 tiling window manager on X11 to Hyprland on Wayland, preserving the existing keybinding layout and workflow while embracing Wayland-native tooling.

## Requirements

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Compositor | Hyprland | Modern, feature-rich, active development |
| Status Bar | Waybar | Full-featured, Hyprland integration |
| Launcher | Walker | Raycast-like with built-in clipboard history |
| Lock Screen | hyprlock | Hyprland-native, customizable |
| Notifications | mako | Wayland-native, minimal |
| Screenshots | grimblast | Hyprland-native |
| Wallpaper | hyprpaper | Hyprland-native |
| Idle Management | hypridle | Hyprland-native, replaces xss-lock |
| Animations | Minimal/fast | Prioritize responsiveness |
| Theme | Kanagawa | Preserve existing aesthetic |
| Network | systemd-networkd | No NetworkManager dependency |

## File Structure

```
linux/.config/
├── hypr/
│   ├── hyprland.conf          # Main entry point (sources others)
│   ├── keybinds.conf          # All keybindings (hyper-key vim-style)
│   ├── windowrules.conf       # Float rules
│   ├── autostart.conf         # Startup applications
│   ├── appearance.conf        # Gaps, borders, Kanagawa colors
│   └── animations.conf        # Minimal/fast animation settings
├── hyprlock.conf              # Lock screen config
├── hypridle.conf              # Idle timeout -> lock -> suspend
├── hyprpaper.conf             # Wallpaper config
├── waybar/
│   ├── config.jsonc           # Modules configuration
│   └── style.css              # Kanagawa-themed styling
├── mako/
│   └── config                 # Notification styling
└── walker/
    └── config.toml            # Launcher + clipboard config
```

## Keybinding Translation

### Modifier Keys

| i3 Variable | i3 Value | Hyprland Equivalent |
|-------------|----------|---------------------|
| `$hyp` | Mod1+Shift+Control+Mod4 | `SUPER ALT CTRL SHIFT` |
| `$altc` | Mod1+Control | `ALT CTRL` |
| `$alt` | Mod1 | `ALT` |
| `$mod` | Mod4 | `SUPER` |

### Core Keybindings

```ini
# Window management
bind = SUPER ALT CTRL SHIFT, Q, killactive
bind = SUPER ALT CTRL SHIFT, F, fullscreen
bind = SUPER ALT CTRL SHIFT, G, togglefloating

# Vim-style focus (hjkl)
bind = SUPER ALT CTRL SHIFT, H, movefocus, l
bind = SUPER ALT CTRL SHIFT, J, movefocus, d
bind = SUPER ALT CTRL SHIFT, K, movefocus, u
bind = SUPER ALT CTRL SHIFT, L, movefocus, r

# Window movement
bind = ALT CTRL, H, movewindow, l
bind = ALT CTRL, J, movewindow, d
bind = ALT CTRL, K, movewindow, u
bind = ALT CTRL, L, movewindow, r

# Application launchers
bind = SUPER ALT CTRL SHIFT, T, exec, ~/dotfiles/scripts/launch-ftz.sh
bind = SUPER ALT CTRL SHIFT, B, exec, thorium-browser
bind = SUPER ALT CTRL SHIFT, A, exec, walker
bind = SUPER ALT CTRL SHIFT, Tab, exec, walker -m windows
bind = SUPER ALT CTRL SHIFT, E, exec, kitty -e yazi
bind = SUPER ALT CTRL SHIFT, V, exec, walker -m clipboard

# Workspaces 1-10
bind = SUPER ALT CTRL SHIFT, 1, workspace, 1
bind = SUPER ALT CTRL SHIFT, 2, workspace, 2
bind = SUPER ALT CTRL SHIFT, 3, workspace, 3
bind = SUPER ALT CTRL SHIFT, 4, workspace, 4
bind = SUPER ALT CTRL SHIFT, 5, workspace, 5
bind = SUPER ALT CTRL SHIFT, 6, workspace, 6
bind = SUPER ALT CTRL SHIFT, 7, workspace, 7
bind = SUPER ALT CTRL SHIFT, 8, workspace, 8
bind = SUPER ALT CTRL SHIFT, 9, workspace, 9
bind = SUPER ALT CTRL SHIFT, 0, workspace, 10

# Move to workspaces
bind = ALT CTRL, 1, movetoworkspace, 1
bind = ALT CTRL, 2, movetoworkspace, 2
bind = ALT CTRL, 3, movetoworkspace, 3
bind = ALT CTRL, 4, movetoworkspace, 4
bind = ALT CTRL, 5, movetoworkspace, 5
bind = ALT CTRL, 6, movetoworkspace, 6
bind = ALT CTRL, 7, movetoworkspace, 7
bind = ALT CTRL, 8, movetoworkspace, 8
bind = ALT CTRL, 9, movetoworkspace, 9
bind = ALT CTRL, 0, movetoworkspace, 10

# Special
bind = SUPER, grave, workspace, previous
bind = SUPER ALT CTRL SHIFT, S, exec, grimblast --notify copy area
bind = ALT CTRL, X, exec, hyprlock && systemctl suspend

# System
bind = ALT, R, exec, hyprctl reload
```

### Submaps (Modes)

Resize and move modes translate to Hyprland submaps with identical vim-key navigation.

## Waybar Configuration

### Modules Layout

**Left:** `hyprland/workspaces`
**Center:** `clock`
**Right:** `network` | `custom/tailscale` | `cpu` | `memory` | `pulseaudio` | `backlight` | `battery` | `idle_inhibitor` | `tray`

### Network Module (systemd-networkd)

```json
"network": {
    "interface": "enp*",
    "format": "{ifname}: {ipaddr}",
    "format-disconnected": "disconnected",
    "tooltip-format": "{ifname}: {ipaddr}/{cidr}\nGateway: {gwaddr}"
}
```

### Tailscale Module

```json
"custom/tailscale": {
    "exec": "tailscale status --json | jq -r '.Self.HostName // empty'",
    "format": "󰖂 {}",
    "interval": 30,
    "on-click": "tailscale up",
    "on-click-right": "tailscale down"
}
```

### Theme Colors (Kanagawa)

- Background: `#1d2021`
- Text: `#ebdbb2`
- Separator: `#665c54`
- Focused workspace: `#458588`
- Active workspace: `#83a598`
- Inactive workspace: `#1d2021`
- Urgent: `#cc241d`

## Window Rules

```ini
# Floating windows
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, class:^(Lxappearance)$
windowrulev2 = float, class:^(Arandr)$
windowrulev2 = float, title:^(Picture-in-Picture)$
windowrulev2 = float, class:^(feh|Sxiv|mpv)$
windowrulev2 = float, class:^(ripdrag)$
windowrulev2 = float, class:^(floating-terminal)$
windowrulev2 = float, title:.*Preferences$

# Focus behavior
windowrulev2 = focus, class:^(kitty|Thorium|Code)$
```

## Appearance

### Gaps and Borders

```ini
general {
    gaps_in = 5
    gaps_out = 3
    border_size = 4
    col.active_border = rgb(C8C8C8)
    col.inactive_border = rgb(1F1F28)
    layout = dwindle
}
```

### Animations (Minimal)

```ini
animations {
    enabled = true

    bezier = quick, 0.25, 0.1, 0.25, 1

    animation = windows, 1, 2, quick
    animation = windowsOut, 1, 2, quick, popin 80%
    animation = fade, 1, 2, quick
    animation = workspaces, 1, 2, quick, slide
}
```

### Layout

```ini
dwindle {
    pseudotile = false
    preserve_split = true
    force_split = 2
}
```

## Idle and Lock (hypridle)

```ini
listener {
    timeout = 300          # 5 min - lock screen
    on-timeout = hyprlock
}
listener {
    timeout = 600          # 10 min - screen off
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
listener {
    timeout = 900          # 15 min - suspend
    on-timeout = systemctl suspend
}
```

## Autostart Applications

```ini
exec-once = waybar
exec-once = hyprpaper
exec-once = hypridle
exec-once = mako
exec-once = blueman-applet
exec-once = wl-paste --watch cliphist store
exec-once = walker --gapplication-service
```

## Packages Required

### Arch Linux

```bash
# Core
hyprland waybar walker-bin mako hyprlock hypridle hyprpaper grimblast-git

# Clipboard
wl-clipboard cliphist

# Utilities
blueman jq

# Fonts
ttf-jetbrains-mono-nerd
```

## Removed from i3 Setup

| Component | Reason |
|-----------|--------|
| picom | Hyprland has built-in compositor |
| nm-applet | Using systemd-networkd |
| redshift-gtk | Use hyprsunset or gammastep-wayland |
| flameshot | Replaced by grimblast |
| feh | Replaced by hyprpaper |
| xss-lock | Replaced by hypridle |
| i3blocks | Replaced by waybar |
| rofi | Replaced by walker |
| dunst | Replaced by mako |
