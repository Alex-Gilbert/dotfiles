function senv
    set file $argv[1]

    if test -z "$file"
        echo "Usage: senv <env-file>"
        return 1
    end

    . (sed '/^[[:space:]]*#/! s/^/export /' $file | psub)
end
