#!/bin/bash
set -e

# Update the system packages first
echo "Updating system packages..."
sudo pacman -Syu --noconfirm

# Install essential tools and utilities for Neovim and development
echo "Installing Neovim essentials and related utilities..."
sudo pacman -S --noconfirm \
  neovim \
  fzf \
  ripgrep \
  fd \
  bat \
  universal-ctags \
  python-pynvim \
  nodejs \
  npm \
  ninja \
  dotnet-sdk \
  stow \
  zoxide \
  zellij

# Setup Rust (rustup installs Cargo with the toolchain)
echo "Installing rustup and setting up the Rust toolchain..."
sudo pacman -S --noconfirm rustup
rustup default stable

# Add build targets for WebAssembly and Linux
echo "Adding WebAssembly build target..."
rustup target add wasm32-unknown-unknown
echo "Adding native Linux build target..."
rustup target add x86_64-unknown-linux-gnu

# Install Lua 5.1 and LuaRocks for Lua 5.1 from the AUR using paru
echo "Installing Lua 5.1 and LuaRocks (for Lua 5.1) from AUR..."
paru -S --noconfirm lua51 lua51-luarocks

# Install JetBrains Toolbox and Visual Studio Code (visual-studio-cod-bin) from the AUR
echo "Installing JetBrains Toolbox and Visual Studio Code..."
paru -S --noconfirm jetbrains-toolbox visual-studio-cod-bin

echo "All installations complete!"
