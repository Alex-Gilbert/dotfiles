# One browser: Firefox (plus Chrome, for Claude only)

Every machine runs the same browser with the same config: **Firefox**. Hyper+b
opens it everywhere (Paneru on macOS; niri, sway, i3, hypr and sxhkd on Linux)
and `$BROWSER` agrees. The only other browser is **Google Chrome**, kept purely
as the target for Claude in Chrome.

## Why Firefox

- **It's Gecko, so the config is a file.** `common/.config/firefox/user.js` is
  plain text in this repo. Chromium-family prefs are a JSON blob the browser
  rewrites underneath you, which is why the old multi-browser setup drifted.
- **It's on every device.** Desktop and Android, one Mozilla account: Firefox
  Sync carries bookmarks, passwords, open tabs and add-ons everywhere.
- **Upstream, not a fork.** Zen (the previous pick) is Firefox with a new UI;
  the prefs and Tridactyl setup carry over unchanged, minus one more project to
  wait on for security releases.
- **Tridactyl's `:editor`** (below) has no Chromium equivalent.

## Work and personal: containers

One window, colour-coded tabs, separate cookies per container, so work and
personal Gmail sit side by side. Install **Firefox Multi-Account Containers**
(addons.mozilla.org/firefox/addon/multi-account-containers/), then make a
`Work` and a `Personal` container and sign each into its Gmail.

- **Move a tab between them:** right-click the tab → *Reopen in Container*.
- **Always open a site in one:** container menu → *Always open this site in…*
  Only for sites that belong to one side (work Slack, Linear). Not Gmail:
  both accounts are `mail.google.com`, so it can only pick one container.
- `user.js` pins `privacy.userContext.enabled` so containers stay on.
- Firefox Sync installs the add-on on every machine. To carry the containers
  themselves, turn on *Sync* in the add-on's own settings (it's opt-in); then
  it's once per Mozilla account, not once per machine.

## Setup (every machine)

1. Install:
   - macOS: `brew install --cask firefox`
   - Linux: `paru -S --needed firefox`
2. Launch Firefox once so it creates its profile, sign into the Mozilla
   account, and let Sync pull add-ons (Multi-Account Containers, Tridactyl).
3. `./scripts/stow_dotfiles.sh` (puts `user.js` at `~/.config/firefox/user.js`),
   then link it into the profile. Firefox names profile dirs randomly, so this
   is a script, not a stow target; re-run it after making a new profile:

   ```sh
   ./scripts/firefox-link-prefs.sh
   ```

4. Make it the default browser:
   - macOS: Firefox → Settings → *Make Default*.
   - Linux: `xdg-settings set default-web-browser firefox.desktop`
5. Restart Firefox so `user.js` applies.

To change a pref for every machine, edit `common/.config/firefox/user.js`.
Anything listed there is frozen (it is re-applied over `prefs.js` at every
start), so keep it to prefs you'd never reach for in Settings.

## Chrome: Claude's browser, nothing else

Claude in Chrome only runs in Chromium-family browsers (Firefox and Safari are
not supported), so Google Chrome stays installed on every machine (the same
browser on macOS and Linux) as **Claude's** browser:

- **Not the default and not on Hyper+b.** Links you click open in Firefox.
  Start Chrome from Raycast (macOS) or wofi (Linux) when Claude needs it; the
  extension only connects while Chrome is running.
- **One profile, only the sign-ins Claude may use.** Claude acts as you here,
  so what's signed in is what it can touch. Today: Gmail. Add services as
  they come up; nothing else gets a login.
- **No sync, no bookmarks, no other extensions.** Nothing to maintain.

Install: macOS `brew install --cask google-chrome`; Linux
`paru -S --needed google-chrome`. Then add the Claude extension from the
Chrome Web Store and sign into Gmail.

## Removing the old browsers

After Firefox has your bookmarks and passwords (import from Zen/Chrome first:
Firefox → *Import data*), remove the rest:

- macOS: Zen and Firefox Developer Edition (`brew uninstall --cask zen`,
  drag the Developer Edition app to the Bin). Keep Google Chrome, but sign it
  out of everything except what Claude needs.
- Linux: `paru -Rns zen-browser-bin chromium` and `rm -rf ~/.config/zen`.

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
2. **Install the native messenger** — in Firefox, `:installnative`. This is what
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
