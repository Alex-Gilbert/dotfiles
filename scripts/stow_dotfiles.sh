#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${DOTFILES_DIR:-"$HOME/dotfiles"}"

# source utils (sets OS_TYPE + portable_readlink)
# shellcheck source=/dev/null
source "$REPO_DIR/scripts/cross-platform-utils.sh"

OS="${OS_TYPE:-$(uname -s | tr '[:upper:]' '[:lower:]')}"
echo "Detected OS: $OS"

create_directories() {
  echo "Creating essential directories..."
  mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.ssh" "$HOME/.aws"
  # ~/.config/zen is Zen's *profile root*, and common/ ships a user.js into it.
  # Without this the dir won't exist on a fresh machine, stow will tree-fold and
  # symlink ~/.config/zen -> the repo, and Zen will write its whole profile
  # (cookies, history, sqlite) into the git tree. Pre-create so stow links the
  # single file instead of adopting the directory.
  mkdir -p "$HOME/.config/zen"
}

decrypt_and_place() {
  local src_file="$1"
  local src_abs; src_abs="$(portable_readlink -f "$src_file")"
  local rel="${src_abs#$DOTFILES_DIR/}"
  local dest="$HOME/${rel%.gpg}"

  echo "Decrypting $rel -> ${dest#$HOME/}"
  mkdir -p "$(dirname "$dest")"
  if gpg --quiet --batch --yes --decrypt --output "$dest" "$src_abs"; then
    chmod 600 "$dest" || true
    echo "Decrypted and placed: ${dest#$HOME/}"
  else
    echo "Failed to decrypt: $rel" >&2
  fi
}
export -f decrypt_and_place

process_package() {
  local pkg="$1"  # "common" or "$OS"
  local pkg_dir="$REPO_DIR/$pkg"

  if [ -d "$pkg_dir" ]; then
    echo "Processing $pkg configs..."
    (
      DOTFILES_DIR="$pkg_dir"
      export DOTFILES_DIR
      find "$DOTFILES_DIR" -type f -name '*.gpg' \
        -exec bash -c 'decrypt_and_place "$1"' _ "{}" \;
    )
    (cd "$REPO_DIR" && stow -v --ignore='\.gpg$' "$pkg")
  fi
}

create_directories

process_package "common"
process_package "$OS"

echo "Dotfiles installation complete!"
