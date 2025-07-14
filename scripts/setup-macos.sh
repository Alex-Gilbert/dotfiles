#!/bin/bash

# macOS Setup Script
# This script sets up a fresh macOS installation with all necessary tools

set -e  # Exit on error

echo "🍎 macOS Setup Script"
echo "===================="

# Check if running on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Error: This script is for macOS only!"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    echo "📦 Checking Xcode Command Line Tools..."
    if ! xcode-select -p >/dev/null 2>&1; then
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "Press any key when Xcode Command Line Tools installation is complete..."
        read -n 1
    else
        echo "✓ Xcode Command Line Tools already installed"
    fi
}

# Install Homebrew
install_homebrew() {
    echo "🍺 Checking Homebrew..."
    if ! command_exists brew; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        echo "✓ Homebrew already installed"
    fi
    
    echo "Updating Homebrew..."
    brew update
}

# Install essential packages
install_packages() {
    echo "📦 Installing essential packages..."
    
    # Core tools
    local packages=(
        git
        stow
        zsh
        neovim
        tmux
        fzf
        ripgrep
        fd
        bat
        eza
        zoxide
        lazygit
        gh
        jq
        wget
        curl
        gpg
        
        # GNU tools for compatibility with Linux scripts
        coreutils
        gnu-sed
        gnu-tar
        grep
        findutils
        gawk
    )
    
    for package in "${packages[@]}"; do
        if brew list "$package" >/dev/null 2>&1; then
            echo "✓ $package already installed"
        else
            echo "Installing $package..."
            brew install "$package"
        fi
    done
    
    echo "📦 Installing additional tools via cask..."
    local casks=(
        kitty           # Terminal emulator
        google-chrome
        visual-studio-code
    )
    
    for cask in "${casks[@]}"; do
        if brew list --cask "$cask" >/dev/null 2>&1; then
            echo "✓ $cask already installed"
        else
            echo "Installing $cask..."
            brew install --cask "$cask"
        fi
    done
}

# Setup shell
setup_shell() {
    echo "🐚 Setting up shell..."
    
    # Add Homebrew zsh to allowed shells if not already there
    if ! grep -q "/opt/homebrew/bin/zsh" /etc/shells; then
        echo "Adding Homebrew zsh to allowed shells..."
        echo "/opt/homebrew/bin/zsh" | sudo tee -a /etc/shells
    fi
    
    # Set zsh as default shell
    if [[ "$SHELL" != "/opt/homebrew/bin/zsh" ]] && [[ -f "/opt/homebrew/bin/zsh" ]]; then
        echo "Setting zsh as default shell..."
        chsh -s /opt/homebrew/bin/zsh
    elif [[ "$SHELL" != "/usr/local/bin/zsh" ]] && [[ -f "/usr/local/bin/zsh" ]]; then
        chsh -s /usr/local/bin/zsh
    fi
}

# Configure macOS defaults
configure_macos() {
    echo "⚙️  Configuring macOS defaults..."
    
    # Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true
    
    # Show file extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    
    # Enable tap to click
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    
    # Save screenshots to a specific folder
    mkdir -p "$HOME/Screenshots"
    defaults write com.apple.screencapture location -string "$HOME/Screenshots"
    
    # Restart affected services
    killall Finder
    
    echo "✓ macOS defaults configured"
}

# Setup development environment
setup_dev_environment() {
    echo "💻 Setting up development environment..."
    
    # Python
    if ! command_exists python3; then
        brew install python@3.12
    fi
    
    # Node.js
    if ! command_exists node; then
        brew install node
    fi
    
    # Rust
    if ! command_exists rustc; then
        echo "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
}

# Clone and setup dotfiles
setup_dotfiles() {
    echo "📁 Setting up dotfiles..."
    
    DOTFILES_DIR="$HOME/dotfiles"
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "Cloning dotfiles repository..."
        echo "Please enter your dotfiles repository URL:"
        read -r repo_url
        git clone "$repo_url" "$DOTFILES_DIR"
    fi
    
    cd "$DOTFILES_DIR"
    
    # Run stow setup
    if [[ -f "./scripts/stow_dotfiles.sh" ]]; then
        echo "Running stow_dotfiles.sh..."
        ./scripts/stow_dotfiles.sh
    else
        echo "Warning: stow_dotfiles.sh not found!"
    fi
}

# Main installation flow
main() {
    echo "This script will set up your macOS development environment."
    echo "Press any key to continue or Ctrl+C to cancel..."
    read -n 1
    
    install_xcode_tools
    install_homebrew
    install_packages
    setup_shell
    configure_macos
    setup_dev_environment
    setup_dotfiles
    
    echo ""
    echo "✅ macOS setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Configure git: git config --global user.name 'Your Name'"
    echo "3. Configure git: git config --global user.email 'your@email.com'"
    echo "4. Set up SSH keys for GitHub"
    echo "5. Run 'p10k configure' to set up your prompt"
}

# Run main function
main