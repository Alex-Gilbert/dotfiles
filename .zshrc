setopt extended_glob
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt inc_append_history
setopt share_history

source ~/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle heroku
antigen bundle pip
antigen bundle lein
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle MichaelAquilina/zsh-you-should-use

# Load the theme.
antigen theme eastwood

# Tell Antigen that you're done.
antigen apply

bindkey '^K' history-substring-search-up
bindkey '^J' history-substring-search-down

bindkey '^L' expand-or-complete-prefix
bindkey '^S' expand-or-complete

bindkey '^I' beginning-of-line
bindkey '^A' end-of-line

HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

export PATH="$PATH:$HOME/.local/CPLEX_Studio221/cplex/bin/x86-64_linux/"
export PATH="$PATH:$HOME/.local/zig-0.12.0/"
export PATH="$PATH:$HOME/.local/pandoc-3.1.8/bin/"
export PATH="$PATH:$HOME/.local/renderdoc_1.31/bin/"
export PATH="$PATH:$HOME/dotfiles/scripts/"
export PATH="$PATH:$HOME/dc-repos/artiv-deployment/"

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias bat=batcat
alias cu=cluster-utils.sh

alias z=zellij

alias n=nvim
alias dcr="cd ~/dc-repos/"
alias sky="cd ~/dc-repos/skyshark/"
. "$HOME/.cargo/env"

eval "$(zoxide init zsh --cmd cd)"
eval $(keychain --eval --quiet ~/.ssh/id_rsa_work ~/.ssh/id_rsa_personal)

source /usr/share/nvm/init-nvm.sh

alias dive="docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    wagoodman/dive:latest"
