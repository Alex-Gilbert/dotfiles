function fp
    set selected (find ~/dev/ -mindepth 3 -maxdepth 4 -type d -not -path '*/.git*' -not -path '*/node_modules/*' | fzf)
    if test -n "$selected"
        cd $selected
    end
end
