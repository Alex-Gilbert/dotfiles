function ftsave
    if test -z "$TMUX"
        echo "Not in a tmux session"
        return 1
    end

    set session_name (tmux display-message -p '#S')

    # Use tmuxp freeze to save the current session
    tmuxp freeze -o .tmux --yes --force

    echo "Saved session '$session_name' to .tmux"
end
