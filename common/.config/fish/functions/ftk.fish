function ftk
    set selected (tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --prompt="Kill session: " --preview="tmux list-windows -t {}")
    if test -n "$selected"
        tmux kill-session -t $selected
        echo "Killed session: $selected"
    end
end
