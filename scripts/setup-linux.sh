#!/bin/bash

# Linux Setup Script
# This script sets up a fresh Linux installation with i3-gaps and all necessary tools

set -e  # Exit on error

echo "🐧 Linux Setup Script"
echo "===================="

# Check if running on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Error: This script is for Linux only!"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect package manager
detect_package_manager() {
    if command_exists pacman; then
        echo "pacman"
    elif command_exists apt; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    else
        echo "unknown"
    fi
}

# Install paru if not present (Arch only)
install_paru() {
    if ! command_exists paru; then
        echo "📦 Installing paru (AUR helper)..."
        sudo pacman -S --needed base-devel git
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/paru
        echo "✓ paru installed"
    else
        echo "✓ paru already installed"
    fi
}

# Install i3-gaps and compositor
install_i3_gaps() {
    echo "🪟 Installing i3-gaps and compositor..."

    local pm=$(detect_package_manager)

    case "$pm" in
        pacman)
            sudo pacman -S --needed \
                i3-gaps \
                picom \
                rofi \
                dunst \
                feh \
                i3blocks \
                i3lock \
                xss-lock \
                flameshot \
                redshift \
                network-manager-applet \
                blueman \
                pasystray
            ;;
        apt)
            sudo add-apt-repository ppa:regolith-linux/release -y
            sudo apt update
            sudo apt install -y i3-gaps picom rofi dunst feh i3blocks i3lock xss-lock flameshot redshift
            ;;
        dnf)
            sudo dnf copr enable fuhrmann/i3-gaps -y
            sudo dnf install -y i3-gaps picom rofi dunst feh i3blocks i3lock xss-lock flameshot redshift
            ;;
        *)
            echo "Error: Unsupported package manager"
            exit 1
            ;;
    esac

    echo "✓ i3-gaps and compositor installed"
}

# Install essential packages
install_packages() {
    echo "📦 Installing essential packages..."

    local pm=$(detect_package_manager)

    # Core tools
    local packages=(
        git
        stow
        fish
        neovim
        fzf
        ripgrep
        fd
        bat
        eza
        zoxide
        lazygit
        jq
        wget
        curl
        gpg
    )

    case "$pm" in
        pacman)
            sudo pacman -S --needed "${packages[@]}"
            ;;
        apt)
            sudo apt install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
    esac

    echo "✓ Essential packages installed"
}

# Install terminal emulator
install_terminal() {
    echo "🖥️  Installing terminal emulator..."

    local pm=$(detect_package_manager)

    case "$pm" in
        pacman)
            sudo pacman -S --needed kitty
            ;;
        apt)
            sudo apt install -y kitty
            ;;
        dnf)
            sudo dnf install -y kitty
            ;;
    esac

    echo "✓ kitty installed"
}

# Setup shell
setup_shell() {
    echo "🐚 Setting up shell..."

    local fish_path=$(which fish)

    if [[ -z "$fish_path" ]]; then
        echo "Error: fish not found"
        return 1
    fi

    # Add fish to allowed shells if not already there
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

# Setup development environment
setup_dev_environment() {
    echo "💻 Setting up development environment..."

    local pm=$(detect_package_manager)

    # Node.js
    if ! command_exists node; then
        case "$pm" in
            pacman)
                sudo pacman -S --needed nodejs npm
                ;;
            apt)
                sudo apt install -y nodejs npm
                ;;
            dnf)
                sudo dnf install -y nodejs npm
                ;;
        esac
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
    echo "This script will set up your Linux development environment with i3-gaps."
    echo "Press any key to continue or Ctrl+C to cancel..."
    read -n 1

    local pm=$(detect_package_manager)

    if [[ "$pm" == "pacman" ]]; then
        install_paru
    fi

    install_i3_gaps
    install_packages
    install_terminal
    setup_shell
    setup_dev_environment
    setup_dotfiles

    echo ""
    echo "✅ Linux setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Log out and select i3 from your display manager"
    echo "2. Restart your terminal to use fish shell"
    echo "3. Configure git: git config --global user.name 'Your Name'"
    echo "4. Configure git: git config --global user.email 'your@email.com'"
    echo "5. Set up SSH keys for GitHub"
    echo "6. Reload i3 config: Alt+r (or i3-msg reload)"
    echo ""
    echo "Customization:"
    echo "  - Edit gaps: ~/.config/i3/config (gaps inner/outer)"
    echo "  - Edit corner radius: ~/.config/picom/picom-minimal.conf (corner-radius)"
}

# Run main function
main
