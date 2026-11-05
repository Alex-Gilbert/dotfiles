#!/bin/bash
# SwiftBar plugin: open RilianTech PRs in the menu bar, refreshed every 5 minutes
# (the .5m. in the filename). Click a PR to open it.

# SwiftBar's PATH doesn't include Homebrew
export PATH="/opt/homebrew/bin:$PATH"

all_url='https://github.com/pulls?q=is:open+is:pr+org:RilianTech'

# shortcut: shows at most 200 PRs, raise --limit if the org ever has more
if ! menu=$(gh search prs --owner RilianTech --state open --limit 200 \
    --json number,title,url,repository,author,isDraft --jq '
    (length | "PRs \(.)"),
    "---",
    (group_by(.repository.name)[] |
        "\(.[0].repository.name) (\(length)) | size=12",
        (.[] |
            (if .isDraft then "[draft] " else "" end) as $draft |
            "\($draft)#\(.number) \(.title | gsub("\\|"; "/")) · \(.author.login) | href=\(.url) length=80"))
    ' 2>&1); then
    # A failed fetch must not look like zero open PRs
    printf 'PRs ?\n---\ngh failed: %s\n' "${menu//|//}"
    printf 'Refresh | refresh=true\n'
    exit 0
fi

printf '%s\n---\nOpen all on GitHub | href=%s\nRefresh | refresh=true\n' "$menu" "$all_url"
