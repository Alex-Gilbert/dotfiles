#!/bin/bash

# Helper script to switch between Kitty and Ghostty after initial setup

set -e

echo "🔄 Terminal Switcher"
echo "==================="

# Check current terminal from skhd config
if grep -q "Kitty" ~/.config/skhd/skhdrc 2>/dev/null; then
    CURRENT_TERMINAL="Kitty"
elif grep -q "Ghostty" ~/.config/skhd/skhdrc 2>/dev/null; then
    CURRENT_TERMINAL="Ghostty"
else
    CURRENT_TERMINAL="Unknown"
fi

echo "Current terminal: $CURRENT_TERMINAL"
echo ""
echo "Switch to:"
echo "1) Kitty"
echo "2) Ghostty"
read -p "Enter choice [1-2]: " terminal_choice

case $terminal_choice in
    1)
        TERMINAL_NAME="Kitty"
        TERMINAL_PATH="/Applications/Kitty.app"
        TERMINAL_APP_ID="net.kovidgoyal.kitty"
        TERMINAL_YAZI_ARGS="--args -e yazi"
        TERMINAL_FLOAT_ARGS="--args --class floating-terminal"
        TERMINAL_BTOP_ARGS="--args -e btop"
        TERMINAL_POWER_ARGS="--args -e sudo powermetrics --samplers smc"
        
        # Check if Kitty is installed
        if [ ! -d "/Applications/Kitty.app" ]; then
            echo "❌ Kitty not found. Installing..."
            brew install --cask kitty || true
        fi
        ;;
    2)
        TERMINAL_NAME="Ghostty"
        TERMINAL_PATH="/Applications/Ghostty.app"
        TERMINAL_APP_ID="com.mitchellh.ghostty"
        TERMINAL_YAZI_ARGS="--args -e yazi"
        TERMINAL_FLOAT_ARGS="--args --class=floating-terminal"
        TERMINAL_BTOP_ARGS="--args -e btop"
        TERMINAL_POWER_ARGS="--args -e 'sudo powermetrics --samplers smc'"
        
        # Check if Ghostty is installed
        if [ ! -d "/Applications/Ghostty.app" ]; then
            echo "❌ Ghostty not found."
            echo "   Please download from https://ghostty.org and install to /Applications/"
            exit 1
        fi
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Update AeroSpace config
if [ -f "$(dirname "$0")/.aerospace.toml.template" ]; then
    sed -e "s|__TERMINAL_NAME__|$TERMINAL_NAME|g" \
        -e "s|__TERMINAL_APP_ID__|$TERMINAL_APP_ID|g" \
        "$(dirname "$0")/.aerospace.toml.template" > ~/.aerospace.toml
    echo "✅ Updated AeroSpace config for $TERMINAL_NAME"
fi

# Update skhd config
if [ -f "$(dirname "$0")/.config/skhd/skhdrc.template" ]; then
    sed -e "s|__TERMINAL_NAME__|$TERMINAL_NAME|g" \
        -e "s|__TERMINAL_PATH__|$TERMINAL_PATH|g" \
        -e "s|__TERMINAL_YAZI_ARGS__|$TERMINAL_YAZI_ARGS|g" \
        -e "s|__TERMINAL_FLOAT_ARGS__|$TERMINAL_FLOAT_ARGS|g" \
        -e "s|__TERMINAL_BTOP_ARGS__|$TERMINAL_BTOP_ARGS|g" \
        -e "s|__TERMINAL_POWER_ARGS__|$TERMINAL_POWER_ARGS|g" \
        "$(dirname "$0")/.config/skhd/skhdrc.template" > ~/.config/skhd/skhdrc
    echo "✅ Updated skhd config for $TERMINAL_NAME"
fi

# Restart services
echo "🔄 Restarting services..."
brew services restart skhd

# Reload AeroSpace config
echo "🔄 Reloading AeroSpace config..."
/opt/homebrew/bin/aerospace reload-config 2>/dev/null || /usr/local/bin/aerospace reload-config 2>/dev/null || echo "   Please reload AeroSpace manually: Alt+Shift+; then ESC"

echo ""
echo "✅ Successfully switched to $TERMINAL_NAME!"
echo ""
echo "⚠️  Remember to grant Accessibility permission to $TERMINAL_NAME if not already done:"
echo "   System Settings → Privacy & Security → Accessibility"