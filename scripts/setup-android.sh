#!/data/data/com.termux/files/usr/bin/bash
# Termux/Android setup. Run inside Termux on the tablet:
#   bash ~/dotfiles/scripts/setup-android.sh

set -euo pipefail

echo "🤖 Termux Android Setup"
echo "======================="

# Verify we're in Termux (uname says "Linux" here too).
if [ -z "${TERMUX_VERSION:-}" ] && [ "${PREFIX:-}" != "/data/data/com.termux/files/usr" ]; then
    echo "Error: this script must run inside Termux." >&2
    exit 1
fi

echo "📦 Updating Termux package list..."
pkg update -y
pkg upgrade -y

echo "📦 Installing core packages..."
pkg install -y \
    git stow \
    fish neovim tmux \
    openssh openssh-sftp-server mosh \
    fzf zoxide ripgrep fd bat eza \
    lazygit yazi \
    rsync wget curl jq tree \
    starship git-delta \
    gnupg \
    nodejs python rust golang \
    termux-api termux-tools \
    man

# Optional but high-value: tailscale CLI inside Termux. The Android app
# handles the actual VPN; this just gives you `tailscale ssh` etc.
if pkg search tailscale 2>/dev/null | grep -q '^tailscale/'; then
    pkg install -y tailscale || true
fi

# One-time SAF storage prompt so ~/storage links work.
if [ ! -d "$HOME/storage" ]; then
    echo "📂 Granting Termux access to shared storage..."
    termux-setup-storage || true
fi

# Default shell -> fish.
if [ "$(basename "${SHELL:-}")" != "fish" ]; then
    echo "🐚 Setting fish as default shell..."
    chsh -s fish
fi

# Clone dotfiles if missing, then stow.
DOTFILES_DIR="$HOME/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "📁 Cloning dotfiles..."
    read -rp "Dotfiles repository URL: " REPO_URL
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"
./scripts/stow_dotfiles.sh

# Make widget scripts executable (stow preserves perms, but be defensive
# in case the repo was checked out via a path that strips +x).
if [ -d "$HOME/.shortcuts" ]; then
    find "$HOME/.shortcuts" -type f -exec chmod +x {} +
fi

# Pull latest Termux:Settings into the running app.
termux-reload-settings || true

cat <<'EOF'

✅ Termux setup complete.

Next steps:
  1. Install the Tailscale Android app from Play Store and log in. The app
     handles the VPN at the OS level; Termux inherits the routes for free.
  2. Drop a Nerd Font into ~/.termux/font.ttf (see font.ttf.README) and run
     `termux-reload-settings`.
  3. Edit ~/.ssh/config to add your hosts (use Tailscale MagicDNS names so
     they work on every network). Set ControlMaster + ControlPersist for
     instant reconnects.
  4. Long-press your home screen, add a Termux:Widget, and pin the
     ~/.shortcuts/mosh-* launchers for one-tap reattach to remote tmux.
  5. Flash a Glove80 Android layer with K_APP_SWITCH / K_HOMEPAGE / K_BACK
     so DeX is fully keyboard-driven.

EOF
