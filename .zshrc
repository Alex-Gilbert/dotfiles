# Disable flow control
stty -ixon

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt extended_glob
setopt extended_history
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_save_no_dups
setopt hist_verify
setopt inc_append_history
setopt sharehistory


# Ste the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit, if it's not already installed
if [[ ! -d $ZINIT_HOME ]]; then
    echo "Installing zinit..."
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in the Powerlevel10k plugin
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

zinit load zsh-users/zsh-history-substring-search
zinit ice wait atload'_history_substring_search_config'

source ~/zsh-vi-mode-alex.zsh

# Load zsh-completions
autoload -U compinit && compinit
zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# COMPLETION STYLES
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


# Aliases
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lg='lazygit'
alias cu=cluster-utils.sh
alias z=zellij
alias n=nvim
alias cpf='xclip -selection clipboard -t $(file -b --mime-type "$1") -i < "$1"'

alias dive="docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    wagoodman/dive:latest"

# Path
export PATH="$PATH:$HOME/.local/CPLEX_Studio221/cplex/bin/x86-64_linux/"
export PATH="$PATH:$HOME/.local/zig-0.12.0/"
export PATH="$PATH:$HOME/.local/pandoc-3.1.8/bin/"
export PATH="$PATH:$HOME/.local/renderdoc_1.31/bin/"
export PATH="$PATH:$HOME/dotfiles/scripts/"
export PATH="$PATH:$HOME/dc-repos/artiv-deployment/"
export PATH="$PATH:$HOME/.local/bin/"

export GAMS_VERSION=46.4

# lua
source $HOME/lua51/bin/activate

# Shell Integration
eval "$(zoxide init zsh --cmd cd)"
eval "$(fzf --zsh)"
eval $(keychain --eval --quiet ~/.ssh/id_rsa_work ~/.ssh/id_rsa_personal)
source /usr/share/nvm/init-nvm.sh
