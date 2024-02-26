#!/bin/bash

# Function to convert a relative path to an absolute path
get_absolute_path() {
    local REL_PATH="$1"
    local ABS_PATH="$(cd "$(dirname "$REL_PATH")"; pwd)/$(basename "$REL_PATH")"
    echo "$ABS_PATH"
}

# Your dotfiles directory path
DOTFILES_DIR="$HOME/dotfiles"
EMAIL="alexp.gilbert@pm.me"

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file-to-encrypt>"
    exit 1
fi

# Input file (convert to absolute path if necessary)
INPUT_FILE="$(get_absolute_path "$1")"

# Verify that the file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File $INPUT_FILE does not exist."
    exit 1
fi

# Calculate the path relative to the home directory
RELATIVE_PATH="${INPUT_FILE#$HOME/}"

# Construct the new path for the encrypted file within your DOTFILES directory
ENCRYPTED_FILE_PATH="$DOTFILES_DIR/${RELATIVE_PATH}.gpg"

# Create the target directory if it doesn't exist
mkdir -p "$(dirname "$ENCRYPTED_FILE_PATH")"

echo "Encrypting $INPUT_FILE to $ENCRYPTED_FILE_PATH..."

gpg --output "$ENCRYPTED_FILE_PATH" --encrypt --recipient "$EMAIL" "$INPUT_FILE"

echo "Encryption complete: $ENCRYPTED_FILE_PATH"
