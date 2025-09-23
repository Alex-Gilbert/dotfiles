# Complete macOS Setup Instructions

This guide provides step-by-step instructions for setting up a new Mac with an i3-like tiling window manager environment using AeroSpace, skhd, and your dotfiles.

## 📋 Prerequisites

- Fresh macOS installation (or existing Mac you want to configure)
- Internet connection
- Apple ID signed in (for App Store if needed)
- Admin privileges on the Mac

## 🚀 Complete Setup Process

### Step 1: Initial System Setup

Install the essential development tools and package manager:

```bash
# Install Xcode Command Line Tools (required for git and development)
xcode-select --install
# Click "Install" in the popup and wait for completion (this may take 10-20 minutes)

# Install Homebrew (package manager)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH
# For Apple Silicon Macs (M1/M2/M3):
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs:
# echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
# eval "$(/usr/local/bin/brew shellenv)"

# Verify Homebrew installation
brew --version
```

### Step 2: Clone Your Dotfiles

```bash
# Install git if not already available
brew install git

# Configure git (temporary, will be replaced by dotfiles config)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Clone your dotfiles repository
cd ~
git clone https://github.com/YOUR_USERNAME/dotfiles.git

# OR if you have SSH already set up:
# git clone git@github.com:YOUR_USERNAME/dotfiles.git
```

### Step 3: Run Base macOS Development Setup

This installs core development tools and configures the shell:

```bash
# Run the base macOS setup script
cd ~/dotfiles
./scripts/setup-macos.sh
```

This script will:
- Install fish shell and set it as default
- Install essential CLI tools (neovim, tmux, fzf, ripgrep, fd, bat, eza, etc.)
- Install GNU tools for Linux compatibility
- Configure basic macOS settings
- Set up your dotfiles with GNU stow
- Install development environments (Python, Node.js, Rust)

**Note**: You may need to restart your terminal after fish is set as the default shell.

### Step 4: Set Up i3-like Window Management

Now configure the tiling window manager and hotkeys:

```bash
# Run the i3-like setup with terminal selection
cd ~/dotfiles/macos
./setup-i3-like.sh
```

During this script, you'll be prompted for:

1. **Terminal Emulator Choice**:
   - Option 1: **Kitty** - Classic, feature-rich terminal
   - Option 2: **Ghostty** - New, fast terminal with native Metal rendering
   
2. **Launcher Choice**:
   - Option 1: **Sol** - Fast, minimal launcher (recommended)
   - Option 2: **Raycast** - Feature-rich free alternative
   - Option 3: Skip (use Spotlight)

3. **Optional Applications**:
   - Thunderbird (email client)
   - Discord (communication)
   - Spotify (music)
   - Visual Studio Code (editor)

4. **Display Settings**:
   - Disable "Displays have separate Spaces" (recommended for stability)

### Step 5: Grant Required Permissions

**⚠️ CRITICAL STEP - Your hotkeys won't work without this!**

After the setup script completes:

1. Navigate to **System Settings** → **Privacy & Security** → **Accessibility**

2. Click the lock icon and authenticate

3. Enable these applications by checking the boxes:
   - ✅ **AeroSpace** (window manager)
   - ✅ **skhd** (hotkey daemon)
   - ✅ **Kitty** or **Ghostty** (your chosen terminal)
   - ✅ **Sol** or **Raycast** (your chosen launcher)

4. If any app is missing from the list:
   - Click the `+` button
   - Navigate to `/Applications/`
   - Add the missing app

5. Some apps may prompt for permissions when first launched - always allow

### Step 6: Configure Git and SSH

Set up your development credentials:

```bash
# Set up git identity (if not already done)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Generate SSH key for GitHub/GitLab
ssh-keygen -t ed25519 -C "your.email@example.com"
# Press Enter for default location (~/.ssh/id_ed25519)
# Add a passphrase for security (optional but recommended)

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy SSH public key to clipboard
cat ~/.ssh/id_ed25519.pub | pbcopy
echo "✅ SSH public key copied to clipboard!"
```

Add the SSH key to GitHub:
1. Go to [github.com/settings/keys](https://github.com/settings/keys)
2. Click "New SSH key"
3. Give it a name (e.g., "MacBook Pro 2024")
4. Paste the key and click "Add SSH key"

### Step 7: Disable Conflicting macOS Shortcuts

Some default macOS keyboard shortcuts conflict with our setup:

1. **System Settings** → **Keyboard** → **Keyboard Shortcuts**

2. Disable or modify these:
   - **Mission Control**: Uncheck all or change from F3
   - **Spotlight**: Change from Cmd+Space if using Sol/Raycast
   - **Input Sources**: Disable Option+Space shortcuts

3. **System Settings** → **Desktop & Dock**:
   - [ ] Displays have separate Spaces (uncheck for better stability)
   - [x] Automatically hide and show the Dock (check)
   - Set "Position on screen" to Bottom

### Step 8: Restart Services and Log Out

```bash
# Restart the hotkey service
brew services restart skhd

# Reload AeroSpace config
# Either use the keyboard shortcut: Alt+Shift+; then ESC
# Or from terminal:
aerospace reload-config

# Verify services are running
brew services list
```

**Important**: Log out and log back in for all changes to take full effect.

## ✅ Verification Checklist

After logging back in, test these key bindings:

### Window Management
| Action | Keybinding | Description |
|--------|------------|-------------|
| Close window | `Alt+Q` | Close focused window |
| Fullscreen | `Alt+F` | Toggle fullscreen mode |
| Float toggle | `Alt+Ctrl+F` | Toggle floating/tiling |
| Focus | `Alt+H/J/K/L` | Focus left/down/up/right |
| Move | `Alt+Ctrl+H/J/K/L` | Move window in direction |
| Split | `Alt+Cmd+H/V` | Split horizontal/vertical |

### Workspace Navigation
| Action | Keybinding | Description |
|--------|------------|-------------|
| Switch workspace | `Alt+1-9,0` | Go to workspace 1-10 |
| Move to workspace | `Alt+Ctrl+1-9,0` | Move window to workspace |
| Previous workspace | `Alt+`` ` | Toggle previous workspace |
| Art workspace | `Alt+Ctrl+A` | Go to art workspace |

### Application Launchers
| Action | Keybinding | Description |
|--------|------------|-------------|
| Terminal | `Alt+T` | Open terminal |
| Browser | `Alt+B` | Open Thorium browser |
| File manager | `Alt+E` | Open Yazi in terminal |
| App launcher | `Alt+A` | Open Sol/Raycast |
| Window switcher | `Alt+Tab` | Switch windows |

### System Controls
| Action | Keybinding | Description |
|--------|------------|-------------|
| Volume up/down | `Alt+=/Backspace` | Adjust volume |
| Mute | `Alt+M` | Toggle mute |
| Brightness | `Alt+[/]` | Adjust brightness |
| Screenshot | `Alt+C` | Full screen to clipboard |
| Selection shot | `Alt+Shift+C` | Select area to clipboard |
| Lock screen | `Alt+Shift+L` | Lock the screen |

### Modes
| Action | Keybinding | Description |
|--------|------------|-------------|
| Resize mode | `Alt+R` | Enter resize mode |
| Move mode | `Alt+Shift+M` | Enter move mode |
| Service mode | `Alt+Shift+;` | Enter service mode |

## 🔧 Troubleshooting

### Hotkeys Not Working

```bash
# Check if skhd is running
brew services list | grep skhd

# Restart skhd
brew services restart skhd

# Check skhd logs for errors
tail -f /opt/homebrew/var/log/skhd/*

# Verify Accessibility permissions
# System Settings → Privacy & Security → Accessibility
# Ensure skhd is checked
```

### AeroSpace Issues

```bash
# Reload config with keyboard
Alt+Shift+; then press ESC

# Reload from terminal
aerospace reload-config

# Check if AeroSpace is running
ps aux | grep -i aerospace

# View AeroSpace logs
aerospace debug-windows
```

### Terminal Not Opening

1. Verify terminal is installed:
   - Kitty: `/Applications/Kitty.app`
   - Ghostty: `/Applications/Ghostty.app`

2. Check Accessibility permissions for the terminal

3. Try opening manually first to accept any security prompts

### Switch Between Terminals

If you want to change your terminal choice later:

```bash
cd ~/dotfiles/macos
./switch-terminal.sh
```

## 📁 Configuration Files

Your configuration files are located at:

- `~/.aerospace.toml` - AeroSpace window manager config
- `~/.config/skhd/skhdrc` - Hotkey daemon bindings
- `~/.config/kitty/` - Kitty terminal config and theme
- `~/.config/ghostty/config` - Ghostty terminal config
- `~/.config/fish/` - Fish shell configuration
- `~/.config/nvim/` - Neovim configuration

## 🎯 Optional Next Steps

1. **Install Additional Development Tools**:
   ```bash
   brew install docker lazydocker k9s kubectl
   brew install --cask docker
   ```

2. **Configure Workspace Assignments**:
   Edit `~/.aerospace.toml` to assign apps to specific workspaces

3. **Set Up Cloud CLI Tools**:
   ```bash
   brew install awscli azure-cli gcloud
   ```

4. **Install Additional Apps**:
   ```bash
   brew install --cask obsidian notion slack zoom
   ```

5. **Configure Backup Solution**:
   - Set up Time Machine
   - Configure cloud backup for dotfiles

## 📚 Resources

- [AeroSpace Documentation](https://nikitabobko.github.io/AeroSpace/guide)
- [skhd Documentation](https://github.com/koekeishiya/skhd)
- [Kitty Documentation](https://sw.kovidgoyal.net/kitty/)
- [Ghostty Documentation](https://ghostty.org/docs)
- [Fish Shell Documentation](https://fishshell.com/docs/current/)

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review the AeroSpace/skhd logs
3. Verify all Accessibility permissions are granted
4. Try logging out and back in
5. Create an issue in your dotfiles repository with:
   - The error message
   - Output of `brew services list`
   - macOS version (`sw_vers`)

---

**Remember**: The most common issue is missing Accessibility permissions. Always check System Settings → Privacy & Security → Accessibility first when debugging keyboard shortcuts!

## Quick Terminal Command Reference

```bash
# Restart all services
brew services restart skhd
aerospace reload-config

# Check status
brew services list
ps aux | grep -E "(aerospace|skhd)"

# View logs
tail -f /opt/homebrew/var/log/skhd/*
aerospace debug-windows

# Switch terminals
~/dotfiles/macos/switch-terminal.sh
```

Enjoy your new i3-like macOS environment! 🎉