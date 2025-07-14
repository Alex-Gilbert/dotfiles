#!/bin/bash

# Script to help migrate existing dotfiles to cross-platform structure

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR"

echo "This script will help you organize your dotfiles for cross-platform use."
echo "It will suggest where to move files but won't move anything automatically."
echo

# Files/directories that are typically common across platforms
COMMON_PATTERNS=(
    ".config/nvim"
    ".config/git"
    ".gitconfig"
    ".zshrc"
    ".bashrc"
    ".vimrc"
    ".tmux.conf"
)

# Files/directories that are typically Linux-specific
LINUX_PATTERNS=(
    ".config/i3"
    ".config/waybar"
    ".config/hypr"
    ".config/dunst"
    ".config/rofi"
    ".config/polybar"
    ".config/systemd"
    ".Xresources"
    ".xinitrc"
)

# Files/directories that are typically macOS-specific
MACOS_PATTERNS=(
    ".config/karabiner"
    ".config/yabai"
    ".config/skhd"
    ".config/aerospace"
    "Library"
)

echo "=== SUGGESTED MIGRATIONS ==="
echo

# Function to check if a file/directory exists in current structure
check_and_suggest() {
    local pattern=$1
    local target=$2
    
    if [ -e "$pattern" ] || [ -L "$pattern" ]; then
        echo "  $pattern → $target/$pattern"
    fi
}

echo "COMMON (both Linux and macOS):"
for pattern in "${COMMON_PATTERNS[@]}"; do
    check_and_suggest "$pattern" "common"
done

echo
echo "LINUX-SPECIFIC:"
for pattern in "${LINUX_PATTERNS[@]}"; do
    check_and_suggest "$pattern" "linux"
done

echo
echo "MACOS-SPECIFIC:"
for pattern in "${MACOS_PATTERNS[@]}"; do
    check_and_suggest "$pattern" "macos"
done

echo
echo "=== UNKNOWN FILES ==="
echo "These files weren't categorized - review them manually:"
echo

# Find all top-level dotfiles/directories not in our patterns
find . -maxdepth 1 -name ".*" -not -name ".git" -not -name "." -not -name ".." | while read -r file; do
    file=${file#./}
    found=0
    
    # Check if file matches any pattern
    for pattern in "${COMMON_PATTERNS[@]}" "${LINUX_PATTERNS[@]}" "${MACOS_PATTERNS[@]}"; do
        if [[ "$file" == "$pattern" ]]; then
            found=1
            break
        fi
    done
    
    if [ $found -eq 0 ]; then
        echo "  $file"
    fi
done

echo
echo "=== NEXT STEPS ==="
echo "1. Review the suggestions above"
echo "2. Move files to appropriate directories:"
echo "   git mv <file> common/<file>  # for common files"
echo "   git mv <file> linux/<file>   # for Linux-specific"
echo "   git mv <file> macos/<file>   # for macOS-specific"
echo "3. Run './scripts/stow_dotfiles.sh' to test the new structure"
echo
echo "Note: The stow_dotfiles.sh script will fall back to the old structure"
echo "if 'common' directory doesn't exist, so you can migrate gradually."