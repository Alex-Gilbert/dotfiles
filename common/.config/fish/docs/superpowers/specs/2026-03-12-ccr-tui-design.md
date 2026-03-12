# ccr — Claude Conversation Resume TUI

A ratatui-based fuzzy finder for Claude Code conversation history. Treats conversations as files and user messages as lines — telescope grep-style interface for searching across all past sessions, with a preview pane showing message context.

## Data Model

Source: `~/.claude/projects/*/*.jsonl`

Each JSONL file represents one **conversation**. From each file:

- **Conversation metadata**: `session_id` (filename sans `.jsonl`), `cwd` (taken from the first JSONL record that has a `cwd` field), `project_name` (basename of `cwd`), `timestamp` (file mtime)
- **Messages**: every JSONL line with `type: "user"` where `message.role == "user"` — extract text content (handling both string and array-of-content-blocks formats), plus the **next assistant message** with text content for preview

Messages are indexed like "lines in a file" — each has a position within its conversation. Fuzzy search runs across all message texts. Results are grouped under conversation headers.

**Sort order**: Conversations sorted by mtime descending (most recent first). Messages within a conversation sorted by position (order they appear in the JSONL file).

### JSONL Record Format

Each line is a JSON object. Relevant fields:

```jsonl
{"type":"user","message":{"role":"user","content":"fix the auth login flow"},"cwd":"/Users/alex/dev/reepi","sessionId":"abc-123","timestamp":"2026-03-12T14:30:00Z"}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"I'll look into the auth flow..."}]},"sessionId":"abc-123","timestamp":"2026-03-12T14:30:05Z"}
```

Content can be a plain string or an array of content blocks. For array content, extract blocks with `type: "text"` only. For preview, assistant messages may contain tool_use/tool_result blocks — skip those and only render text blocks.

### Error Handling

- **Malformed JSONL lines**: skip silently (same as existing Python behavior)
- **Unreadable files**: skip silently, continue indexing other files
- **Missing `~/.claude/projects/`**: exit with a helpful error message
- **Socket connection failures** (daemon mode): fall back to direct mode silently

## Architecture

### Two modes, one binary (`ccr`)

- **Direct mode** (default): On launch, parse all JSONL files, build the index in memory, run the TUI.
- **Daemon mode**: A background process (`ccr daemon`) watches `~/.claude/projects/` for changes, maintains a hot index, and listens on a Unix socket. When the TUI launches, it first tries to connect to the socket — if the daemon is there, it streams results from it instead of parsing files itself. If not, falls back to direct mode silently.

The binary is named `ccr`. The shell wrappers call `ccr` and eval its output.

### Components

1. **Parser** — reads JSONL, extracts conversations and user messages with their adjacent assistant replies
2. **Index** — holds all messages in a fuzzy-searchable structure (using `nucleo` crate — same fuzzy matcher that powers telescope)
3. **Daemon** — wraps parser + index, watches for file changes (via `notify` crate), serves queries over Unix socket
4. **TUI** — ratatui app with telescope layout. Talks to either the daemon or a local in-memory index through a shared trait/interface
5. **Exec** — on selection, prints a shell-escaped command to stdout. Shell wrapper evals it.

### Daemon Details

- **Socket**: `$XDG_RUNTIME_DIR/ccr.sock` (fallback: `/tmp/ccr-$UID.sock`)
- **PID file**: next to the socket
- **Lifecycle**: `ccr daemon` starts, `ccr daemon --stop` kills

**Wire protocol** (newline-delimited over Unix socket):
1. TUI connects, sends: `DUMP v1\n`
2. Daemon responds with JSON lines, one per conversation:
   ```json
   {"session_id":"abc-123","cwd":"/Users/alex/dev/reepi","project_name":"reepi","timestamp":1710254400,"messages":[{"index":0,"text":"fix the auth login flow","reply":"I'll look into the auth flow..."},{"index":1,"text":"the token refresh is broken too","reply":"Let me check the refresh middleware..."}]}
   ```
3. Daemon sends `END\n` as sentinel
4. TUI builds its local fuzzy index from the received data and handles all matching/highlighting locally

The TUI does not stream live queries to the daemon — it pulls the full dataset once at startup (fast over a local socket), then runs fuzzy matching in-process. This keeps the protocol simple and the TUI responsive. The `v1` tag allows future protocol changes without breaking older clients.

- **File watching**: `notify` crate watches `~/.claude/projects/` for new/modified JSONL files, incrementally updates index
- **Async runtime**: `tokio` is used only in daemon mode. Direct mode is synchronous.

## TUI Layout (Classic Telescope)

```
┌─────────────────────────────────────────────────────┐
│ > auth login│                                       │
├──────────────────────────┬──────────────────────────┤
│ ── reepi (03/12 14:30) ──│ Preview                  │
│  3: can you fix the auth │                          │
│     login flow           │ ▶ You:                   │
│  7: the token refresh is │ can you fix the auth     │
│     broken too           │ login flow? users are    │
│ ── caspian (03/11 09:15) │ getting 401s after the   │
│  2: implement auth login │ session expires          │
│     page                 │                          │
│  5: add OAuth login      │ ▶ Claude:                │
│     support              │ I'll look into the auth  │
│ ── marketplace (03/10)  ─│ flow. The issue is in    │
│  1: setup auth middleware│ the token refresh...     │
├──────────────────────────┴──────────────────────────┤
│ 6/134 matches │ reepi │ ~/dev/.../reepi │ ⏎ resume  │
└─────────────────────────────────────────────────────┘
```

- **Top**: Input bar with fuzzy search prompt
- **Left pane**: Results grouped by conversation headers (`project_name (date)`). Message rows show index + truncated text. Matched characters highlighted.
- **Right pane**: Preview — full user message + assistant reply (text blocks only). Auto-scrolls to matched message. Scrollable with `ctrl-u`/`ctrl-d`.
- **Bottom**: Status bar — match count, cwd, keybinding hints

## Keybindings

| Key | Action |
|-----|--------|
| Type | Fuzzy search |
| `ctrl-n` / `↓` | Next result |
| `ctrl-p` / `↑` | Previous result |
| `Enter` / `ctrl-y` | Select and resume conversation |
| `Esc` / `ctrl-c` | Quit |
| `ctrl-u` / `ctrl-d` | Scroll preview up/down |

No config file for keybindings. Hardcoded for simplicity.

## Shell Integration

The Rust binary prints a shell-escaped command to stdout on selection:

```
cd '/path/to/my project' && claude --resume 'abc-123-def'
```

Paths and session IDs are single-quoted to handle spaces and special characters.

On cancel (Esc/ctrl-c), the binary exits with no output.

Fish wrapper (`ccr.fish`):
```fish
function ccr
    set cmd (command ccr)
    if test -n "$cmd"
        eval $cmd
    end
end
```

Zsh wrapper (`ccr.zsh`):
```zsh
ccr() {
    local cmd=$(command ccr)
    [[ -n "$cmd" ]] && eval "$cmd"
}
```

Note: the shell function and binary share the name `ccr`. `command ccr` bypasses function lookup and resolves the binary via `$PATH`, avoiding infinite recursion.

## Project Location

`~/projects/ccr` — standalone Rust project.

## Key Crates

- `ratatui` — TUI framework
- `crossterm` — terminal backend
- `nucleo` — fuzzy matching (telescope-grade)
- `serde` / `serde_json` — JSONL parsing
- `notify` — filesystem watching (daemon mode)
- `tokio` — async runtime (daemon mode only)
- `clap` — CLI argument parsing

## Testing

- **Parser unit tests**: feed sample JSONL (valid, malformed, mixed content types) and assert correct extraction of conversations and messages
- **Index tests**: build index from known data, run fuzzy queries, assert match results and ordering
- **Integration test**: use a temp directory with fixture JSONL files, run the parser + index end-to-end, verify the full pipeline
- **TUI**: manual testing — ratatui's test backend can be used for snapshot tests if needed later
- **Daemon**: integration test with a real Unix socket — start daemon, connect, verify protocol
