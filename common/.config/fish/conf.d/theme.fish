# This machine's theme and prompt badge, from ~/.config/theme (see its README).
# Sorts after fish_frozen_theme.fish, so a theme's colours win.
set -g host_theme kanagawa
set -g host_badge
set -l host_file ~/.config/theme/hosts/(prompt_hostname)
if test -r $host_file
    for line in (string match -rv '^\s*(#|$)' <$host_file)
        set -l kv (string split -m1 ' ' -- (string trim -- $line))
        switch $kv[1]
            case theme
                set host_theme $kv[2]
            case badge
                set host_badge $kv[2]
        end
    end
end
set -q HOST_THEME; and set host_theme $HOST_THEME
test -r ~/.config/theme/$host_theme.fish; or set host_theme kanagawa
source ~/.config/theme/$host_theme.fish
