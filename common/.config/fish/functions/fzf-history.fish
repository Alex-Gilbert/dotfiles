function fzf-history
    set selected (history | fzf --tac)
    if test -n "$selected"
        commandline -r $selected
        commandline -f execute
    end
end
