function gclone --description 'Clone a Gitea repo (owner/name) into ~/dev and cd into it; no arg = fzf picker'
    set -l repo $argv[1]
    if test (count $argv) -eq 0
        set repo (__gclone_repos | fzf --delimiter \t --prompt 'gitea> ' | string split -f1 \t)
        test -n "$repo"; or return 1
    else if test (count $argv) -ne 1
        echo "usage: gclone [owner/repo]" >&2
        return 1
    end
    set -l name (string split / $repo)[-1]
    git clone ssh://gitea/$repo.git ~/dev/$name; and cd ~/dev/$name
end
