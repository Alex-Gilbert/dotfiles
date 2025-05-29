# Aliases
alias lg = lazygit
alias cu = cluster-utils.sh
alias z = zellij -l welcome
alias n = nvim
alias dive = docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest
alias fp = cd (sh -c "find ~/dev/ -mindepth 3 -maxdepth 4 -type d -not -path '*/.git*' -not -path '*/node_modules/*'" | fzf)
