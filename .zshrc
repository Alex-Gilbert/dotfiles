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
antigen bundle jeffreytse/zsh-vi-mode
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle MichaelAquilina/zsh-you-should-use

# Load the theme.
antigen theme eastwood

# Tell Antigen that you're done.
antigen apply

bindkey '^k' history-substring-search-up
bindkey '^j' history-substring-search-down

bindkey '^l' expand-or-complete-prefix
bindkey '^s' expand-or-complete

bindkey '^i' beginning-of-line
bindkey '^a' end-of-line

HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

export PATH="$PATH:$HOME/.local/CPLEX_Studio221/cplex/bin/x86-64_linux/"
export PATH="$PATH:$HOME/.local/zig-0.12.0/"
export PATH="$PATH:$HOME/.local/pandoc-3.1.8/bin/"
export PATH="$PATH:$HOME/dotfiles/scripts/"

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias bat=batcat

alias z=zellij

alias n=nvim
alias dcr="cd ~/dc-repos/"
alias sky="cd ~/dc-repos/skyshark/"
. "$HOME/.cargo/env"
eval "$(zoxide init zsh --cmd cd)"
