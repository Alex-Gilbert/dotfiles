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

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file-or-directory-to-add>"
    exit 1
fi

# Input path (convert to absolute path if necessary)
INPUT_PATH="$(get_absolute_path "$1")"

# Verify that the path exists and is either a file or a directory
if [ ! -f "$INPUT_PATH" ] && [ ! -d "$INPUT_PATH" ]; then
    echo "Error: $INPUT_PATH does not exist or is not a valid file/directory."
    exit 1
fi

# Calculate the path relative to the home directory
RELATIVE_PATH="${INPUT_PATH#$HOME/}"

# Construct the new path for the encrypted file within your DOTFILES directory
NEW_PATH="$DOTFILES_DIR/${RELATIVE_PATH}"

# Create the target directory if it doesn't exist (for files, or copy root for directories)
mkdir -p "$(dirname "$NEW_PATH")"

# Move the file or directory to the new location
mv "$INPUT_PATH" "$NEW_PATH"
echo "Moved $INPUT_PATH to $NEW_PATH"

cd "$DOTFILES_DIR"
stow .
