function fish_prompt
    # Path segment (replace home with ~)
    set path_segment (string replace $HOME "~" $PWD)
    
    # Git info
    set git_info ""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set branch (git branch --show-current 2>/dev/null)
        set status_output (git status --porcelain 2>/dev/null)
        
        if test -z "$status_output"
            set status_indicator (set_color green)"✓"(set_color normal)
        else
            set status_indicator (set_color red)"✗"(set_color normal)
        end
        
        set git_info (set_color white)"["(set_color cyan)$branch(set_color normal)" $status_indicator"(set_color white)"]"(set_color normal)
    end
    
    # Main prompt
    echo (set_color blue)$path_segment(set_color normal) $git_info
    echo (set_color green)"❯ "(set_color normal)
end
