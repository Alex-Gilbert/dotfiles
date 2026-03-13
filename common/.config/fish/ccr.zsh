ccr() {
    local cmd=$(command ccr)
    [[ -n "$cmd" ]] && eval "$cmd"
}
