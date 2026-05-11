#!/bin/bash

# Cross-platform utility functions
# Source this file in your scripts to get portable commands

# Detect OS. Termux reports "Linux" via uname, so disambiguate via $PREFIX/$TERMUX_VERSION.
case "$(uname -s)" in
    Darwin)
        OS_TYPE="macos"
        ;;
    Linux)
        if [ -n "${TERMUX_VERSION:-}" ] || [ "${PREFIX:-}" = "/data/data/com.termux/files/usr" ]; then
            OS_TYPE="android"
        else
            OS_TYPE="linux"
        fi
        ;;
    *)
        OS_TYPE="unknown"
        ;;
esac

# Function to use the correct sed command
portable_sed() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        # Check if GNU sed is installed
        if command -v gsed >/dev/null 2>&1; then
            gsed "$@"
        else
            # Use BSD sed with different syntax
            sed "$@"
        fi
    else
        sed "$@"
    fi
}

# Function for in-place sed operations
portable_sed_inplace() {
    local sed_script="$1"
    shift
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if command -v gsed >/dev/null 2>&1; then
            gsed -i "$sed_script" "$@"
        else
            # BSD sed requires extension for -i
            sed -i '' "$sed_script" "$@"
        fi
    else
        sed -i "$sed_script" "$@"
    fi
}

# Function to use the correct grep command
portable_grep() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        # Check if GNU grep is installed
        if command -v ggrep >/dev/null 2>&1; then
            ggrep "$@"
        else
            grep "$@"
        fi
    else
        grep "$@"
    fi
}

# Function to use the correct find command
portable_find() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        # Check if GNU find is installed
        if command -v gfind >/dev/null 2>&1; then
            gfind "$@"
        else
            find "$@"
        fi
    else
        find "$@"
    fi
}

# Function to use the correct readlink command
portable_readlink() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        # Check if GNU readlink is installed
        if command -v greadlink >/dev/null 2>&1; then
            greadlink "$@"
        else
            # macOS doesn't have readlink -f, use alternative
            if [[ "$1" == "-f" ]]; then
                shift
                python3 -c "import os; print(os.path.realpath('$1'))"
            else
                readlink "$@"
            fi
        fi
    else
        readlink "$@"
    fi
}

# Function to use the correct date command
portable_date() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        # Check if GNU date is installed
        if command -v gdate >/dev/null 2>&1; then
            gdate "$@"
        else
            date "$@"
        fi
    else
        date "$@"
    fi
}

# Function to get number of CPU cores
get_cpu_cores() {
    case "$OS_TYPE" in
        macos) sysctl -n hw.ncpu ;;
        *)     nproc ;;
    esac
}

# Function to open files/URLs in default application
portable_open() {
    case "$OS_TYPE" in
        macos)   open "$@" ;;
        android) termux-open "$@" ;;
        *)       xdg-open "$@" ;;
    esac
}

# Function to copy to clipboard
copy_to_clipboard() {
    case "$OS_TYPE" in
        macos)   pbcopy ;;
        android) termux-clipboard-set ;;
        *)       xclip -selection clipboard ;;
    esac
}

# Function to paste from clipboard
paste_from_clipboard() {
    case "$OS_TYPE" in
        macos)   pbpaste ;;
        android) termux-clipboard-get ;;
        *)       xclip -selection clipboard -o ;;
    esac
}

# Export functions so they're available to subshells
export -f portable_sed
export -f portable_sed_inplace
export -f portable_grep
export -f portable_find
export -f portable_readlink
export -f portable_date
export -f get_cpu_cores
export -f portable_open
export -f copy_to_clipboard
export -f paste_from_clipboard

# Export OS_TYPE for use in scripts
export OS_TYPE