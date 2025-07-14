function fish_right_prompt
    # Current time
    set current_time (date "+%H:%M:%S")
    
    # Command duration
    set duration_display ""
    if test -n "$CMD_DURATION"
        set duration_ms $CMD_DURATION
        
        if test $duration_ms -lt 1000
            set duration_display "took "(set_color yellow)$duration_ms"ms"(set_color normal)
        else if test $duration_ms -lt 60000
            set duration_sec (math $duration_ms / 1000)
            set duration_display "took "(set_color yellow)(printf "%.2f" $duration_sec)"s"(set_color normal)
        else
            set duration_min (math -s0 $duration_ms / 60000)
            set remaining_sec (math -s0 "($duration_ms % 60000) / 1000")
            set duration_display "took "(set_color yellow)$duration_min"m "$remaining_sec"s"(set_color normal)
        end
    end
    
    echo $duration_display " "(set_color white)"["$current_time"]"(set_color normal)
end
