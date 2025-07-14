#!/bin/bash

# Function to convert a relative path to an absolute path
get_absolute_path() {
    local REL_PATH="$1"
    # Check if the input is a directory or a file for accurate path handling
    if [ -d "$REL_PATH" ]; then
        # For directories, simply use 'pwd' within the directory
        local ABS_PATH="$(cd "$REL_PATH"; pwd)"
    else
        # For files, use 'pwd' and append the basename
        local ABS_PATH="$(cd "$(dirname "$REL_PATH")"; pwd)/$(basename "$REL_PATH")"
    fi
    echo "$ABS_PATH"
}

# Your dotfiles directory path
DOTFILES_DIR="$HOME/dotfiles"

# Source cross-platform utilities to get OS_TYPE
source "$DOTFILES_DIR/scripts/cross-platform-utils.sh"

# Check if arguments are provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file-or-directory-to-add> [--os <linux|macos>]"
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
            INPUT_PATH="$1"
            shift
            ;;
    esac
done

# Validate OS choice
if [[ "$TARGET_OS" != "common" && "$TARGET_OS" != "linux" && "$TARGET_OS" != "macos" ]]; then
    echo "Error: --os must be 'common', 'linux', or 'macos'"
    exit 1
fi

# Convert input path to absolute path if necessary
INPUT_PATH="$(get_absolute_path "$INPUT_PATH")"

# Verify that the path exists and is either a file or a directory
if [ ! -f "$INPUT_PATH" ] && [ ! -d "$INPUT_PATH" ]; then
    echo "Error: $INPUT_PATH does not exist or is not a valid file/directory."
    exit 1
fi

# Calculate the path relative to the home directory
RELATIVE_PATH="${INPUT_PATH#$HOME/}"

# Construct the new path within the appropriate OS-specific directory
NEW_PATH="$DOTFILES_DIR/$TARGET_OS/${RELATIVE_PATH}"

# Create the target directory if it doesn't exist (for files, or copy root for directories)
mkdir -p "$(dirname "$NEW_PATH")"

# Move the file or directory to the new location
mv "$INPUT_PATH" "$NEW_PATH"
echo "Moved $INPUT_PATH to $NEW_PATH"

cd "$DOTFILES_DIR"
stow -v "$TARGET_OS"
