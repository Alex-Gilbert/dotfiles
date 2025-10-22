function git-dump
    if test (count $argv) -lt 1
        echo "Usage: git-dump <repo-url> [branch]"
        return 1
    end

    set repo $argv[1]

    # Determine branch: use arg if given, else detect default, else fallback to main
    if test (count $argv) -ge 2
        set branch $argv[2]
    else
        set branch (git ls-remote --symref $repo HEAD 2>/dev/null | awk '/^ref:/ {sub("refs/heads/","",$2); print $2}')
        if test -z "$branch"
            set branch main
        end
    end

    # Build the codeload path (owner/repo)
    set path (string replace -r '^https://github.com/' '' -- $repo)
    set path (string replace -r '\.git$' '' -- $path)

    echo "Downloading $repo@$branch ..."
    curl -L "https://codeload.github.com/$path/tar.gz/refs/heads/$branch" \
    | tar -xz --strip-components=1
end
