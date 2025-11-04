function fpt
    set selected (find ~/dev/ -mindepth 3 -maxdepth 4 -type d -not -path '*/.git*' -not -path '*/node_modules/*' | fzf)
    if test -z "$selected"
        return
    end

    set session_name (basename $selected | tr . _)

    # Check if session already exists
    if tmux has-session -t $session_name 2>/dev/null
        echo "Session '$session_name' already exists. Attaching..."
        if test -n "$TMUX"
            tmux switch-client -t $session_name
        else
            tmux attach-session -t $session_name
        end
        return
    end

    # Check if .tmux.yaml file exists in selected directory
    if test -f "$selected/.tmux.yaml"
        echo "Loading session from .tmux.yaml file..."
        if test -n "$TMUX"
            # Inside tmux, load detached and switch
            tmuxp load -d "$selected/.tmux.yaml"
            tmux switch-client -t $session_name
        else
            # Outside tmux, load and attach
            tmuxp load "$selected/.tmux.yaml"
        end
    else
        # No .tmux.yaml file, create simple session
        if test -n "$TMUX"
            tmux new-session -d -s $session_name -c $selected
            tmux switch-client -t $session_name
        else
            tmux new-session -s $session_name -c $selected
        end
    end
end
