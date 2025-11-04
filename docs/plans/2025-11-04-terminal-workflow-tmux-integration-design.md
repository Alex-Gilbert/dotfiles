# Terminal Workflow: Tmux Integration Design

**Date:** 2025-11-04
**Author:** Alex (with Claude Code)
**Status:** Approved

## Overview

Transform terminal workflow from window-manager-centric (opening/closing many kitty terminals) to tmux-centric (persistent sessions with context preservation). The key insight: leverage zoxide for directory navigation while automatically managing tmux sessions.

## Current Workflow Problems

- Opening many ephemeral kitty terminals via Meta+t
- Navigating to same project directories repeatedly (via cd/zoxide or fp function)
- Losing all context when closing terminals
- Heavy reliance on window manager for terminal organization
- No preservation of running processes, command history, or pane layouts

## Design Goals

1. **Preserve Meta+t muscle memory** - Keep the existing keybinding behavior
2. **Directory-first navigation** - Use zoxide's frecency ranking for project selection
3. **Automatic session management** - Create/attach to tmux sessions transparently
4. **Minimal retraining** - Gradual transition from window-manager to tmux workflows
5. **Context preservation** - Keep project sessions alive with all windows/panes intact

## Architecture

### Core Flow

```
Meta+t pressed
    ↓
New kitty window opens
    ↓
Automatically runs `ftz` function
    ↓
Zoxide interactive (zi) shows frecent directories
    ↓
User selects directory OR presses Esc
    ↓
If selected: Create/attach to tmux session for that directory
If Esc: Drop to normal shell
```

### Session Management Logic

```
Directory selected via zoxide
    ↓
Generate session_name (basename of directory, sanitized)
    ↓
Check if tmux session exists
    ↓
If EXISTS:
    - Inside tmux: switch-client to session
    - Outside tmux: attach-session to session
    ↓
If NOT EXISTS:
    - Check for .tmux config file
    - If .tmux exists: Load via tmuxp
    - If no .tmux: Create simple session in that directory
```

## Implementation Components

### 1. New Fish Function: `ftz`

Location: `/home/alex/dotfiles/common/.config/fish/functions/ftz.fish`

```fish
function ftz
    # Use zoxide interactive to select directory
    set selected (zoxide query -i)

    if test -z "$selected"
        # User cancelled, just drop to shell
        return
    end

    cd $selected
    set session_name (basename $selected | tr . _)

    # Check if session exists
    if tmux has-session -t $session_name 2>/dev/null
        # Attach to existing
        if test -n "$TMUX"
            tmux switch-client -t $session_name
        else
            tmux attach-session -t $session_name
        end
    else
        # Create new (with .tmux support via tmuxp)
        if test -f .tmux
            tmuxp load .tmux
        else
            tmux new-session -s $session_name -c $selected
        end
    end
end
```

### 2. Window Manager Configuration

Modify i3 config (or relevant WM config) to change Meta+t keybinding:

**Before:**
```
bindsym $mod+t exec kitty
```

**After:**
```
bindsym $mod+t exec kitty -e fish -c ftz
```

## Integration with Existing Functions

The new `ftz` function complements existing tmux utilities:

- **ftz** (new) - Default for Meta+t, directory-first navigation with zoxide
- **fts** - Still useful when already in a directory: "start session here"
- **fpt** - Still useful for browsing ~/dev specifically (project-focused)
- **ft** - Still useful for switching between already-running sessions
- **ftw** - Window switcher within current session
- **ftr** - Rename current session
- **ftk** - Kill session (cleanup finished projects)
- **ftsave** - Save current session to .tmux file (via tmuxp freeze)

## Edge Cases

### Already Inside Tmux
When Meta+t is pressed while already in a tmux session:
- `$TMUX` variable is set
- Function uses `switch-client` instead of `attach-session`
- Allows seamless jumping between project sessions

### Zoxide Cancellation (Esc)
When user presses Esc in zoxide selector:
- `zoxide query -i` returns empty string
- Function returns early
- User is left in normal shell (not in tmux)

### Session Name Collisions
If two projects have the same basename:
- They will map to the same session name
- Second selection will attach to first project's session
- **Decision:** Ignore for now, revisit if it becomes problematic

### No .tmux File
When creating new session without saved configuration:
- Creates simple single-window session in selected directory
- User can later save layout with `ftsave` if desired

## Workflow Transition

### Before (Window-Manager-Centric)
1. Press Meta+t → New terminal
2. cd or fp to project
3. Run command
4. Close terminal when done
5. Repeat for each task

### After (Tmux-Centric)
1. Press Meta+t → Zoxide selector
2. Pick directory → Auto-attached to session
3. Run commands, create windows/panes
4. Press Meta+t → Jump to different project
5. Sessions stay alive, context preserved

### Key Mental Shift
Stop closing terminals. Leave tmux sessions running. Each project maintains its state (windows, panes, processes, history) indefinitely.

## Success Criteria

- Meta+t muscle memory preserved
- Zoxide directory selection feels natural
- Sessions automatically created/attached without manual intervention
- Can quickly jump between active projects
- Context (windows, panes, running processes) preserved across sessions
- Gradual adoption possible (can still Esc to normal shell)

## Future Enhancements

- Auto-save sessions on detach (via tmux-continuum)
- Session templates for common project types
- Better handling of basename collisions (if needed)
- Integration with project-specific environment variables
