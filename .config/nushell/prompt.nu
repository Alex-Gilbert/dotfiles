$env.PROMPT_COMMAND = {
    let path_segment = (pwd | str replace $nu.home-path "~")    

    let git_info = do -i { 
        if (git rev-parse --is-inside-work-tree | complete | get exit_code) == 0 {
            let branch = (git branch --show-current | str trim)
            let status = (git status --porcelain | str trim)
            
            let status_indicator = if ($status | is-empty) {
                $"(ansi green)✓(ansi reset)"  # Clean
            } else {
                $"(ansi red)✗(ansi reset)"  # Dirty
            }
            
            $"(ansi white)[(ansi cyan)($branch)(ansi reset) ($status_indicator)](ansi reset)"
        } else {
            ""
        }
    } | default ""
    
    # Combine the path and git segments
    $"(ansi blue)($path_segment)(ansi reset) ($git_info)\n"
}

$env.TRANSIENT_PROMPT_COMMAND = {
    ""
}

# Transient prompt configuration
$env.TRANSIENT_PROMPT_COMMAND_RIGHT = {
    # Get the current timestamp
    let current_time = (date now | format date "%H:%M:%S")

    # Format the command execution time
    let cmd_duration = if ($env.CMD_DURATION_MS != null) {
        let duration_ms = $env.CMD_DURATION_MS | into int

        # Format duration based on its length
        if $duration_ms < 1000 {
            # Less than 1 second
            [(ansi yellow) $"($duration_ms)ms" (ansi reset)] | str join
        } else if $duration_ms < 60000 {
            # Less than 1 minute, show seconds
            let duration_sec = ($duration_ms / 1000 | math round --precision 2)
            [(ansi yellow) $"($duration_sec)s" (ansi reset)] | str join
        } else {
            # More than 1 minute, show minutes and seconds
            let duration_min = ($duration_ms / 60000 | math floor)
            let remaining_sec = (($duration_ms mod 60000) / 1000 | math round --precision 0)
            [(ansi yellow) $"($duration_min)m ($remaining_sec)s" (ansi reset)] | str join
        }
    } else {
        ""
    }

    # Combine all elements: time, execution duration, prompt symbol, and git info
    let time_display = [(ansi white) "[" $current_time "]" (ansi reset)] | str join
    let duration_display = if not ($cmd_duration | is-empty) {
        ["took " $cmd_duration] | str join
    } else {
        ""
    }

    [$duration_display " " $time_display] | str join
}
