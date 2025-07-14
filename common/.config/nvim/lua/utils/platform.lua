-- Platform-specific utilities for Neovim configuration

local M = {}

-- Detect the operating system
M.is_macos = vim.fn.has("macunix") == 1
M.is_linux = vim.fn.has("unix") == 1 and not M.is_macos
M.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

-- Get the appropriate command for opening files/URLs
M.get_open_cmd = function()
    if M.is_macos then
        return "open"
    elseif M.is_linux then
        return "xdg-open"
    elseif M.is_windows then
        return "start"
    end
end

-- Get the appropriate stat command for file times
M.get_stat_cmd = function(type)
    if M.is_macos then
        if type == "birth" then
            return "stat -f %B"  -- Birth time
        elseif type == "modified" then
            return "stat -f %m"  -- Modified time
        end
    elseif M.is_linux then
        if type == "birth" then
            return "stat -c %w"  -- Birth time (might be unsupported)
        elseif type == "modified" then
            return "stat -c %y"  -- Modified time
        end
    end
end

-- Get the appropriate clipboard command
M.get_clipboard_cmd = function()
    if M.is_macos then
        return {
            copy = "pbcopy",
            paste = "pbpaste"
        }
    elseif M.is_linux then
        return {
            copy = "xclip -selection clipboard",
            paste = "xclip -selection clipboard -o"
        }
    end
end

-- Get platform-specific paths
M.get_platform_paths = function()
    local paths = {}
    
    if M.is_macos then
        -- Add Homebrew paths
        table.insert(paths, "/opt/homebrew/bin")
        table.insert(paths, "/usr/local/bin")
    elseif M.is_linux then
        -- Add Linux-specific paths
        table.insert(paths, "/usr/local/bin")
        table.insert(paths, vim.fn.expand("~/.local/bin"))
    end
    
    return paths
end

-- Check if a command exists
M.command_exists = function(cmd)
    return vim.fn.executable(cmd) == 1
end

-- Get the appropriate package manager command
M.get_package_manager = function()
    if M.is_macos then
        if M.command_exists("brew") then
            return "brew"
        end
    elseif M.is_linux then
        if M.command_exists("pacman") then
            return "pacman"
        elseif M.command_exists("apt") then
            return "apt"
        elseif M.command_exists("dnf") then
            return "dnf"
        end
    end
    return nil
end

-- Helper to install missing tools
M.suggest_install = function(tool)
    local pm = M.get_package_manager()
    if not pm then
        return "Please install " .. tool .. " manually"
    end
    
    if pm == "brew" then
        return "brew install " .. tool
    elseif pm == "pacman" then
        return "sudo pacman -S " .. tool
    elseif pm == "apt" then
        return "sudo apt install " .. tool
    elseif pm == "dnf" then
        return "sudo dnf install " .. tool
    end
end

return M