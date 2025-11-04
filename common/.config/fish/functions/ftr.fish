function ftr
    if test -z "$TMUX"
        echo "Not in a tmux session"
        return 1
    end

    if test (count $argv) -eq 0
        echo "Usage: ftr <new-session-name>"
        return 1
    end

    set new_name (string replace -a . _ $argv[1])
    tmux rename-session $new_name
    echo "Session renamed to: $new_name"
end
