# i3 to macOS Configuration Deviations

This document outlines the differences between your Linux i3 config and the macOS setup using AeroSpace + skhd + Sol.

## Key Binding Changes

### Modifier Key
- **i3**: Super (Windows/Cmd key) as $mod
- **macOS**: Alt/Option as primary modifier
- **Rationale**: More consistent with macOS conventions, avoids conflicts with system shortcuts

### Split Commands
- **i3**: `$mod+$alt+h/v` for splitting
- **macOS**: `Alt+Cmd+h/v` for splitting
- **Note**: Alt+Cmd combination mirrors the i3 $mod+$alt pattern

## Feature Differences

### Not Available on macOS

1. **Focus Parent/Child** (`$mod+shift+p`, `$mod+ctrl+shift+p`)
   - AeroSpace doesn't support this i3 feature
   - Workaround: Use direct navigation with Alt+H/J/K/L

2. **True Scratchpad**
   - macOS uses workspace "S" as pseudo-scratchpad
   - Alt+Z toggles to/from scratchpad workspace
   - Alt+Shift+Z moves window to scratchpad

3. **Sticky Windows** 
   - Not supported in AeroSpace
   - Picture-in-Picture windows are automatically floated instead

4. **Canvas Mode** (`$mod+w`)
   - Custom script needs macOS adaptation
   - Commented out in skhd config

5. **Gaps Reset** (`$mod+$alt+g`)
   - Modified to use resize commands instead
   - Alt+Shift+G increases, Alt+Ctrl+G decreases

### Modified Features

1. **Application Launches**
   - Handled by skhd instead of i3 exec
   - Uses `open -na` for macOS app bundles

2. **Volume/Brightness**
   - Uses osascript and brightness CLI
   - No pactl/brightnessctl equivalents

3. **Screenshots**
   - Uses macOS `screencapture` instead of `flameshot`
   - Alt+C for full screen, Alt+Shift+C for selection

4. **Lock Screen**
   - Uses CGSession instead of i3lock
   - Different visual appearance

5. **System Info**
   - htop → btop (or htop if installed)
   - nvtop → powermetrics (requires sudo)
   - nmtui → Network.prefPane

## Window Rules

### Workspace Assignments
Successfully migrated:
- Thunderbird → Workspace 9
- Discord/Spotify → Workspace 10
- Krita/Blender/Gimp → Workspace "art"

### Float Rules
- Most dialog detection automatic in AeroSpace
- PiP windows handled correctly
- ripdrag equivalent apps need testing

## Performance Considerations

1. **Workspace Switching**
   - macOS "hides" windows off-screen (1px visible)
   - No animation unlike native Spaces
   - Faster than native macOS Spaces

2. **Multiple Monitors**
   - Requires proper monitor arrangement
   - Bottom corners must be free for window hiding

3. **Focus Behavior**
   - `focus_follows_mouse no` → Handled correctly
   - Mouse follows monitor change implemented

## Launch Integration

### skhd vs i3 bindings
- Window management → AeroSpace
- App launches → skhd
- System controls → skhd
- Avoid duplication to prevent conflicts

### Sol/Raycast vs rofi
- Alt+A → App launcher (like rofi -show drun)
- Alt+Tab → Window switcher (enhanced from basic workspace-back-and-forth)

## Configuration Files

| Linux | macOS |
|-------|-------|
| `~/.config/i3/config` | `~/.aerospace.toml` |
| (i3 handles all) | `~/.config/skhd/skhdrc` |
| rofi config | Sol preferences (GUI) |

## Setup Requirements

1. **Accessibility Permissions** (critical):
   - AeroSpace
   - skhd  
   - Sol/Raycast

2. **Disable Conflicting Shortcuts**:
   - Mission Control
   - Spotlight (Cmd+Space)
   - Option key special characters

3. **Recommended Settings**:
   - Disable "Displays have separate Spaces"
   - Enable key repeat
   - Set Dock to auto-hide

## Testing Checklist

After setup, verify:
- [ ] Alt+1-9,0 switches workspaces
- [ ] Alt+H/J/K/L focuses windows
- [ ] Alt+Ctrl+H/J/K/L moves windows
- [ ] Alt+F toggles fullscreen
- [ ] Alt+Q closes windows
- [ ] Alt+T opens terminal
- [ ] Alt+A opens launcher
- [ ] Alt+R enters resize mode
- [ ] Volume/brightness controls work
- [ ] Screenshots work
- [ ] App workspace assignments work