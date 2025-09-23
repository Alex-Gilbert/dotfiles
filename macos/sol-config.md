# Sol Launcher Configuration

Sol is a modern launcher for macOS that can replace rofi functionality from i3.

## Installation

```bash
# Install Sol via Homebrew
brew install --cask sol

# Or download from: https://github.com/ospfranco/sol
```

## Configuration

Sol's configuration is done through its GUI preferences, but here are the key settings to match i3/rofi:

### Hotkeys (set in Sol preferences)

1. **App Launcher** (like rofi -show drun):
   - Already configured in skhd: `Alt + A`
   - Sol should be set to respond to this or use its default hotkey

2. **Window Switcher** (like rofi -show window):
   - Already configured in skhd: `Alt + Tab`
   - Sol should be set to respond to this or use its default hotkey

### Recommended Sol Settings

1. **General**:
   - Launch at login: ✓
   - Hide dock icon: ✓ (optional)

2. **Appearance**:
   - Theme: Dark (matches i3 aesthetic)
   - Position: Center
   - Width: 600-800px

3. **Behavior**:
   - Fuzzy search: ✓
   - Show recent apps: ✓
   - Max results: 10-15

4. **Quick Actions** (optional):
   - Add custom scripts for common tasks
   - Can integrate with AeroSpace via `aerospace` CLI commands

## Alternative: Using Raycast or Alfred

If you prefer, you can use Raycast (free) or Alfred instead of Sol:

### Raycast (free alternative)
```bash
brew install --cask raycast
```
- Set hotkey to `Alt + A` for launcher
- Disable conflicting macOS Spotlight hotkeys

### Alfred (paid alternative)
```bash
brew install --cask alfred
```
- More customizable workflows
- Better integration with macOS services

## Integration with skhd

The skhd config already includes the bindings:
- `alt - a`: Opens Sol launcher (or your preferred launcher)
- `alt - tab`: Opens Sol window switcher

Make sure Sol is running and configured to respond to these triggers.