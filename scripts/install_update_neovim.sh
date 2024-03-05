#!/bin/bash

# Set the Neovim version to build
NEOVIM_VERSION="stable" # You can specify a version tag or "stable" for the latest stable release

# Create a temporary directory for the build process
BUILD_DIR=$(mktemp -d)
echo "Building Neovim in temporary directory $BUILD_DIR"

# Ensure cleanup on exit
function cleanup {
    echo "Cleaning up..."
    rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

# Change to the temporary directory
cd "$BUILD_DIR"

# Function to install dependencies using apt
install_deps_apt() {
    sudo apt update
    sudo apt install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen
}

# Function to install dependencies using pacman
install_deps_pacman() {
    sudo pacman -Sy --needed --noconfirm ninja gettext libtool autoconf automake cmake gcc pkgconf unzip curl doxygen
}

# Detect package manager and install dependencies
if command -v apt > /dev/null; then
    install_deps_apt
elif command -v pacman > /dev/null; then
    install_deps_pacman
else
    echo "Unsupported package manager. Script supports apt and pacman."
    exit 1
fi

# Clone the Neovim repository
git clone https://github.com/neovim/neovim.git
cd neovim
git checkout ${NEOVIM_VERSION}

# Build Neovim
make CMAKE_BUILD_TYPE=Release
sudo make install

# Verify Neovim installation
nvim --version
