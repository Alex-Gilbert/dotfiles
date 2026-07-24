# Vi mode
fish_vi_key_bindings

# Vi mode cursor shapes (if your terminal supports it)
set fish_vi_force_cursor 1
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore

# Aliases
alias lg lazygit
alias cu cluster-utils.sh
# alias z 'zellij -l welcome'
alias n nvim
alias dive 'docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest'
alias dd 'nohup dolphin $PWD > /dev/null 2>&1 &'
alias c='xclip -selection clipboard'
alias serena='uvx --from git+https://github.com/oraios/serena serena start-mcp-server'
alias kay kubectl
alias mouse-speed='xinput set-prop 14 "libinput Accel Speed"'
alias space-check='sudo du -h --max-depth=1 . | sort -h'
alias vpnup='sudo wg-quick up protonvpn'
alias vpndown='sudo wg-quick down protonvpn'

# Cross-platform PATH additions
fish_add_path $HOME/.config/fish/functions
fish_add_path $HOME/dotfiles/scripts
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.bun/bin

# Platform-specific config: each platform's stow package drops a file into
# ~/.config/fish/conf.d/ which fish auto-sources. macOS keeps its legacy hook
# below for back-compat with macos/.config/fish/config.fish.
#   - Linux desktop  -> linux/.config/fish/conf.d/linux-env.fish
#   - Termux/Android -> android/.config/fish/conf.d/android-env.fish
if test (uname -s) = "Darwin"
    if test -f $HOME/dotfiles/macos/.config/fish/config.fish
        source $HOME/dotfiles/macos/.config/fish/config.fish
    end
    fish_add_path /usr/local/share/dotnet
    fish_add_path (go env GOPATH)/bin
end

# Common environment variables
set -gx GAMS_VERSION "46.4"

# Editors
set -gx EDITOR "nvim"
set -gx VISUAL "nvim"

# ssh-agent
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket" 

# Zoxide integration
set -Ux _ZO_EXCLUDE_DIRS "/mnt/*:/run/media/*"
zoxide init fish --cmd cd | source

# Disable greeting
set fish_greeting

# History settings (Fish defaults are already good)

# Custom key bindings
bind -M insert \er 'fzf-history'
bind -M default \er 'fzf-history'

# opencode
fish_add_path $HOME/.opencode/bin

# dotenv
set -g fish_dotenv_enable_yes 1

# cook
fish_add_path "$HOME/.cook/bin"
COMPLETE=fish cook | source
