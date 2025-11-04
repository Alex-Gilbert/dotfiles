function ftn
    # Determine session name: from .tmux file, argument, or auto-name from directory
    if test (count $argv) -gt 0
        # Argument provided, use it
        set session_name (string replace -a . _ $argv[1])
    else if test -f .tmux
        # No argument but .tmux exists, get name from file
        set session_name (grep "^session_name:" .tmux | string split ": ")[2]
        set session_name (string replace -a . _ $session_name)
    else
        # No argument and no .tmux, auto-name from directory
        set session_name (basename (pwd) | tr . _)
    end

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
        # tmuxp load will create and attach/switch to the session
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
