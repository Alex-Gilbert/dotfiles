function ftu --description 'Pick a tuios session or zoxide dir; attach to (or create) its session'
    # Sessions first (marked ●), then zoxide dirs by frecency.
    set pick (begin
            tuios ls --json 2>/dev/null | jq -r '.[] | "● " + .name'
            zoxide query -l
        end | fzf --prompt 'session> ' --height 100% --reverse --no-sort \
            --preview 'test -d {} && ls -A --color=always {} || tuios list-windows -s (string sub -s 3 {}) 2>/dev/null')

    if test -z "$pick"
        # Cancelled: outside tuios, fall back to a fresh scratch session.
        set -q TUIOS_SESSION; or tuios new
        return 0
    end

    if string match -q '● *' -- $pick
        set name (string sub -s 3 -- $pick)
        set dir
    else
        set name (basename $pick | string replace -a . _)
        set dir $pick
    end

    if set -q TUIOS_SESSION
        # Inside tuios: switch this client in place instead of nesting.
        if test -n "$dir"
            tuios switch-session --create --cwd $dir $name
        else
            tuios switch-session $name
        end
    else
        test -n "$dir"; and cd $dir
        tuios attach -c $name
    end
end
