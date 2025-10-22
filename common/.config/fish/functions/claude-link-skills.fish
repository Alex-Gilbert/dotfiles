# Link plugin skills to ~/.claude/skills with tracking
function claude-link-skills
    set PLUGIN_CACHE "$HOME/.claude/plugins/cache"
    set SKILLS_DIR "$HOME/.config/claude/skills"
    set TRACKER "$HOME/.config/claude/plugin-skills-symlinks.txt"

    mkdir -p $SKILLS_DIR

    echo "🔗 Creating symlinks for plugin skills..."
    echo "# Created on "(date) > $TRACKER
    echo "# Remove these when plugin discovery is fixed" >> $TRACKER
    echo "" >> $TRACKER

    for skill_file in (find $PLUGIN_CACHE -name "SKILL.md" 2>/dev/null)
        set skill_dir (dirname $skill_file)
        set skill_name (basename $skill_dir)
        set target "$SKILLS_DIR/$skill_name"
        
        if test -e $target
            if test -L $target
                echo "⏭️  $skill_name (already linked)"
            else
                echo "⚠️  $skill_name (exists, not a symlink - skipping)"
            end
        else
            ln -s $skill_dir $target
            echo $target >> $TRACKER
            echo "✅ $skill_name"
        end
    end

    echo ""
    echo "✨ Done! Symlinks tracked in: $TRACKER"
    echo "📝 To remove all symlinks later, run: claude-cleanup-skills"
end

# Remove all tracked skill symlinks
function claude-cleanup-skills
    set TRACKER "$HOME/.config/claude/plugin-skills-symlinks.txt"

    if not test -f $TRACKER
        echo "❌ No tracker file found at: $TRACKER"
        return 1
    end

    echo "🧹 Removing plugin skill symlinks..."

    # Read lines that aren't comments or empty
    for link in (cat $TRACKER | grep -v '^#' | grep -v '^\s*$')
        if test -L $link
            rm $link
            echo "✅ Removed: "(basename $link)
        else
            echo "⏭️  Not a symlink: "(basename $link)
        end
    end

    rm $TRACKER
    echo ""
    echo "✨ Cleanup complete!"
end

# List all symlinked skills
function claude-list-skills
    echo "🔗 Symlinked skills:"
    ls -la ~/.claude/skills/ 2>/dev/null | grep "^l" | awk '{print "  " $9, "->", $11}'
    
    echo ""
    echo "📁 All skills:"
    ls -1 ~/.claude/skills/ 2>/dev/null | sed 's/^/  /'
end

# Quick remove all skill symlinks (no tracking file needed)
function claude-remove-skill-links
    echo "🧹 Removing all skill symlinks from ~/.claude/skills/..."
    
    set count 0
    for link in ~/.claude/skills/*
        if test -L $link
            set skill_name (basename $link)
            rm $link
            echo "✅ Removed: $skill_name"
            set count (math $count + 1)
        end
    end
    
    if test $count -eq 0
        echo "ℹ️  No symlinks found"
    else
        echo ""
        echo "✨ Removed $count symlink(s)"
    end
end

# Copy a specific skill from cache to local (not symlink)
function claude-copy-skill
    if test (count $argv) -eq 0
        echo "Usage: claude-copy-skill <skill-name>"
        echo ""
        echo "Available skills in cache:"
        find ~/.claude/plugins/cache -name "SKILL.md" 2>/dev/null | while read skill_file
            set skill_dir (dirname $skill_file)
            echo "  "(basename $skill_dir)
        end
        return 1
    end

    set skill_name $argv[1]
    set PLUGIN_CACHE "$HOME/.claude/plugins/cache"
    set SKILLS_DIR "$HOME/.claude/skills"
    
    set skill_path (find $PLUGIN_CACHE -type d -name $skill_name 2>/dev/null | head -n 1)
    
    if test -z "$skill_path"
        echo "❌ Skill '$skill_name' not found in plugin cache"
        return 1
    end
    
    set target "$SKILLS_DIR/$skill_name"
    
    if test -e $target
        echo "⚠️  Skill already exists at: $target"
        read -P "Overwrite? [y/N] " -n 1 response
        echo
        if not string match -qi "y" $response
            echo "Cancelled"
            return 0
        end
        rm -rf $target
    end
    
    cp -r $skill_path $target
    echo "✅ Copied $skill_name to $target"
end
