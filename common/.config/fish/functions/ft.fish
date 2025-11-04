function ft
    set selected (tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf)
    if test -n "$selected"
        if test -n "$TMUX"
            tmux switch-client -t $selected
        else
            tmux attach-session -t $selected
        end
    end
end
