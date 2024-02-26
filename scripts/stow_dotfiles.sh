#!/bin/bash

# Define the path to your dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"
export DOTFILES_DIR

decrypt_and_place() {
    local src_file="$1"
    echo "src_file: $src_file"

    # Compute the path relative to the DOTFILES_DIR, ensuring it's an absolute path
    local src_file_abs_path=$(readlink -f $src_file)
    echo "src_file_abs_path: $src_file_abs_path"

    # Remove the DOTFILES_DIR part from the absolute path of the source file
    local relative_path="${src_file_abs_path#$DOTFILES_DIR/}"
    echo "relative_path: $relative_path"

    # Construct the absolute destination path by removing the .gpg extension
    local dest_path="$HOME/${relative_path%.gpg}" # Correctly form the destination path
    echo "dest_path: $dest_path"

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

# Find and decrypt .gpg files, placing them in the correct location
find "$DOTFILES_DIR" -type f -name "*.gpg" -exec bash -c 'decrypt_and_place "$0"' {} \;

cd "$DOTFILES_DIR"
stow .
