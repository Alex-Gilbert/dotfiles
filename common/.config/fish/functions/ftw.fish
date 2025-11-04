function ftw
    if test -z "$TMUX"
        echo "Not in a tmux session"
        return 1
    end

    set selected (tmux list-windows -F "#{window_index}: #{window_name}" | fzf)
    if test -n "$selected"
        set window_index (string split ":" $selected)[1]
        tmux select-window -t $window_index
    end
end
