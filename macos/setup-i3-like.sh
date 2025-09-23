#!/bin/bash

# macOS i3-like Setup Script
# Sets up AeroSpace, skhd, and Sol for an i3-like experience

set -e

echo "🚀 Setting up i3-like environment for macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install from https://brew.sh"
    exit 1
fi

echo "📦 Installing core components..."

# Install window manager and hotkey daemon
brew install --cask nikitabobko/tap/aerospace || true
brew install koekeishiya/formulae/skhd || true

# Choose terminal emulator
echo ""
echo "🖥️  Choose your terminal emulator:"
echo "1) Kitty (classic, feature-rich)"
echo "2) Ghostty (new, fast, native Metal rendering)"
read -p "Enter choice [1-2]: " terminal_choice

# Set terminal variables based on choice
case $terminal_choice in
    1)
        TERMINAL_NAME="Kitty"
        TERMINAL_PATH="/Applications/Kitty.app"
        TERMINAL_APP_ID="net.kovidgoyal.kitty"
        TERMINAL_YAZI_ARGS="--args -e yazi"
        TERMINAL_FLOAT_ARGS="--args --class floating-terminal"
        TERMINAL_BTOP_ARGS="--args -e btop"
        TERMINAL_POWER_ARGS="--args -e sudo powermetrics --samplers smc"
        
        echo "📦 Installing Kitty..."
        brew install --cask kitty || true
        
        # Setup Kitty with Kanagawa theme
        echo "🎨 Setting up Kitty with Kanagawa theme..."
        mkdir -p ~/.config/kitty
        
        # Create Kanagawa theme file if template exists
        if [ -f "$(dirname "$0")/.config/kitty/kanagawa.conf" ]; then
            cp "$(dirname "$0")/.config/kitty/kanagawa.conf" ~/.config/kitty/kanagawa.conf
            
            # Add theme include to kitty.conf if not already present
            if ! grep -q "include kanagawa.conf" ~/.config/kitty/kitty.conf 2>/dev/null; then
                echo "" >> ~/.config/kitty/kitty.conf
                echo "# Kanagawa theme" >> ~/.config/kitty/kitty.conf
                echo "include kanagawa.conf" >> ~/.config/kitty/kitty.conf
            fi
            echo "✅ Kanagawa theme configured for Kitty"
        fi
        ;;
    2)
        TERMINAL_NAME="Ghostty"
        TERMINAL_PATH="/Applications/Ghostty.app"
        TERMINAL_APP_ID="com.mitchellh.ghostty"
        # Ghostty uses different command syntax
        TERMINAL_YAZI_ARGS="--args -e yazi"
        TERMINAL_FLOAT_ARGS="--args --class=floating-terminal"
        TERMINAL_BTOP_ARGS="--args -e btop"
        TERMINAL_POWER_ARGS="--args -e 'sudo powermetrics --samplers smc'"
        
        echo "📦 Installing Ghostty..."
        echo "⚠️  Ghostty must be manually downloaded from https://ghostty.org"
        echo "   Please download and install Ghostty.app to /Applications/"
        read -p "Press Enter after installing Ghostty..."
        
        # Verify Ghostty installation
        if [ ! -d "/Applications/Ghostty.app" ]; then
            echo "❌ Ghostty.app not found in /Applications/"
            echo "   Please install Ghostty and run this script again."
            exit 1
        fi
        
        # Setup Ghostty with Kanagawa theme
        echo "🎨 Setting up Ghostty with Kanagawa theme..."
        mkdir -p ~/.config/ghostty
        
        if [ -f "$(dirname "$0")/.config/ghostty/config" ]; then
            cp "$(dirname "$0")/.config/ghostty/config" ~/.config/ghostty/config
            echo "✅ Kanagawa theme configured for Ghostty"
        fi
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "✅ Selected terminal: $TERMINAL_NAME"

# Install browser
brew install --cask thorium || true

# Install launcher (Sol or alternatives)
echo ""
echo "📱 Choose your launcher:"
echo "1) Sol (recommended)"
echo "2) Raycast (free alternative)"
echo "3) Skip launcher installation"
read -p "Enter choice [1-3]: " launcher_choice

case $launcher_choice in
    1)
        brew install --cask sol || true
        ;;
    2)
        brew install --cask raycast || true
        ;;
    *)
        echo "Skipping launcher installation"
        ;;
esac

# Install optional utilities
echo "📦 Installing optional utilities..."
brew install brightness || true
brew install jq || true
brew install coreutils || true

# Install optional applications
echo "📦 Installing optional applications (you can skip any)..."
read -p "Install Thunderbird? (y/n): " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && brew install --cask thunderbird || true

read -p "Install Discord? (y/n): " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && brew install --cask discord || true

read -p "Install Spotify? (y/n): " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && brew install --cask spotify || true

read -p "Install Visual Studio Code? (y/n): " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && brew install --cask visual-studio-code || true

# Create config directories
echo "📁 Creating config directories..."
mkdir -p ~/.config/skhd
mkdir -p ~/.config/aerospace

# Copy and configure templates with selected terminal
echo "📝 Installing configurations..."

# Process AeroSpace config
if [ -f "$(dirname "$0")/.aerospace.toml.template" ]; then
    sed -e "s|__TERMINAL_NAME__|$TERMINAL_NAME|g" \
        -e "s|__TERMINAL_APP_ID__|$TERMINAL_APP_ID|g" \
        "$(dirname "$0")/.aerospace.toml.template" > ~/.aerospace.toml
    echo "✅ Configured AeroSpace for $TERMINAL_NAME"
elif [ -f "$(dirname "$0")/.aerospace.toml" ]; then
    # Fallback to non-template version if it exists
    cp "$(dirname "$0")/.aerospace.toml" ~/.aerospace.toml
    echo "✅ Copied AeroSpace config"
fi

# Process skhd config
if [ -f "$(dirname "$0")/.config/skhd/skhdrc.template" ]; then
    sed -e "s|__TERMINAL_NAME__|$TERMINAL_NAME|g" \
        -e "s|__TERMINAL_PATH__|$TERMINAL_PATH|g" \
        -e "s|__TERMINAL_YAZI_ARGS__|$TERMINAL_YAZI_ARGS|g" \
        -e "s|__TERMINAL_FLOAT_ARGS__|$TERMINAL_FLOAT_ARGS|g" \
        -e "s|__TERMINAL_BTOP_ARGS__|$TERMINAL_BTOP_ARGS|g" \
        -e "s|__TERMINAL_POWER_ARGS__|$TERMINAL_POWER_ARGS|g" \
        "$(dirname "$0")/.config/skhd/skhdrc.template" > ~/.config/skhd/skhdrc
    echo "✅ Configured skhd for $TERMINAL_NAME"
elif [ -f "$(dirname "$0")/.config/skhd/skhdrc" ]; then
    # Fallback to non-template version if it exists
    cp "$(dirname "$0")/.config/skhd/skhdrc" ~/.config/skhd/skhdrc
    echo "✅ Copied skhd config"
fi

# Configure macOS settings
echo "⚙️  Configuring macOS settings..."

# Disable some default macOS shortcuts that conflict
echo "   Disabling conflicting macOS keyboard shortcuts..."
# Disable Mission Control shortcuts
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 32 "<dict><key>enabled</key><false/></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 34 "<dict><key>enabled</key><false/></dict>"
# Disable Spotlight shortcut (cmd+space)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "<dict><key>enabled</key><false/></dict>"

# Enable key repeat
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Dock settings
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock orientation -string "bottom"

# Optional: Disable displays have separate spaces (recommended for stability)
read -p "Disable 'Displays have separate Spaces'? (recommended for stability) (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    defaults write com.apple.spaces spans-displays -bool true
    echo "⚠️  Note: Logout required for this setting to take effect"
fi

# Start services
echo "🚀 Starting services..."
brew services start skhd

# Launch AeroSpace
echo "🚀 Launching AeroSpace..."
open -a AeroSpace

# Grant permissions
echo ""
echo "⚠️  IMPORTANT: Grant Accessibility Permissions!"
echo "   macOS will prompt you to grant accessibility permissions to:"
echo "   1. AeroSpace"
echo "   2. skhd"
echo "   3. $TERMINAL_NAME"
echo "   4. Sol (or your chosen launcher)"
echo ""
echo "   Go to: System Settings → Privacy & Security → Accessibility"
echo "   Enable all applications listed above"
echo ""
read -p "Press Enter after granting permissions..."

# Restart skhd after permissions
brew services restart skhd

# Set apps to launch at login
echo "🔄 Setting apps to launch at login..."
osascript -e 'tell application "System Events" to make login item at end with properties {name:"AeroSpace", path:"/Applications/AeroSpace.app", hidden:false}' 2>/dev/null || true

if [ "$launcher_choice" = "1" ]; then
    osascript -e 'tell application "System Events" to make login item at end with properties {name:"Sol", path:"/Applications/Sol.app", hidden:false}' 2>/dev/null || true
fi

echo ""
echo "✅ Setup complete with $TERMINAL_NAME!"
echo ""
echo "📚 Quick Reference:"
echo "   Alt+Q         - Close window"
echo "   Alt+F         - Fullscreen"
echo "   Alt+H/J/K/L   - Focus windows"
echo "   Alt+1-9,0     - Switch workspaces"
echo "   Alt+T         - Open terminal ($TERMINAL_NAME)"
echo "   Alt+B         - Open browser (Thorium)"
echo "   Alt+A         - App launcher"
echo "   Alt+Tab       - Window switcher"
echo "   Alt+R         - Resize mode"
echo "   Alt+Shift+M   - Move mode"
echo ""
echo "📝 Config files:"
echo "   ~/.aerospace.toml          - AeroSpace config"
echo "   ~/.config/skhd/skhdrc      - skhd hotkey config"
if [ "$TERMINAL_NAME" = "Kitty" ]; then
    echo "   ~/.config/kitty/           - Kitty config & theme"
else
    echo "   ~/.config/ghostty/config   - Ghostty config & theme"
fi
echo ""
echo "🔧 Troubleshooting:"
echo "   - If hotkeys don't work: Check Accessibility permissions"
echo "   - Restart skhd: brew services restart skhd"
echo "   - Reload AeroSpace: Alt+Shift+; then ESC"
echo ""
echo "⚠️  Logout and login again for all settings to take full effect"