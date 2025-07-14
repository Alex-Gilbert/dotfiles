#!/bin/bash

# Define the path to your dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"
export DOTFILES_DIR

# Source cross-platform utilities
source "$DOTFILES_DIR/scripts/cross-platform-utils.sh"

# OS is set by cross-platform-utils.sh as OS_TYPE
OS="$OS_TYPE"

echo "Detected OS: $OS"

# Create essential directories to prevent stow from symlinking entire directories
create_directories() {
    echo "Creating essential directories..."
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.ssh"
    mkdir -p "$HOME/.aws"
    
    # Add any other directories that should exist before stowing
    # This prevents stow from creating symlinks to entire directories
}

decrypt_and_place() {
    local src_file="$1"

    # Compute the path relative to the DOTFILES_DIR, ensuring it's an absolute path
    local src_file_abs_path=$(portable_readlink -f "$src_file")

    # Remove the DOTFILES_DIR part from the absolute path of the source file
    local relative_path="${src_file_abs_path#$DOTFILES_DIR/}"

    # Construct the absolute destination path by removing the .gpg extension
    local dest_path="$HOME/${relative_path%.gpg}" # Correctly form the destination path

    echo "Decrypting $src_file to $dest_path..."

    # Create the destination directory if it doesn't exist
    mkdir -p "$(dirname "$dest_path")"

    # Decrypt the file into its destination (assumes gpg is configured to not prompt for output file)
    gpg --quiet --batch --yes --decrypt --output "$dest_path" "$src_file"

    if [ $? -eq 0 ]; then
        echo "Decrypted and placed: $dest_path"
        chmod 600 "$dest_path"
    else
        echo "Failed to decrypt: $src_file"
    fi
}

export -f decrypt_and_place

# Create directories first
create_directories

# Find and decrypt .gpg files, placing them in the correct location
find "$DOTFILES_DIR" -type f -name "*.gpg" -exec bash -c 'decrypt_and_place "$0"' {} \;

cd "$DOTFILES_DIR"

# Check if the new directory structure exists
if [ -d "$DOTFILES_DIR/common" ]; then
    echo "Using new directory structure..."
    
    # Stow common configs
    if [ -d "common" ]; then
        echo "Stowing common configs..."
        stow -v common
    fi
    
    # Stow OS-specific configs
    if [ -d "$OS" ]; then
        echo "Stowing $OS-specific configs..."
        stow -v "$OS"
    fi
else
    echo "Using legacy structure..."
    # Fall back to old behavior for backwards compatibility
    stow -v .
fi

echo "Dotfiles installation complete!"
