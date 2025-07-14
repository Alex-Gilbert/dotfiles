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

# Source cross-platform utilities to get OS_TYPE
source "$DOTFILES_DIR/scripts/cross-platform-utils.sh"

# Check if arguments are provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file-to-encrypt> [--os <linux|macos>]"
    echo "  If --os is not specified, defaults to 'common'"
    exit 1
fi

# Parse arguments
TARGET_OS="common"
while [[ $# -gt 0 ]]; do
    case $1 in
        --os)
            TARGET_OS="$2"
            shift 2
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# Validate OS choice
if [[ "$TARGET_OS" != "common" && "$TARGET_OS" != "linux" && "$TARGET_OS" != "macos" ]]; then
    echo "Error: --os must be 'common', 'linux', or 'macos'"
    exit 1
fi

# Convert input file to absolute path if necessary
INPUT_FILE="$(get_absolute_path "$INPUT_FILE")"

# Verify that the file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File $INPUT_FILE does not exist."
    exit 1
fi

# Calculate the path relative to the home directory
RELATIVE_PATH="${INPUT_FILE#$HOME/}"

# Construct the new path within the appropriate OS-specific directory
ENCRYPTED_FILE_PATH="$DOTFILES_DIR/$TARGET_OS/${RELATIVE_PATH}.gpg"

# Create the target directory if it doesn't exist
mkdir -p "$(dirname "$ENCRYPTED_FILE_PATH")"

echo "Encrypting $INPUT_FILE to $ENCRYPTED_FILE_PATH..."

gpg --output "$ENCRYPTED_FILE_PATH" --encrypt --recipient "$EMAIL" "$INPUT_FILE"

echo "Encryption complete: $ENCRYPTED_FILE_PATH"
