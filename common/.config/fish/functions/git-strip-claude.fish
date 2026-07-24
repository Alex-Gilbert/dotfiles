# Strip "Co-Authored-By: Claude" trailers from unpushed commits.
# Compares HEAD against its remote base and rewrites only the commits
# ahead of that base. Leaves file trees untouched — messages only.
#
#   git-strip-claude              # auto-detect base (@{u}, else origin/<branch>)
#   git-strip-claude origin/main  # compare against an explicit base ref
function git-strip-claude
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "❌ Not inside a git repository"
        return 1
    end

    # Determine the remote base to compare HEAD against
    set -l base $argv[1]
    if test -z "$base"
        set base (git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    end
    if test -z "$base"
        set -l branch (git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if test -n "$branch"; and git rev-parse --verify --quiet origin/$branch >/dev/null
            set base origin/$branch
        end
    end
    if test -z "$base"
        echo "❌ Could not determine a remote base. Pass one: git-strip-claude origin/main"
        return 1
    end
    if not git rev-parse --verify --quiet $base >/dev/null
        echo "❌ Base ref '$base' does not exist"
        return 1
    end

    set -l range $base..HEAD
    set -l count (git rev-list --count $range)
    if test "$count" -eq 0
        echo "ℹ️  No commits ahead of $base — nothing to do"
        return 0
    end

    # Count how many carry the trailer
    set -l affected 0
    for h in (git rev-list $range)
        if git log -1 --format='%B' $h | grep -qi 'Co-Authored-By:.*Claude'
            set affected (math $affected + 1)
        end
    end

    echo "🔍 $count commit(s) ahead of $base; $affected carry a Claude co-author trailer"
    if test "$affected" -eq 0
        echo "✨ Nothing to strip"
        return 0
    end

    # Safety backup
    set -l backup "backup/pre-claude-strip-"(date +%Y%m%d-%H%M%S)
    git tag $backup HEAD
    echo "🏷️  Backup tag: $backup ("(git rev-parse --short HEAD)")"

    # Rewrite the range, deleting the trailer line (case-insensitive)
    if not FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f \
            --msg-filter 'sed "/^Co-Authored-By:[[:space:]]*Claude/Id"' \
            $range
        echo "❌ filter-branch failed; restore with: git reset --hard $backup"
        return 1
    end

    # Verify file trees are unchanged (messages only)
    set -l diffstat (git diff $backup HEAD --stat)
    if test -z "$diffstat"
        echo "✅ Trailers stripped; file trees identical to backup"
    else
        echo "⚠️  Trees differ from backup — inspect: git diff $backup HEAD"
    end

    set -l remaining (git log $range --format='%B' | grep -ic 'co-authored.*claude')
    echo "📊 Remaining Claude co-author lines: $remaining"
    echo ""
    echo "↩️  Undo:        git reset --hard $backup"
    echo "🧹 Drop backup: git tag -d $backup; and rm -rf .git/refs/original"
end
