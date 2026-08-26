# One browser: Zen

Five browsers were installed and four configs disagreed about which one was
the browser — sway said `firefox`, i3/hypr/sxhkd said `thorium-browser`,
`xdg-settings` said `brave`, and the (dead, unsourced) zshrc files said
`google-chrome`. Now everything says `zen-browser`.

## Why Zen

- **It's Gecko, so the config is a file.** `user.js` is plain text that lives
  in this repo and reproduces on a new machine. Chromium-family prefs are a
  JSON blob the browser rewrites underneath you; there is no version-control
  story there, which is the whole reason four configs drifted apart.
- **Thorium had to go regardless.** Project lead unavailable; the M150→M151
  bump shipped Aug 2026 as beta builds on a *collaborator's fork*, with the
  main repo carrying a notification and no binaries. Historically it has gone
  9 months between releases. Unpatched Chromium is not a daily driver.
- **Zen tracks Firefox within days.** 1.21.15b (Aug 19 2026) is the Firefox
  154 engine with MFSA2026-74, 60+ CVEs; the release before it absorbed
  Mozilla's 44-CVE advisory four days after Mozilla shipped it.
- **Figma officially supports Firefox.** `scripts/open_figma.sh` only existed
  to spoof a Chrome UA past Thorium's unrecognised one. Deleted.

## What `chromium` is still doing here

`claude-in-chrome` is Chrome/Edge, with Claude Code also detecting the
extension in other Chromium browsers. Firefox and Safari are not supported and
not planned. So bare `chromium` (145M profile, official repos, gets patched
with the rest of the system) stays installed **as an automation target only** —
no logins, no bookmarks, not bound to a key. It is a tool, not a browser.

## Linux

Order matters: Zen imports from the Chromium profiles, so import *before* the
purge.

```sh
paru -S zen-browser-bin
```

1. Launch it once (`zen-browser`) and let it create its profile.
2. Import bookmarks/passwords from Chrome and Thorium while they still exist.
3. Link the repo's prefs into the profile. Zen's profile root is
   `~/.config/zen` (XDG — *not* `~/.zen`, despite what most guides say), and it
   names the profile directory randomly, so this is a one-time step per machine
   rather than a stow target. `about:profiles` shows the exact path if you want
   to confirm. Filtering on `prefs.js` skips the stub profiles Zen pre-creates
   but never runs:

   ```fish
   for d in ~/.config/zen/*/
       test -f $d/prefs.js; and ln -sfn ~/.config/zen/user.js $d/user.js
   end
   ```

4. Make it the system default:

   ```sh
   xdg-settings set default-web-browser zen.desktop
   ```

5. Restart Zen so `user.js` applies, confirm the imports landed, then purge:

   ```sh
   paru -Rns brave-bin google-chrome thorium-browser-bin firefox
   rm -rf ~/.config/google-chrome ~/.config/BraveSoftware ~/.config/thorium ~/.mozilla
   ```

   Nothing on the system depends on any of them (checked). That's ~8.8G back.

### Screen sharing on sway

Unrelated to the browser, but it bites the browser: only
`xdg-desktop-portal-{gtk,hyprland,kde}` are installed. The hyprland portal
only serves Hyprland, so a sway session has no screencast backend and share
dialogs come up empty in *any* browser.

```sh
paru -S xdg-desktop-portal-wlr
```

## macOS

```sh
brew install --cask zen
```

Then the same profile link, against the macOS profile path:

```sh
for p in ~/Library/Application\ Support/zen/Profiles/*/prefs.js
    ln -sf ~/.config/zen/user.js (dirname $p)/user.js
end
```

Set it as default in Zen's own Settings, then uninstall Chrome.

## Sidebar on hover

Compact mode reveals the sidebar when the pointer grazes the screen edge. Off:

```js
user_pref("zen.view.compact.show-sidebar-and-toolbar-on-hover", false);
```

Already in `common/.config/zen/user.js`. The hotkey you'd want instead is
built in and unaffected by that pref — Zen ships two separate compact-mode
actions:

| Action id | Command | Default |
|---|---|---|
| `zen-compact-mode-show-sidebar` | `cmd_zenCompactModeShowSidebar` | **Ctrl+Alt+S** |
| `zen-compact-mode-toggle` | `cmd_toggleCompactModeIgnoreHover` | **Ctrl+S** |

Rebind in Settings → Keyboard shortcuts. That writes to
`zen-keyboard-shortcuts.json` **inside the profile**, not to `user.js` — so if
you customise it, that file is the next candidate for the same symlink
treatment as `user.js`.

Related knobs, same prefix, if you want to tune what compact mode hides:
`zen.view.compact.hide-tabbar` (default true), `.hide-toolbar` (false),
`.toolbar-flash-popup` (false), `.sidebar-keep-hover.duration` (150ms).

## Developer tools

Tridactyl **cannot** open devtools — WebExtensions have no API for it, and
there's no `:devtools` excmd. Devtools shortcuts live at the browser level, in
Zen's own `devTools` shortcut group, stored in the profile at
`zen-keyboard-shortcuts.json`.

| Chord | Panel |
|---|---|
| `F12` / `Ctrl+Shift+I` | toggle toolbox |
| `Ctrl+Shift+K` | web console |
| `Ctrl+Shift+L` | inspector |
| `Ctrl+Shift+E` | network |
| `Ctrl+Alt+D` | debugger *(moved — see below)* |
| `Ctrl+Shift+M` | responsive design mode |
| `Ctrl+Shift+J` | browser console |
| `Ctrl+Alt+Shift+I` | browser toolbox |
| `Shift+F5` / `F7` / `F9` / `F12` | performance / style editor / storage / accessibility |
| `Ctrl+Alt+Shift+W` | DOM panel *(moved — see below)* |

Plain `F12` is not rebindable: Zen lists `key_toggleToolboxF12` in
`IGNORED_DEVTOOLS_SHORTCUTS`, because DevToolsStartup handles it specially.
It still works, it just won't appear in Settings → Keyboard shortcuts.

### Three default conflicts, fixed

An audit of all 128 shortcuts found three chords bound to two actions each.
In every case the *standard* binding was kept and the rarer action moved:

| Chord | Was also | Now |
|---|---|---|
| `Ctrl+Shift+K` | `zen-close-all-unpinned-tabs` | console keeps it; tab-nuke → `Ctrl+Alt+Shift+K` |
| `Ctrl+Shift+W` | `key_dom` | close-window keeps it; DOM panel → `Ctrl+Alt+Shift+W` |
| `Ctrl+Shift+Z` | `key_jsdebugger` | redo keeps it; debugger → `Ctrl+Alt+D` |

The first was the dangerous one — the universal web-console chord also closed
every unpinned tab. Redo keeps `Ctrl+Shift+Z` because there's no `Ctrl+Y`
fallback bound; `Ctrl+Alt+D` for the debugger echoes nvim's `<leader>d` group.

### Why this file is a copy, not a symlink

`common/.config/zen/zen-keyboard-shortcuts.json` is a **copy**, unlike
`user.js` which is symlinked. Zen *writes* this file whenever you change a
shortcut in Settings, and it does so by atomic replace — which would delete a
symlink and silently detach the profile from the repo. Re-sync by hand after
changing shortcuts in the UI:

```fish
cp ~/.config/zen/*/zen-keyboard-shortcuts.json ~/dotfiles/common/.config/zen/
```

Going the other way (repo → a fresh machine) is the same copy in reverse, into
the profile directory. Zen must not be running for either — it rewrites the
file on exit. A `.pre-devtools.bak` of the original sits beside it in the
profile.

## Editing prefs afterwards

`user.js` is re-applied over `prefs.js` at every startup, so anything listed in
`common/.config/zen/user.js` is frozen — changing it in Settings reverts on the
next launch. Keep that file to prefs you'd never reach for in the UI, and let
taste (theme, compact mode, workspaces, extensions) live in the UI where Zen's
own sync carries it between machines.

## Making hyper+b instant

Gecko's first start is slow; every window after it is nearly free. So one Zen
instance is warmed at login and parked in the **scratchpad** — the process stays
resident, nothing sits in the tiling layout — and `hyper+b` is just a plain
`zen-browser`, which opens a new window in the current workspace, tiled,
against that already-running process.

- `sway/config` + `i3/config` autostart: `scripts/zen-warm.sh`
- `hyper+b` in all four WM configs: `zen-browser`

Measured on this machine: cold start and park **~1.0s**, a new window against
the warm instance **~220–270ms**. Closing every visible Zen window leaves the
parked one alive, so the process stays warm all session.

`zen-warm.sh` is idempotent — it exits immediately if any Zen window exists, so
a WM reload won't spawn a second browser.

Session restore opens **several** windows and they don't all appear at once, so
the script waits for the window count to settle and then parks every one of
them. Parking only the first left the rest sitting on the workspace at login,
which is the exact thing this is meant to prevent. Being broad is safe here:
`zen-warm.sh` has exited long before you press hyper+b, so windows you open
later are never touched.

### Headless does not work for this

`zen-browser --headless` genuinely warms the process, but it takes the profile
and then **silently swallows every later invocation**: they exit 0 and no window
ever appears. Tested directly — a headless instance plus a second
`zen-browser <url>` produced zero new windows. It can warm a process; it can
never become a visible browser. The scratchpad is what actually gives you
"resident, but nothing on screen".

### Two traps, both hit while building this

**`swaymsg` and `i3-msg` exit 0 even when no window matches the criteria.** So
the obvious one-liner is silently broken — the fallback never runs:

```sh
swaymsg '[app_id=zen] focus' || zen-browser    # never launches anything
```

Window existence has to be read off `-t get_tree`, not the exit code.

**Criteria match *every* matching window, not one.** The first version parked
the warm instance with `[app_id="(?i)^zen$"] move scratchpad`, which also swept
the windows you'd actually opened into the scratchpad — they just vanished.
`zen-warm.sh` therefore captures the con_id of the window it launched and moves
**that** one, by `[con_id=N]`.

### If it ever goes cold

Killing the parked window (it's in the scratchpad, so this takes deliberate
effort) drops the last Zen process and the next `hyper+b` pays the full cold
start. Re-park it without waiting for a re-login:

```sh
./scripts/zen-warm.sh
```

## Vim keybindings

**Tridactyl** is the pick, and specifically because of `:editor` — it hands any
textarea on the page to `$EDITOR`, so you write GitHub comments and PR bodies
in real nvim with your own config. Nothing in the Chromium world does this;
that alone is worth the switch to Gecko.

The others, for the record: **Vimium C** is ~200KB, fixed shortcut set, no
scripting — fine if you only want `hjkl` and link hints. **Surfingkeys** sits
in between with a JS API. Neither can leave the browser sandbox, so neither
can drive nvim.

### Setup

1. **Install the extension** — one click from
   `addons.mozilla.org/firefox/addon/tridactyl-vim/`. Everything else is config.
2. **Install the native messenger** — in Zen, `:installnative`. This is what
   makes `:editor` (and auto-sourcing the rc file) work.
3. **Load the config** — `:source`. After the native messenger is in, this
   happens automatically at startup.

`common/.config/tridactyl/tridactylrc` is stowed to
`~/.config/tridactyl/tridactylrc`, so it reproduces on any machine.

### The bindings

They mirror `~/.config/nvim`, Space as leader:

| Key | nvim equivalent | Browser action |
|---|---|---|
| `<C-i>` | — | hand the focused text field to nvim, **floating** |
| `<Space>/` | `<leader>/` fuzzy-in-buffer | find in page |
| `n` / `N` | `n` / `N` | next / previous match |
| `<Space>pf` | `<leader>pf` fff find_files | every tab, every window |
| `<Space>pb` | `<leader>pb` telescope buffers | tabs in this window |
| `<Space>pr` | `<leader>pr` oldfiles | reopen a closed tab |
| `<Space>bd` | `<leader>bd` Snacks.bufdelete | close tab |
| `<Space>w` | `<leader>w` save | bookmark |
| `<Space>xh` / `<Space>xl` | `<leader>x` swap group | move tab left / right |
| `<Space>psh` | `<leader>psh` help_tags | Tridactyl help |
| `<Space>psk` | `<leader>psk` keymaps | list binds |
| `<Space>vr` | config reload | re-source the rc |

### The editor window floats

`set editorcmd kitty --class tridactyl-editor -e nvim`. The `--class` gives the
window its own `app_id` (Wayland) / `WM_CLASS` (X11), which is all the WM needs
to keep it out of the tiling layout:

```
for_window [app_id="tridactyl-editor"] floating enable, resize set 70 ppt 75 ppt, move position center
```

`ppt` rather than px so it lands the same on the 4K desktop and the
1.25-scaled laptop panel — the existing `floating-terminal` rule above it uses
px, which is fine for a fixed 800x600 scratch terminal but wouldn't be for an
editor. Measured: 1780x1044 centered on a 2560x1440 logical screen. `-e` must
come last in the kitty invocation; Tridactyl appends the temp filename after it.

**Space stops paging down.** That's the one real cost of Space-as-leader.
`<C-d>`/`<C-u>` already scroll half a page and are what the nvim config uses
anyway, so it's the cheaper default — `unbind <Space>` if you disagree.

Left on Tridactyl's defaults on purpose: `]]`/`[[` (`followpage next|prev`,
a better browser analogue of next/prev-reference than tab cycling), and
`<C-d>`/`<C-u>` (nvim recentres with `zz` after them; a web page has no cursor
to centre on).

### The Zen gotcha

`:editor` needs Tridactyl's **native messenger**, a separate binary outside the
extension sandbox. Zen didn't support native messaging at first — the Tridactyl
maintainers still point at zen-browser/desktop#725 when asked — but **that
issue is now closed as Done**, so it works; the discussion thread advising
otherwise is stale.

What's still fiddly is *where* the manifest goes. Zen moved its profile to XDG
(`~/.config/zen`), and it isn't documented whether the native-manifest lookup
followed it or stayed at `~/.mozilla`. I checked the shipped binary and it's
genuinely ambiguous — both strings are present. Rather than guess, cover both:

```fish
# in Zen, run:  :native
# then, if it still reports "not installed":
mkdir -p ~/.config/zen/native-messaging-hosts ~/.mozilla/native-messaging-hosts
for d in ~/.config/zen ~/.mozilla
    ln -sfn ~/.mozilla/native-messaging-hosts/tridactyl.json \
            $d/native-messaging-hosts/tridactyl.json
end
```

Then set the editor — `.tridactylrc`, which belongs in this repo once it exists:

```
set editorcmd foot -e nvim
```

(`foot` because that's the sway terminal; use `kitty` on the i3/X11 side.)
