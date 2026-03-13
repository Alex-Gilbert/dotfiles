function ccr
    set cmd (command ccr)
    if test -n "$cmd"
        eval $cmd
    end
end
