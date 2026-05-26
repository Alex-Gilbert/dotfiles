#!/usr/bin/env bash
# Per-session floating terminal pane
# Each tmux session gets its own persistent float session

session="$(tmux display-message -p '#{session_name}')"
float="_float_${session}"
current_dir="$(tmux display-message -p '#{pane_current_path}')"

width="$(tmux show-option -gqv '@float-width')"
height="$(tmux show-option -gqv '@float-height')"
border_color="$(tmux show-option -gqv '@float-border-color')"
text_color="$(tmux show-option -gqv '@float-text-color')"

width="${width:-80%}"
height="${height:-80%}"
border_color="${border_color:-#98bb6c}"
text_color="${text_color:-#dcd7ba}"

# If we're inside a float session, detach (toggle off)
if [[ "$session" == _float_* ]]; then
    tmux detach-client
    exit 0
fi

# Create the float session if it doesn't exist
if ! tmux has-session -t "$float" 2>/dev/null; then
    tmux new-session -d -s "$float" -c "$current_dir"
    tmux set-option -t "$float" status off
    tmux set-option -t "$float" detach-on-destroy on
fi

# Open popup attached to this session's float
tmux popup \
    -S "fg=${border_color}" \
    -s "fg=${text_color}" \
    -w "$width" \
    -h "$height" \
    -b rounded \
    -E \
    "tmux attach-session -t '${float}'"
