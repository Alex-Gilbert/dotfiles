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
alias z 'zellij -l welcome'
alias n nvim
alias dive 'docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest'
alias dd 'nohup dolphin $PWD > /dev/null 2>&1 &'
alias c='xclip -selection clipboard'
alias serena='uvx --from git+https://github.com/oraios/serena serena start-mcp-server'
alias kay kubectl
alias mouse-speed='xinput set-prop 14 "libinput Accel Speed"'
alias space-check='sudo du -h --max-depth=1 . | sort -h'

# ATH additions
set -gx PATH $PATH \
    $HOME/binaryen-version_123/bin \
    $HOME/.npm-global/bin \
    $HOME/rga-2.11.0.28 \
    $HOME/.local/CPLEX_Studio221/cplex/bin/x86-64_linux \
    $HOME/.local/zig-0.12.0 \
    $HOME/.local/pandoc-3.1.8/bin \
    $HOME/.local/renderdoc_1.31/bin \
    $HOME/dotfiles/scripts \
    $HOME/dc-repos/artiv-deployment \
    $HOME/.local/bin \
    $HOME/.dotnet/tools \
    $HOME/.local/azure-functions \
    $HOME/.cargo/bin \
    $HOME/dev/defcon/skyshark/target/release \
    $(go env GOBIN) \
    $(go env GOPATH)/bin

# Environment variables
set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
set -gx GAMS_VERSION "46.4"

# Zoxide integration
zoxide init fish --cmd cd | source

# Disable greeting
set fish_greeting

# History settings (Fish defaults are already good)

# Custom key bindings
bind -M insert \er 'fzf-history'
bind -M default \er 'fzf-history'

# opencode
fish_add_path /home/alex/.opencode/bin
