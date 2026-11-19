function fish_prompt
    # Colours come from the host theme (conf.d/theme.fish); names as a fallback.
    set -q theme_prompt_path; or source ~/.config/theme/kanagawa.fish

    # Path segment (replace home with ~)
    set path_segment (string replace $HOME "~" $PWD)

    # Git info
    set git_info ""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set branch (git branch --show-current 2>/dev/null)
        set status_output (git status --porcelain 2>/dev/null)

        if test -z "$status_output"
            set status_indicator (set_color $theme_prompt_clean)"✓"(set_color normal)
        else
            set status_indicator (set_color $theme_prompt_dirty)"✗"(set_color normal)
        end

        set git_info (set_color $theme_prompt_bracket)"["(set_color $theme_prompt_branch)$branch(set_color normal)" $status_indicator"(set_color $theme_prompt_bracket)"]"(set_color normal)
    end

    # Badge: which machine this shell runs on, when the host file names one.
    set badge ""
    if test -n "$host_badge"
        set badge (set_color $theme_prompt_badge)" $host_badge "(set_color normal)" "
    end

    # Main prompt
    echo $badge(set_color $theme_prompt_path)$path_segment(set_color normal) $git_info
    echo (set_color $theme_prompt_arrow)"❯ "(set_color normal)
end
