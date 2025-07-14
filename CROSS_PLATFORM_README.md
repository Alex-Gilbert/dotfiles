# Cross-Platform Dotfiles Guide

This dotfiles repository now supports both Linux and macOS. Here's how to use it on either platform.

## Directory Structure

```
dotfiles/
├── common/          # Shared configs for both Linux and macOS
├── linux/           # Linux-specific configs
├── macos/           # macOS-specific configs
└── scripts/         # Helper scripts
```

## Quick Start

### On a fresh macOS installation:
```bash
# Clone the repository
git clone <your-dotfiles-repo> ~/dotfiles
cd ~/dotfiles

# Run the macOS setup script
./scripts/setup-macos.sh
```

### On Linux:
```bash
# Clone the repository
git clone <your-dotfiles-repo> ~/dotfiles
cd ~/dotfiles

# Run the stow setup
./scripts/stow_dotfiles.sh
```

## Key Features

### 1. **Automatic OS Detection**
The `stow_dotfiles.sh` script automatically detects your OS and applies the appropriate configurations:
- Common configurations are always applied
- OS-specific configurations are applied based on the detected platform

### 2. **Cross-Platform Shell Configuration**
- The main `.zshrc` in `common/` handles both platforms
- OS-specific settings are loaded from `.zshrc.linux` or `.zshrc.macos`
- Machine-specific settings can be added to `.zshrc.local` (not tracked by git)

### 3. **Platform Utilities**
The `scripts/cross-platform-utils.sh` provides portable commands:
- `portable_sed` - Works with both GNU and BSD sed
- `portable_grep` - Works with both GNU and BSD grep
- `portable_find` - Works with both GNU and BSD find
- `portable_readlink` - Handles the missing `-f` flag on macOS
- `copy_to_clipboard` / `paste_from_clipboard` - Cross-platform clipboard access

### 4. **Neovim Platform Support**
- `lua/utils/platform.lua` provides OS detection and platform-specific helpers
- Automatically uses the correct commands (e.g., `xdg-open` vs `open`)
- Handles different `stat` command syntax between platforms

## Migration Guide

If you're migrating existing dotfiles:

1. Run the migration helper to see suggestions:
   ```bash
   ./scripts/migrate_to_cross_platform.sh
   ```

2. Move files to the appropriate directories:
   ```bash
   # For shared configs
   git mv .config/nvim common/.config/

   # For Linux-specific configs
   git mv .config/i3 linux/.config/

   # For macOS-specific configs (when you have them)
   git mv .config/karabiner macos/.config/
   ```

3. Update any scripts to use the cross-platform utilities:
   ```bash
   # Source the utilities
   source "$HOME/dotfiles/scripts/cross-platform-utils.sh"
   
   # Use portable commands
   portable_sed -i 's/old/new/g' file.txt
   ```

## macOS-Specific Setup

The `setup-macos.sh` script will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install essential packages (including GNU coreutils for Linux compatibility)
4. Configure sensible macOS defaults
5. Set up your development environment
6. Run the dotfiles installation

### GNU Tools on macOS
The setup installs GNU versions of common tools:
- `coreutils` (provides `gls`, `gdate`, etc.)
- `gnu-sed` (provides `gsed`)
- `grep` (provides `ggrep`)
- `findutils` (provides `gfind`)

These are automatically used by the cross-platform utilities when available.

## Adding New Configurations

### For shared configs:
Place them in the `common/` directory with the same structure as your home directory.

### For OS-specific configs:
Place them in `linux/` or `macos/` directories.

### For scripts:
1. Source the cross-platform utilities at the top
2. Use `OS_TYPE` variable for conditionals
3. Use portable commands for cross-platform compatibility

Example:
```bash
#!/bin/bash
source "$HOME/dotfiles/scripts/cross-platform-utils.sh"

if [[ "$OS_TYPE" == "macos" ]]; then
    # macOS-specific code
else
    # Linux-specific code
fi

# Use portable commands
portable_sed -i 's/pattern/replacement/g' file.txt
```

## Troubleshooting

### Stow creates symlinks to entire directories
This is handled by pre-creating essential directories in `stow_dotfiles.sh`. If you encounter this issue with new directories, add them to the `create_directories()` function.

### Command not found on macOS
Make sure you've run `setup-macos.sh` to install all required tools via Homebrew.

### Different command behavior between platforms
Use the portable wrappers in `cross-platform-utils.sh` or check the platform with `$OS_TYPE`.

## Testing

Before pushing changes, test on both platforms if possible:
1. Linux: Run `./scripts/stow_dotfiles.sh`
2. macOS: Run `./scripts/stow_dotfiles.sh`
3. Verify all symlinks are created correctly
4. Test that configurations work as expected