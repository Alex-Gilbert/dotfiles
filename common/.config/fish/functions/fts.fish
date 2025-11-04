function fts
    set session_name (basename (pwd) | tr . _)

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

    # Check if .tmux file exists
    if test -f .tmux
        echo "Loading session from .tmux file..."
        if test -n "$TMUX"
            # Inside tmux, load detached and switch
            tmuxp load -d .tmux
            tmux switch-client -t $session_name
        else
            # Outside tmux, load and attach
            tmuxp load .tmux
        end
    else
        # No .tmux file, create simple session
        if test -n "$TMUX"
            tmux new-session -d -s $session_name -c (pwd)
            tmux switch-client -t $session_name
        else
            tmux new-session -s $session_name -c (pwd)
        end
    end
end
