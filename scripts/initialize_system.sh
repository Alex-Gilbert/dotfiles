#!/bin/bash

# Define where Antigen will be installed
# Define the path to your dotfiles directory
DOTFILES_DIR=~/dotfiles
ANTIGEN_PATH="$HOME/.antigen"

# Function to install Antigen
install_antigen() {
    echo "Installing Antigen..."
    mkdir -p "$ANTIGEN_PATH"
    curl -L git.io/antigen > "$ANTIGEN_PATH/antigen.zsh"
    if [ $? -eq 0 ]; then
        echo "Antigen installed successfully."
    else
        echo "Failed to install Antigen."
        exit 1
    fi
}


# Check if Antigen is already installed
if [ -f "$ANTIGEN_PATH/antigen.zsh" ]; then
    echo "Antigen is already installed."
else
    install_antigen
fi

# Further setup steps can be added below
# For example, stowing dotfiles, installing other packages, etc.

echo "Setup script completed."
