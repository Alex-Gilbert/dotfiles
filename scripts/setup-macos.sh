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
        fish
        neovim
        tmux
        fzf
        ripgrep
        fd
        bat
        eza
        zoxide
        lazygit
        yazi
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
    
    # Determine fish path
    local fish_path=""
    if [[ -f "/opt/homebrew/bin/fish" ]]; then
        fish_path="/opt/homebrew/bin/fish"
    elif [[ -f "/usr/local/bin/fish" ]]; then
        fish_path="/usr/local/bin/fish"
    else
        echo "Error: fish not found in expected locations"
        return 1
    fi
    
    # Add Homebrew fish to allowed shells if not already there
    if ! grep -q "$fish_path" /etc/shells; then
        echo "Adding fish to allowed shells..."
        echo "$fish_path" | sudo tee -a /etc/shells
    fi
    
    # Set fish as default shell
    if [[ "$SHELL" != "$fish_path" ]]; then
        echo "Setting fish as default shell..."
        chsh -s "$fish_path"
        echo "✓ Fish set as default shell. Please restart your terminal."
    else
        echo "✓ Fish is already the default shell"
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

# Install Tmux Plugin Manager
install_tpm() {
    echo "🔌 Setting up Tmux Plugin Manager..."

    TPM_DIR="$HOME/.config/tmux/plugins/tpm"

    if [[ -d "$TPM_DIR" ]]; then
        echo "✓ TPM already installed"
    else
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        echo "✓ TPM installed. Run 'prefix + I' in tmux to install plugins."
    fi
}

# Install Fisher (fish plugin manager)
install_fisher() {
    echo "🐟 Setting up Fisher (fish plugin manager)..."

    # Check if fisher is already installed
    if fish -c "type -q fisher" 2>/dev/null; then
        echo "✓ Fisher already installed"
    else
        echo "Installing Fisher..."
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
        echo "✓ Fisher installed"
    fi

    # Install plugins from fish_plugins if it exists
    if [[ -f "$HOME/.config/fish/fish_plugins" ]]; then
        echo "Installing fish plugins..."
        fish -c "fisher update"
        echo "✓ Fish plugins installed"
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
    install_tpm
    install_fisher
    
    echo ""
    echo "✅ macOS setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal to use fish shell"
    echo "2. Configure git: git config --global user.name 'Your Name'"
    echo "3. Configure git: git config --global user.email 'your@email.com'"
    echo "4. Set up SSH keys for GitHub"
    echo "5. Open tmux and press Alt+Space, I to install tmux plugins"
}

# Run main function
main
