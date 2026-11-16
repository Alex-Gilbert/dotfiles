# shortcut: hits the Gitea API on every <tab> / picker open; add a cache if it ever feels slow
function __gclone_repos
    set -l page 1
    while true
        # tsv rows: "owner"	"name"	"description" -> owner/name<TAB>description
        set -l rows (tea repos list -o tsv -f owner,name,description --limit 50 --page $page 2>/dev/null \
            | tail -n +2 | string replace -a '"' '' | string replace \t /)
        test (count $rows) -eq 0; and break
        printf '%s\n' $rows
        # Gitea caps pages at 50 by default; a short page means we're done
        test (count $rows) -lt 50; and break
        set page (math $page + 1)
    end
end
