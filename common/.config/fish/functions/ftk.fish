function ftk
    set -l socket_root /tmp
    set -q TMUX_TMPDIR; and set socket_root $TMUX_TMPDIR
    set -l sockets $socket_root/tmux-(id -u)/*
    set -q TMUX; and set -a sockets (string split -r -m 2 , -- "$TMUX")[1]
    set -l selected (for socket in (printf '%s\n' $sockets | sort -u)
        test -S "$socket"; or continue
        tmux -S "$socket" list-sessions -F "#{socket_path}	#{session_id}	#{session_name}" 2>/dev/null
    end | fzf --delimiter=\t --with-nth=1,3 --prompt="Kill session: " --preview='tmux -S {1} list-windows -t {2}')
    test -n "$selected"; or return
    set -l fields (string split \t -- "$selected")
    tmux -S "$fields[1]" kill-session -t "$fields[2]"; and echo "Killed session: $fields[3] ($fields[1])"
end
