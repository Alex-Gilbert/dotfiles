# Vi mode
fish_vi_key_bindings

# Vi mode cursor shapes (if your terminal supports it)
set fish_vi_force_cursor 1
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore

# Aliases
alias lg lazygit
alias cu cluster-utils.sh
# alias z 'zellij -l welcome'
alias n nvim
alias dive 'docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest'
alias dd 'nohup dolphin $PWD > /dev/null 2>&1 &'
alias c='xclip -selection clipboard'
alias serena='uvx --from git+https://github.com/oraios/serena serena start-mcp-server'
alias kay kubectl
alias mouse-speed='xinput set-prop 14 "libinput Accel Speed"'
alias space-check='sudo du -h --max-depth=1 . | sort -h'
alias vpnup='sudo wg-quick up protonvpn'
alias vpndown='sudo wg-quick down protonvpn'

# Claude Code skill suites. Each repo is a plugin dir (.claude-plugin/plugin.json
# + skills/), so the flag loads the whole set and `git pull` is the update story.
# Don't copy skills into ~/.claude/skills/ — copies fork silently and go stale.
abbr ccteam 'claude --plugin-dir ~/dev/alex-team-skills'
abbr ccmem 'claude --plugin-dir ~/dev/alex-memory'

# Cross-platform PATH additions.
# -g (global, not universal) on every fish_add_path in this repo is deliberate:
# bare `fish_add_path` writes to the *universal* $fish_user_paths, which fish
# persists into fish_variables — a tracked file. That's how macOS paths
# (/opt/homebrew, /Applications/...) ended up committed and leaking onto Linux.
# Global entries are rebuilt from these files on every shell start instead.
fish_add_path -g $HOME/.config/fish/functions
fish_add_path -g $HOME/dotfiles/scripts
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/.cargo/bin
fish_add_path -g $HOME/.bun/bin

# Platform-specific config: each platform's stow package drops a file into
# ~/.config/fish/conf.d/, which fish auto-sources. Nothing platform-specific
# belongs in this file — only one package is ever stowed on a given machine,
# so each env file guards itself and the others simply aren't present.
#   - Linux desktop  -> linux/.config/fish/conf.d/linux-env.fish
#   - macOS          -> macos/.config/fish/conf.d/macos-env.fish
#   - Termux/Android -> android/.config/fish/conf.d/android-env.fish

# Common environment variables
set -gx GAMS_VERSION "46.4"

# Editors
set -gx EDITOR "nvim"
set -gx VISUAL "nvim"

# ssh-agent
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket" 

# Zoxide integration
set -Ux _ZO_EXCLUDE_DIRS "/mnt/*:/run/media/*"
# Cache `zoxide init` output; regenerate when the zoxide binary is newer than the cache.
set -l _zoxide_bin (command -v zoxide)
if test -n "$_zoxide_bin"
    set -l _zoxide_cache $__fish_cache_dir/zoxide-init.fish
    if not test -f $_zoxide_cache; or test $_zoxide_bin -nt $_zoxide_cache
        mkdir -p $__fish_cache_dir
        zoxide init fish --cmd cd >$_zoxide_cache
    end
    source $_zoxide_cache
end

# Disable greeting
set fish_greeting

# History settings (Fish defaults are already good)

# Custom key bindings
bind -M insert \er 'fzf-history'
bind -M default \er 'fzf-history'

# `?` asks the local model for a command: type what you want as a comment,
# press ? in normal mode, get the command. Press it on an existing command to
# get an explanation instead. Backed by ollama via fish-ai.ini, so nothing
# leaves the machine.
#
# Bound here rather than via fish-ai's keymap_1 because _fish_ai_bind binds its
# keymaps in BOTH insert and default mode, and `?` has to stay a literal
# question mark in insert mode (globs, URLs, `test -n`). fish-ai's conf.d runs
# before config.fish, so this binding lands last and wins.
#
# ctrl-space still does autocomplete-or-fix in both modes (fish-ai's keymap_2).
bind -M default '?' _fish_ai_codify_or_explain

# opencode
fish_add_path -g $HOME/.opencode/bin

# dotenv
set -g fish_dotenv_enable_yes 1

# cook
if test -d $HOME/.cook/bin
    fish_add_path -g $HOME/.cook/bin
    COMPLETE=fish cook | source
end

# direnv — per-directory env, loaded on cd. Keeps project-specific vars out of
# the global environment instead of every shell paying for every project.
if command -q direnv
    direnv hook fish | source
end
