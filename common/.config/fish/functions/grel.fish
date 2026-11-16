function grel --description 'Install a Gitea release asset (fzf: repo, then asset); `grel up` updates everything installed'
    set -l state ~/.local/state/grel/installed
    mkdir -p (path dirname $state) ~/.local/bin
    touch $state

    if contains -- "$argv[1]" -h --help
        echo "usage: grel [owner/repo]   pick an asset to install (no arg: pick the repo too)"
        echo "       grel up             reinstall anything a newer release replaced"
        return 0
    end

    if test "$argv[1]" = up
        # state rows: owner/repo<TAB>name pattern<TAB>installed asset id
        for row in (cat $state)
            set -l f (string split \t $row)
            set -l asset
            for line in (__grel_assets $f[1])
                if string match -q -- $f[2] (string split -f2 \t $line)
                    set asset $line
                    break
                end
            end
            if test -z "$asset"
                echo "$f[1]: nothing matches $f[2] any more" >&2
            else if test (string split -f4 \t $asset) = $f[3]
                echo "$f[1]: $f[2] is up to date"
            else
                __grel_install $f[1] $asset; or return 1
            end
        end
        return 0
    end

    set -l repo $argv[1]
    if test -z "$repo"
        set repo (__gclone_repos | fzf --delimiter \t --prompt 'release from> ' | string split -f1 \t)
        test -n "$repo"; or return 1
    end
    set -l asset (__grel_assets $repo | fzf --delimiter \t --with-nth 1,2,3 --prompt "$repo> ")
    test -n "$asset"; or return 1
    __grel_install $repo $asset
end

# Every asset of every release, newest release first:
# tag<TAB>name<TAB>size<TAB>asset id<TAB>download url
function __grel_assets
    tea api -l gilbert "repos/$argv[1]/releases?limit=20" 2>/dev/null | jq -r '.[] | .tag_name as $t
        | .assets[] | [$t, .name, "\(.size / 1048576 | floor) MB", .id, .browser_download_url] | @tsv'
end

# Download one asset row and put it where it runs: binaries from a tarball and
# AppImages into ~/.local/bin, anything else into ~/Downloads.
function __grel_install --argument-names repo row
    set -l a (string split \t $row)
    set -l name $a[2]
    set -l tmp (mktemp -d)
    tea api -l gilbert -o $tmp/$name $a[5] >/dev/null; or begin
        rm -rf $tmp
        return 1
    end
    switch $name
        case '*.tar.gz' '*.tgz'
            tar -xzf $tmp/$name -C $tmp
            for f in (find $tmp -type f -perm -u+x)
                install -m755 $f ~/.local/bin/
                echo "installed ~/.local/bin/"(path basename $f)" ($a[1])"
            end
        case '*.AppImage'
            set -l dest ~/.local/bin/(string split -f2 / $repo).AppImage
            install -m755 $tmp/$name $dest
            echo "installed $dest ($a[1])"
        case '*'
            mv $tmp/$name ~/Downloads/
            echo "saved ~/Downloads/$name ($a[1])"
    end
    rm -rf $tmp

    # Remember it by name with versions wildcarded, so `grel up` finds 0.2.0 after 0.1.0.
    set -l pattern (string replace -ra '[0-9]+(\.[0-9]+)+' '*' -- $name)
    set -l state ~/.local/state/grel/installed
    set -l rows "$repo"\t"$pattern"\t$a[4]
    for r in (cat $state)
        test (string split -f1,2 \t -- $r | string join \t) = "$repo"\t"$pattern"; or set -a rows $r
    end
    printf '%s\n' $rows >$state
end
