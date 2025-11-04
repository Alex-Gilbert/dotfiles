function ftz
    # Use zoxide interactive to select directory
    set selected (zoxide query -i)

    if test -z "$selected"
        # User cancelled, return to shell
        return 0
    end

    cd $selected
    set session_name (basename $selected | tr . _)

    # Check if session exists
    if tmux has-session -t $session_name 2>/dev/null
        # Attach to existing
        if test -n "$TMUX"
            tmux switch-client -t $session_name
        else
            tmux attach-session -t $session_name
        end
    else
        # Create new (with .tmux support via tmuxp)
        if test -f .tmux
            tmuxp load .tmux
        else
            tmux new-session -s $session_name -c $selected
        end
    end
end
