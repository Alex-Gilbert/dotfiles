# Atlas project — tab completion for demo names in just commands.
# Skip when there's no justfile in cwd: `just` startup costs ~50ms per shell
# and the recipe only exists inside the atlas repo anyway.
if test -f justfile -o -f Justfile -o -f .justfile
    just _completions-fish 2>/dev/null | source
end
